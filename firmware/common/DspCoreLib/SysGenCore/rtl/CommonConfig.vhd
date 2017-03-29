-------------------------------------------------------------------------------
-- Title      : Axi-lite interface for trigger generation interface
-------------------------------------------------------------------------------
-- File       : CommonConfig.vhd
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

entity CommonConfig is
   generic (
   -- General Configurations
      TPD_G                      : time                       := 1 ns;
      AXI_ERROR_RESP_G          : slv(1 downto 0)            := AXI_RESP_SLVERR_C
   );
   port (

         -- Clocks and Resets
      axiClk         : in    sl;
      axiRst         : in    sl;

      -- AXI-Lite Register Interface
      axilReadMaster  : in    AxiLiteReadMasterType := AXI_LITE_READ_MASTER_INIT_C;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType := AXI_LITE_WRITE_MASTER_INIT_C;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Configuration signals
      commonConfig   : out    commonConfigType
   );
end CommonConfig;

architecture rtl of CommonConfig is


   type RegType is record
      commonConfig    : commonConfigType;
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      commonConfig   => COMMONCONFIG_C,
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C
      );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

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

      --  TrigDelay(0) -- unused
      axiSlaveRegister(regCon, x"000", 0, v.commonConfig.enableCalib);
      axiSlaveRegister(regCon, x"004", 0, v.commonConfig.AppType);

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
      commonConfig <= r.commonConfig;

   end process comb;

   seq : process (axiClk) is
   begin
      if rising_edge(axiClk) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
