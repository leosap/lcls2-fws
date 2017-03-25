-------------------------------------------------------------------------------
-- Title      : Signal Generator for JESD DAC
-------------------------------------------------------------------------------
-- File       : AdcIntProc.vhd
-- Author     : Leonid Sapozhnikov <leosap@slac.stanford.edu>
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
use work.Jesd204bPkg.all;
use work.AdcIntProcPkg.all;


entity AdcIntProc is
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
      jesdClk        : in  sl;
      jesdRst        : in  sl;

      -- configuration and status
      ConfigSpace     : out   ConfigSpaceType;

      adcValids       : in    sl := '0';
      adcValuesIn     : in    slv(31 downto 0) := (others => '0');
	    adcValids2       : in    sl; := '0'
      adcValuesIn2     : in    slv(31 downto 0) := (others => '0');
      adcValuesOut    : out   sampleDataArray(2 downto 0);
      adcValidOut     : out    sl;
      dacValidsOut    : out    sl;
      dacValidsIn     : in     sl := '0';
      dacValuesOut    : out    slv(31 downto 0);
      dacValuesIn     : in     slv(31 downto 0);
      timingMessage   : in    TimingMessageType := TIMING_MESSAGE_INIT_C;
      resultValidOut  : in    sl := '0';

      -- AXI-Lite Register Interface
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Internal trigger
      IntTrig         : in  sl
   );
--   attribute dont_touch                 : string;
--   attribute dont_touch  of AdcIntProc : architecture is “yes”;
end AdcIntProc;

architecture rtl of AdcIntProc is


signal  ConfigSpaceLcl        :    ConfigSpaceLclType;
signal  IntTrigOut            :    slv(2 downto 0);
signal  adcValidOutV          :    slv(2 downto 0);
signal  TriggerRate           :    slv(31 downto 0);
signal  TriggerRateUpdate     :    sl;

begin

   -----------------------------------------------------------
   -- AXI lite
   -----------------------------------------------------------
-- No cross bar interface

   -- DAQ control register interface
   AxiLiteGenRegAdcProc_INST: entity work.AxiLiteGenRegAdcProc
   generic map (
      TPD_G            => TPD_G,
      AXI_ERROR_RESP_G => AXI_ERROR_RESP_G
      )
   port map (
      axiClk          => axiClk,
      axiRst          => axiRst,
      jesdClk         => jesdClk,
      jesdRst         => jesdRst,
      axilReadMaster  => axilReadMaster,
      axilReadSlave   => axilReadSlave,
      axilWriteMaster => axilWriteMaster,
      axilWriteSlave  => axilWriteSlave,
      timingMessage   => timingMessage,
      resultValidOut  => resultValidOut,
      TriggerRate      => TriggerRate,
      TriggerRateUpdate => TriggerRateUpdate,
      ConfigSpaceLcl  => ConfigSpaceLcl,
      ConfigSpace     => ConfigSpace
      );

-- Trigger rate in 1s counter
  SyncTrigRate_INST: entity work.SyncTrigRate
   generic map (
      TPD_G        => TPD_G,
      REF_CLK_FREQ_G => 185.714286E+6,
      ONE_SHOT_G   => true)
   port map (
      trigIn          => IntTrig,
      trigRateUpdated => TriggerRateUpdate,
      trigRateOut     => TriggerRate,
      locClk          => axiClk,
      refClk          => jesdClk
      );

   -----------------------------------------------------------

   genAdcIntSum : for i in 2 downto 0 generate

   -- Trigger delay

      TrigGen_INST: entity work.TrigDelay
   generic map (
      TPD_G        => TPD_G)
   port map (
      devClk          => jesdClk,
      devRst          => jesdRst,
      TrigDelay       => ConfigSpaceLcl.TrigDelay(i),
      IntTrigIn       => IntTrig,
      IntTrigOut      => IntTrigOut(i)
      );

   -- ADC processing, first summing

      AdcProc_INST: entity work.AdcIntSum
   generic map (
      TPD_G        => TPD_G)
   port map (
      devClk          => jesdClk,
      devRst          => jesdRst,
      NumberSamples   => ConfigSpaceLcl.NumberSamples(i),
      adcValuesIn     => adcValuesIn,
      adcValuesOut    => adcValuesOut(i),
      adcValidOut     => adcValidOutV(i),
      IntTrig         => IntTrigOut(i)
      );

  end generate genAdcIntSum;

   DataReady_INST: entity work.DataReady
   generic map (
      TPD_G        => TPD_G)
   port map (
      jesdClk         => jesdClk,
      jesdRst         => jesdRst,
      adcValidOutV    => adcValidOutV,
      adcValidOut     => adcValidOut
      );

   DacSel_INST: entity work.DacSel
   generic map (
      TPD_G        => TPD_G)
   port map (
      jesdClk         => jesdClk,
      jesdRst         => jesdRst,
      DacSrs          => ConfigSpaceLcl.DacSrs,
      adcValids       => adcValids,
      adcValuesIn     => adcValuesIn,
      adcValids2      => adcValids2,
      adcValuesIn2    => adcValuesIn2,
      dacValidsOut    => dacValidsOut,
      dacValidsIn     => dacValidsIn,
      dacValuesOut    => dacValuesOut,
      dacValuesIn     => dacValuesIn
      );

end rtl;
