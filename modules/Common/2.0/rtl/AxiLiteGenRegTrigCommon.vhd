-------------------------------------------------------------------------------
-- Title      : Axi-lite interface for trigger common interface
-------------------------------------------------------------------------------
-- File       : AxiLiteGenRegTrigCommon.vhd
-- Author     : Leonid Sapozhnikovt  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-15
-- Last update: 2015-04-15
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:  Register decoding for TRigger  generator common, unused for the moment
--               0x00 (RW)- Place holder
-------------------------------------------------------------------------
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

entity AxiLiteGenRegTrigCommon is
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
      axilWriteSlave  : out   AxiLiteWriteSlaveType
   );
end AxiLiteGenRegTrigCommon;

architecture rtl of AxiLiteGenRegTrigCommon is


   type RegType is record
      UnusedReg    : slv(7 downto 0);
      axilReadSlave   : AxiLiteReadSlaveType;
      axilWriteSlave  : AxiLiteWriteSlaveType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      UnusedReg       => (others=>'0'),
      axilReadSlave   => AXI_LITE_READ_SLAVE_INIT_C,
      axilWriteSlave  => AXI_LITE_WRITE_SLAVE_INIT_C);

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

      -- force enable
      axiSlaveRegister(regCon, x"000", 0, v.UnusedReg);

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

---------------------------------------------------------------------
end rtl;
