-------------------------------------------------------------------------------
-- Title      : Signal Generator for JESD DAC
-------------------------------------------------------------------------------
-- File       : TrigGenLaneMr.vhd
-- Author     : Uros Legat  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Signal generator top module.
--     Currently contains 2 signal generator lanes.
--     To change the number of lanes:
--          - Change INT_TRIG_SIZE_G,

--
--     Module has its own AxiLite register interface and access to AXI lite and
--     AXIlite configuration for each trigger lne, 4 front panel lines and up to 8 internals.
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 LLRF Development'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 LLRF Development', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.TrigGenPkg.all;


entity TrigGenLaneMr is
   generic (
      TPD_G             : time                        := 1 ns;
      -- AXI Lite and stream generics
      AXI_ERROR_RESP_G  : slv(1 downto 0)             := AXI_RESP_SLVERR_C;
      AXI_BASE_ADDR_G   : slv(31 downto 0)       := (others => '0')
   );
   port (

      -- Clocks and Resets
      axiClk         : in    sl;
      axiRst         : in    sl;

      -- Clocks and Resets
      devClk          : in   sl;
      devRst          : in   sl;
      timingBus       : in   TimingBusType;

      -- AXI-Lite Register Interface
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Trigger input/output signals
      lemoDinI        : in    slv(1 downto 0);
      Tstrobe         : in   sl;
      -- Internal trigger for desirable destination
      IntTrig         : out  sl
   );
end TrigGenLaneMr;

architecture rtl of TrigGenLaneMr is


signal  TrigSpecMr        :    TrigSpecMrType;


begin

   -----------------------------------------------------------
   -- AXI lite
   -----------------------------------------------------------
-- No cross bar interface

   -- DAQ control register interface
   AxiLiteGenRegTrigLineMr_INST: entity work.AxiLiteGenRegTrigLineMr
   generic map (
      TPD_G            => TPD_G,
      AXI_ERROR_RESP_G => AXI_ERROR_RESP_G
      )
   port map (
      axiClk          => axiClk,
      axiRst          => axiRst,
      devClk          => devClk,
      devRst          => devRst,
      axilReadMaster  => axilReadMaster,
      axilReadSlave   => axilReadSlave,
      axilWriteMaster => axilWriteMaster,
      axilWriteSlave  => axilWriteSlave,
      TrigSpecMr      => TrigSpecMr
      );


   -----------------------------------------------------------
   -- Trigger generator

      TrigGenMr_INST: entity work.TrigGenMr
   generic map (
      TPD_G        => TPD_G)
   port map (
      devClk          => devClk,
      devRst          => devRst,
      TimingBus       => TimingBus,
      lemoDinI        => lemoDinI,
      TrigSpecMr      => TrigSpecMr,
      Tstrobe         => Tstrobe,
      IntTrig         => IntTrig
      );

   -----------------------------------------------------



end rtl;
