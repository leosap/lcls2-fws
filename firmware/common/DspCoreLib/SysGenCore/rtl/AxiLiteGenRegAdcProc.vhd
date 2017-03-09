-------------------------------------------------------------------------------
-- Title      : Axi-lite interface for trigger generation interface
-------------------------------------------------------------------------------
-- File       : AxiLiteGenRegAdcProc.vhd
-- Author     : Leonid Sapozhnikovt  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-15
-- Last update: 2015-04-15
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:  Register decoding for TRigger  generator
--               0x00 (RW)- Number of samples to average in first group, LS bit indicate the
--               bit 31-16 if 0, and 15-0 if 1 for start off addition
--               0x01 (RW)- Delay from triger to the second group of summing
--               0x02 (RW)- Number of samples to average in second group
--               0x01 (RW)- Delay from triger to the second group of summing
--               0x02 (RW)- Number of samples to average in second group
--               Other registers defined as needed
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 BCM/BLEN Development'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 LLRF Development', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AdcIntProcPkg.all;

entity AxiLiteGenRegAdcProc is
   generic (
   -- General Configurations
      TPD_G                      : time                       := 1 ns;
      AXI_ERROR_RESP_G          : slv(1 downto 0)            := AXI_RESP_SLVERR_C
   );
   port (

         -- Clocks and Resets
      axiClk         : in    sl;
      axiRst         : in    sl;
      jesdClk        : in  sl;
      jesdRst        : in  sl;

      -- AXI-Lite Register Interface
      axilReadMaster  : in    AxiLiteReadMasterType := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Configuration signals
      timingMessage   : in    TimingMessageType;
      resultValidOut  : in    sl;
      TriggerRate     : in    slv(31 downto 0);
      TriggerRateUpdate  : in    sl;
      ConfigSpaceLcl  : out  ConfigSpaceLclType := CONF_SPACE_LCL_C;
      ConfigSpace     : out  ConfigSpaceType := CONF_SPACE_C
   );
end AxiLiteGenRegAdcProc;

architecture rtl of AxiLiteGenRegAdcProc is


   type RegType is record
      NumberSamples   : Slv8Array(2 downto 0);
      TrigDelay       : Slv8Array(2 downto 0);
      SimAdcSumData   : Slv32Array(2 downto 0);
      TimingStamp     : slv(31 downto 0);
      TriggerRate     : slv(31 downto 0);
      TestMode        : slv(2 downto 0);
      DacSrs          : slv(0 downto 0);
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      NumberSamples   => ((others=>'0'),(others=>'0'),(others=>'0')),
      TrigDelay       => ((others=>'0'),(others=>'0'),(others=>'0')),
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C,
      SimAdcSumData   => ((others=>'0'),(others=>'0'),(others=>'0')),
      TimingStamp     => (others=>'0'),
      TriggerRate     => (others=>'0'),
      TestMode        => (others=>'0'),
      DacSrs          => (others=>'0')
      );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   signal NumberSamples   : Slv8Array(2 downto 0);
   signal TrigDelay       : Slv8Array(2 downto 0);
   signal DacSrs          : slv(0 downto 0);
--   signal TestMode3Synced : Sl;


begin
   ------------------------------------
   -- Register Space
   ------------------------------------
   comb : process (axilReadMaster, axiRst, axilWriteMaster, timingMessage, resultValidOut, TriggerRate, TriggerRateUpdate, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      --  TrigDelay(0) -- unused
      axiSlaveRegister(regCon, x"000", 0, v.NumberSamples(0));
      axiSlaveRegister(regCon, x"004", 0, v.TrigDelay(1));
      axiSlaveRegister(regCon, x"008", 0, v.NumberSamples(1));
      axiSlaveRegister(regCon, x"00C", 0, v.TrigDelay(2));
      axiSlaveRegister(regCon, x"010", 0, v.NumberSamples(2));
      axiSlaveRegister(regCon, x"014", 0, v.SimAdcSumData(0));
      axiSlaveRegister(regCon, x"018", 0, v.SimAdcSumData(1));
      axiSlaveRegister(regCon, x"01C", 0, v.SimAdcSumData(2));
      axiSlaveRegister(regCon, x"020", 0, v.TestMode);
      axiSlaveRegisterR(regCon, x"024", 0, r.TimingStamp);
      axiSlaveRegisterR(regCon, x"028", 0, r.TriggerRate);
      axiSlaveRegister(regCon, x"02C", 0, v.DacSrs);

      if (resultValidOut = '1') then
         v.TimingStamp := timingMessage.timeStamp(31 downto 0);
      end if;

      if (TriggerRateUpdate = '1') then
         v.TriggerRate := TriggerRate;
      end if;

      -- Closeout the transaction
      axiSlaveDefault(regCon,v.axilWriteSlave, v.axilReadSlave, AXI_ERROR_RESP_G);

      --------
      -- Reset
      --------
      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Register the variable for next clock cycle
      rin <= v;

      -- Outputs
            -- Outputs
      axilReadSlave   <= r.axilReadSlave;
      axilWriteSlave  <= r.axilWriteSlave;

   end process comb;

   seq : process (axiClk) is
   begin
      if rising_edge(axiClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;
---------------------------------------------------------------------
   -- Output assignment and synchronisation
   GEN_CHAN : for i in 2 downto 0 generate
     SyncFifo_OUT1 : entity work.SynchronizerFifo
     generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => 8
     )
     port map (
      wr_clk => axiClk,
      din    => r.NumberSamples(i),
      rd_clk => jesdClk,
      dout   => NumberSamples(i)
     );

     SyncFifo_OUT2 : entity work.SynchronizerFifo
     generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => 8
     )
     port map (
      wr_clk => axiClk,
      din    => r.TrigDelay(i),
      rd_clk => jesdClk,
      dout   => TrigDelay(i)
     );
  end generate GEN_CHAN;

     SyncFifo_OUT3 : entity work.SynchronizerFifo
     generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => 1
     )
     port map (
      wr_clk => axiClk,
      din    => r.DacSrs,
      rd_clk => jesdClk,
      dout   => DacSrs
     );
     
  --Synced to JesdClk
  ConfigSpaceLcl.NumberSamples   <= NumberSamples;
  ConfigSpaceLcl.TrigDelay   <= TrigDelay;
  ConfigSpaceLcl.DacSrs   <= r.DacSrs(0);

      --Used at AxiliteClk
  ConfigSpace.SimAdcSumData   <= r.SimAdcSumData;
  ConfigSpace.TestMode(2 downto 0)   <= r.TestMode;
  
---------------------------------------------------------------------
end rtl;
