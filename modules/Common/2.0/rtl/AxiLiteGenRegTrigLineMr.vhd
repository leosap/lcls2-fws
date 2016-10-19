-------------------------------------------------------------------------------
-- Title      : Axi-lite interface for trigger generation interface
-------------------------------------------------------------------------------
-- File       : AxiLiteGenRegTrigLineMr.vhd
-- Author     : Leonid Sapozhnikovt  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-15
-- Last update: 2015-04-15
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:  Register decoding for TRigger  generator

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
use work.TrigGenPkg.all;

entity AxiLiteGenRegTrigLineMr is
   generic (
   -- General Configurations
      TPD_G                      : time                       := 1 ns;
      AXI_ERROR_RESP_G          : slv(1 downto 0)            := AXI_RESP_SLVERR_C
   );
   port (

         -- Clocks and Resets
      axiClk         : in    sl;
      axiRst         : in    sl;

      -- Clocks and Resets
      devClk          : in   sl;
      devRst          : in   sl;

      -- AXI-Lite Register Interface
      axilReadMaster  : in    AxiLiteReadMasterType := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Configuration signals

      TrigSpecMr      : out  TrigSpecMrType
   );
end AxiLiteGenRegTrigLineMr;

architecture rtl of AxiLiteGenRegTrigLineMr is


   type RegType is record
      eventCodes     : slv(255 downto 0);
      SelectSource   : slv(1 downto 0);
      trigDelay      : slv(STD_TRIG_WIDTH-1 downto 0);
      trigStretch    : slv(STD_TRIG_WIDTH-1 downto 0);
      outPolarity    : sl;
      SoftTrigI      : sl;
      SoftTrigD      : sl;
      SoftTrigP      : sl;
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      eventCodes      => x"0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0100_0000_0000",
      SelectSource    => (others=>'0'),
      trigDelay       => (others=>'0'),
      trigStretch     => (others=>'0'),
      outPolarity     => '0',
      SoftTrigI       => '0',
      SoftTrigD       => '0',
      SoftTrigP       => '0',
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C);

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;
   signal SyncOut   : slv(1 downto 0);
   signal SyncIn    : slv(1 downto 0);

begin
   ------------------------------------
   -- Register Space
   ------------------------------------
   comb : process (axilReadMaster, axiRst, axilWriteMaster, r) is
      variable v      : RegType;
      variable regCon : AxiLiteEndPointType;
   begin
      -- Latch the current value
      v := r;

      -- Determine the transaction type
      axiSlaveWaitTxn(regCon, axilWriteMaster, axilReadMaster, v.axilWriteSlave, v.axilReadSlave);

      -- force enable
      axiSlaveRegister(regCon, x"000", 0, v.eventCodes(31 downto 0));
      axiSlaveRegister(regCon, x"004", 0, v.eventCodes(31 + 1*32 downto 0+1*32));
      axiSlaveRegister(regCon, x"008", 0, v.eventCodes(31 + 2*32 downto 0+2*32));
      axiSlaveRegister(regCon, x"00C", 0, v.eventCodes(31 + 3*32 downto 0+3*32));
      axiSlaveRegister(regCon, x"010", 0, v.eventCodes(31 + 4*32 downto 0+4*32));
      axiSlaveRegister(regCon, x"014", 0, v.eventCodes(31 + 5*32 downto 0+5*32));
      axiSlaveRegister(regCon, x"018", 0, v.eventCodes(31 + 6*32 downto 0+6*32));
      axiSlaveRegister(regCon, x"01C", 0, v.eventCodes(31 + 7*32 downto 0+7*32));
      axiSlaveRegister(regCon, x"020", 0, v.trigDelay);
      axiSlaveRegister(regCon, x"024", 0, v.trigStretch);
      axiSlaveRegister(regCon, x"028", 0, v.outPolarity);
      axiSlaveRegister(regCon, x"02C", 0, v.SoftTrigI);
      axiSlaveRegister(regCon, x"030", 0, v.SelectSource);



      v.SoftTrigD := v.SoftTrigI;
      v.SoftTrigP := v.SoftTrigI and not(v.SoftTrigD);

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
      axilReadSlave   <= r.axilReadSlave;
      axilWriteSlave  <= r.axilWriteSlave;

   end process comb;

   seq : process (axiClk) is
   begin
      if rising_edge(axiClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -- Output assignment and synchronisation
   SyncFifo_OUT1 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => 256
   )
   port map (
      wr_clk => axiClk,
      din    => r.eventCodes,
      rd_clk => devClk,
      dout   => TrigSpecMr.eventCodes
   );

   -- Output assignment and synchronisation
   SyncFifo_OUT2 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => 2
   )
   port map (
      wr_clk => axiClk,
      din    => r.SelectSource,
      rd_clk => devClk,
      dout   => TrigSpecMr.SelectSource
   );

   SyncFifo_OUT5 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => STD_TRIG_WIDTH
   )
   port map (
      wr_clk => axiClk,
      din    => r.trigDelay,
      rd_clk => devClk,
      dout   => TrigSpecMr.trigDelay
   );

  SyncFifo_OUT6 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => STD_TRIG_WIDTH
   )
   port map (
      wr_clk => axiClk,
      din    => r.trigStretch,
      rd_clk => devClk,
      dout   => TrigSpecMr.trigStretch
   );


  SyncIn(0) <= r.outPolarity;
  SyncIn(1) <= r.SoftTrigP;

  SyncFifo_OUT7 : entity work.SynchronizerFifo
   generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => 2
   )
   port map (
      wr_clk => axiClk,
      din    => SyncIn,
      rd_clk => devClk,
      dout   => SyncOut
   );

   TrigSpecMr.outPolarity <= SyncOut(0);
   TrigSpecMr.SoftTrigP   <= SyncOut(1);
---------------------------------------------------------------------
end rtl;
