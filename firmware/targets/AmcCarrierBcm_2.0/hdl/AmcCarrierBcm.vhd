-------------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : AmcCarrierBcm.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-07-10
-- Last update: 2016-03-10
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Firmware Target's Top Level
--
-- Note: Common-to-Application interface defined in HPS ESD: LCLSII-2.7-ES-0536
--
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 BCM Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 BCM Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;

entity AmcCarrierBcm is
   generic (
      TPD_G         : time    := 1 ns;
      SIM_SPEEDUP_G : boolean := false;
      SIMULATION_G  : boolean := false);
   port (
      -----------------------
      -- Application Ports --
      -----------------------
      -- JESD High Speed Ports
      jesdRxP          : in    Slv4Array(1 downto 0);
      jesdRxN          : in    Slv4Array(1 downto 0);
      jesdTxP          : out   Slv4Array(1 downto 0);
      jesdTxN          : out   Slv4Array(1 downto 0);
      -- JESD Reference Ports
      jesdClkP         : in    slv(1 downto 0);
      jesdClkN         : in    slv(1 downto 0);
      jesdSysRefP      : in    slv(1 downto 0);
      jesdSysRefN      : in    slv(1 downto 0);
      -- JESD ADC Sync Ports
      jesdRxSyncP      : out   Slv2Array(1 downto 0);
      jesdRxSyncN      : out   Slv2Array(1 downto 0);
      jesdTxSyncP      : in    slv(1 downto 0);
      jesdTxSyncN      : in    slv(1 downto 0);
      -- LMK Ports
      lmkMuxSel        : out   slv(1 downto 0);
      lmkClkSel        : out   Slv2Array(1 downto 0);
      lmkStatus        : in    Slv2Array(1 downto 0);
      lmkSck           : out   slv(1 downto 0);
      lmkDio           : inout slv(1 downto 0);
      lmkSync          : out   Slv2Array(1 downto 0);
      lmkCsL           : out   slv(1 downto 0);
      lmkRst           : out   slv(1 downto 0);
      -- Fast ADC's SPI Ports
      adcCsL           : out   Slv2Array(1 downto 0);
      adcSck           : out   Slv2Array(1 downto 0);
      adcMiso          : in    Slv2Array(1 downto 0);
      adcMosi          : out   Slv2Array(1 downto 0);
      -- Fast DAC's SPI Ports
      dacCsL           : out   slv(1 downto 0);
      dacSck           : out   slv(1 downto 0);
      dacMiso          : in    slv(1 downto 0);
      dacMosi          : out   slv(1 downto 0);
      -- Slow DAC's SPI Ports
      dacVcoCsP        : out   slv(1 downto 0);
      dacVcoCsN        : out   slv(1 downto 0);
      dacVcoSckP       : out   slv(1 downto 0);
      dacVcoSckN       : out   slv(1 downto 0);
      dacVcoDinP       : out   slv(1 downto 0);
      dacVcoDinN       : out   slv(1 downto 0);
      -- Pass through Interfaces
      fpgaClkP         : out   slv(1 downto 0);
      fpgaClkN         : out   slv(1 downto 0);
      smaTrigP         : out   slv(1 downto 0);
      smaTrigN         : out   slv(1 downto 0);
      adcCalP          : out   slv(1 downto 0);
      adcCalN          : out   slv(1 downto 0);
      lemoDinP         : in    Slv2Array(1 downto 0);
      lemoDinN         : in    Slv2Array(1 downto 0);
      lemoDoutP        : out   Slv2Array(1 downto 0);
      lemoDoutN        : out   Slv2Array(1 downto 0);
      bcmL             : out   slv(1 downto 0);
      ----------------
      -- Core Ports --
      ----------------
      -- Common Fabricate Clock
      fabClkP          : in    sl;
      fabClkN          : in    sl;
      -- XAUI Ports
      xauiRxP          : in    slv(3 downto 0);
      xauiRxN          : in    slv(3 downto 0);
      xauiTxP          : out   slv(3 downto 0);
      xauiTxN          : out   slv(3 downto 0);
      xauiClkP         : in    sl;
      xauiClkN         : in    sl;
      -- Backplane MPS Ports
      mpsClkIn         : in    sl;
      mpsClkOut        : out   sl;
      mpsBusRxP        : in    slv(14 downto 1);
      mpsBusRxN        : in    slv(14 downto 1);
      mpsTxP           : out   sl;
      mpsTxN           : out   sl;
      -- LCLS Timing Ports
      timingRxP        : in    sl;
      timingRxN        : in    sl;
      timingTxP        : out   sl;
      timingTxN        : out   sl;
      timingRefClkInP  : in    sl;
      timingRefClkInN  : in    sl;
      timingRecClkOutP : out   sl;
      timingRecClkOutN : out   sl;
      timingClkSel     : out   sl;
      timingClkScl     : inout sl;
      timingClkSda     : inout sl;
      -- Crossbar Ports
      xBarSin          : out   slv(1 downto 0);
      xBarSout         : out   slv(1 downto 0);
      xBarConfig       : out   sl;
      xBarLoad         : out   sl;
      -- Secondary AMC Auxiliary Power Enable Port
      enAuxPwrL        : out   sl;
      -- IPMC Ports
      ipmcScl          : inout sl;
      ipmcSda          : inout sl;
      -- Configuration PROM Ports
      calScl           : inout sl;
      calSda           : inout sl;
      -- DDR3L SO-DIMM Ports
      ddrClkP          : in    sl;
      ddrClkN          : in    sl;
      ddrDm            : out   slv(7 downto 0);
      ddrDqsP          : inout slv(7 downto 0);
      ddrDqsN          : inout slv(7 downto 0);
      ddrDq            : inout slv(63 downto 0);
      ddrA             : out   slv(15 downto 0);
      ddrBa            : out   slv(2 downto 0);
      ddrCsL           : out   slv(1 downto 0);
      ddrOdt           : out   slv(1 downto 0);
      ddrCke           : out   slv(1 downto 0);
      ddrCkP           : out   slv(1 downto 0);
      ddrCkN           : out   slv(1 downto 0);
      ddrWeL           : out   sl;
      ddrRasL          : out   sl;
      ddrCasL          : out   sl;
      ddrRstL          : out   sl;
      ddrAlertL        : in    sl;
      ddrPg            : in    sl;
      ddrPwrEnL        : out   sl;
      ddrScl           : inout sl;
      ddrSda           : inout sl;
      -- SYSMON Ports
      vPIn             : in    sl;
      vNIn             : in    sl);
end AmcCarrierBcm;

architecture top_level of AmcCarrierBcm is

   -- AmcCarrierCore Configuration Constants
   constant TIMING_MODE_C            : boolean                                                   := TIMING_MODE_186MHZ_C;
   constant APP_TYPE_C               : AppType                                                   := APP_BCM_TYPE_C;
   constant DIAGNOSTIC_RAW_STREAMS_C : positive                                                  := 4;
   constant DIAGNOSTIC_RAW_CONFIGS_C : AxiStreamConfigArray(DIAGNOSTIC_RAW_STREAMS_C-1 downto 0) := (others => ssiAxiStreamConfig(4));

   constant EN_BP_MSG_G              : boolean                                                   := true;
   constant HEAD                     : boolean                                                   := true;


   -- AXI-Lite Interface (appClk domain)
   signal regClk         : sl;
   signal regRst         : sl;
   signal regReadMaster  : AxiLiteReadMasterType;
   signal regReadSlave   : AxiLiteReadSlaveType;
   signal regWriteMaster : AxiLiteWriteMasterType;
   signal regWriteSlave  : AxiLiteWriteSlaveType;

   -- Timing Interface (timingClk domain)
   signal timingClk : sl;
   signal timingRst : sl;
   signal timingBus : TimingBusType;

   -- Diagnostic Interface (diagnosticClk domain)
   signal diagnosticClk : sl;
   signal diagnosticRst : sl;
   signal diagnosticBus : DiagnosticBusType;

   --  Waveform interface (waveformClk domain)
   signal waveformClk          : sl;
   signal waveformRst          : sl;
   signal obAppWaveformMasters : WaveformMasterArrayType;
   signal obAppWaveformSlaves  : WaveformSlaveArrayType;
   signal ibAppWaveformMasters : WaveformMasterArrayType;
   signal ibAppWaveformSlaves  : WaveformSlaveArrayType;

   -- Reference Clocks and Resets
   signal recTimingClk : sl;
   signal recTimingRst : sl;
   signal ref156MHzClk : sl;
   signal ref156MHzRst : sl;


begin

   U_App : entity work.Application
      generic map (
         TPD_G         => TPD_G,
         SIM_SPEEDUP_G => SIM_SPEEDUP_G)
      port map (
         ----------------------
         -- Top Level Interface
         ----------------------
         -- AXI-Lite Interface (regClk domain)
         regClk               => regClk,
         regRst               => regRst,
         regReadMaster        => regReadMaster,
         regReadSlave         => regReadSlave,
         regWriteMaster       => regWriteMaster,
         regWriteSlave        => regWriteSlave,
         -- Timing Interface (timingClk domain)
         timingClk            => timingClk,
         timingRst            => timingRst,
         timingBus            => timingBus,
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk        => diagnosticClk,
         diagnosticRst        => diagnosticRst,
         diagnosticBus        => diagnosticBus,
         --  Waveform interface (waveformClk domain)
         waveformClk          => waveformClk,
         waveformRst          => waveformRst,
         obAppWaveformMasters => obAppWaveformMasters,
         obAppWaveformSlaves  => obAppWaveformSlaves,
         ibAppWaveformMasters => ibAppWaveformMasters,
         ibAppWaveformSlaves  => ibAppWaveformSlaves,

         -- Reference Clocks and Resets
         recTimingClk         => recTimingClk,
         recTimingRst         => recTimingRst,
         ref156MHzClk         => ref156MHzClk,
         ref156MHzRst         => ref156MHzRst,

         -----------------------
         -- Application Ports --
         -----------------------
         -- JESD High Speed Ports
         jesdRxP              => jesdRxP,
         jesdRxN              => jesdRxN,
         jesdTxP              => jesdTxP,
         jesdTxN              => jesdTxN,
         -- JESD Reference Ports
         jesdClkP             => jesdClkP,
         jesdClkN             => jesdClkN,
         jesdSysRefP          => jesdSysRefP,
         jesdSysRefN          => jesdSysRefN,
         -- JESD ADC Sync Ports
         jesdRxSyncP          => jesdRxSyncP,
         jesdRxSyncN          => jesdRxSyncN,
         jesdTxSyncP          => jesdTxSyncP,
         jesdTxSyncN          => jesdTxSyncN,
         -- LMK Ports
         lmkMuxSel            => lmkMuxSel,
         lmkClkSel            => lmkClkSel,
         lmkStatus            => lmkStatus,
         lmkSck               => lmkSck,
         lmkDio               => lmkDio,
         lmkSync              => lmkSync,
         lmkCsL               => lmkCsL,
         lmkRst               => lmkRst,
         -- Fast ADC's SPI Ports
         adcCsL               => adcCsL,
         adcSck               => adcSck,
         adcMiso              => adcMiso,
         adcMosi              => adcMosi,
         -- Fast DAC's SPI Ports
         dacCsL               => dacCsL,
         dacSck               => dacSck,
         dacMiso              => dacMiso,
         dacMosi              => dacMosi,
         -- Slow DAC's SPI Ports
         dacVcoCsP            => dacVcoCsP,
         dacVcoCsN            => dacVcoCsN,
         dacVcoSckP           => dacVcoSckP,
         dacVcoSckN           => dacVcoSckN,
         dacVcoDinP           => dacVcoDinP,
         dacVcoDinN           => dacVcoDinN,
         -- Pass through Interfaces
         fpgaClkP             => fpgaClkP,
         fpgaClkN             => fpgaClkN,
         smaTrigP             => smaTrigP,
         smaTrigN             => smaTrigN,
         adcCalP              => adcCalP,
         adcCalN              => adcCalN,
         lemoDinP             => lemoDinP,
         lemoDinN             => lemoDinN,
         lemoDoutP            => lemoDoutP,
         lemoDoutN            => lemoDoutN,
         bcmL                 => bcmL);

   U_Core : entity work.AmcCarrierCore
      generic map (
         TPD_G                    => TPD_G,
         SIM_SPEEDUP_G            => SIM_SPEEDUP_G,
         APP_TYPE_G               => APP_TYPE_C,
         EN_BP_MSG_G              => EN_BP_MSG_G)
      port map (
         ----------------------
         -- Top Level Interface
         ----------------------
         -- AXI-Lite Interface (regClk domain)
         regClk               => regClk,
         regRst               => regRst,
         regReadMaster        => regReadMaster,
         regReadSlave         => regReadSlave,
         regWriteMaster       => regWriteMaster,
         regWriteSlave        => regWriteSlave,
         -- Timing Interface (timingClk domain)
         timingClk            => timingClk,
         timingRst            => timingRst,
         timingBus            => timingBus,
         -- Diagnostic Interface (diagnosticClk domain)
         diagnosticClk        => diagnosticClk,
         diagnosticRst        => diagnosticRst,
         diagnosticBus        => diagnosticBus,
         --  Waveform interface (waveformClk domain)
         waveformClk          => waveformClk,
         waveformRst          => waveformRst,
         obAppWaveformMasters => obAppWaveformMasters,
         obAppWaveformSlaves  => obAppWaveformSlaves,
         ibAppWaveformMasters => ibAppWaveformMasters,
         ibAppWaveformSlaves  => ibAppWaveformSlaves,

         -- Reference Clocks and Resets
         recTimingClk         => recTimingClk,
         recTimingRst         => recTimingRst,
         ref156MHzClk         => ref156MHzClk,
         ref156MHzRst         => ref156MHzRst,

         ----------------
         -- Core Ports --
         ----------------
         -- Common Fabricate Clock
         fabClkP              => fabClkP,
         fabClkN              => fabClkN,
         -- XAUI Ports
         xauiRxP              => xauiRxP,
         xauiRxN              => xauiRxN,
         xauiTxP              => xauiTxP,
         xauiTxN              => xauiTxN,
         xauiClkP             => xauiClkP,
         xauiClkN             => xauiClkN,
         -- Backplane MPS Ports
         mpsClkIn             => mpsClkIn,
         mpsClkOut            => mpsClkOut,
         mpsBusRxP            => mpsBusRxP,
         mpsBusRxN            => mpsBusRxN,
         mpsTxP               => mpsTxP,
         mpsTxN               => mpsTxN,
         -- LCLS Timing Ports
         timingRxP            => timingRxP,
         timingRxN            => timingRxN,
         timingTxP            => timingTxP,
         timingTxN            => timingTxN,
         timingRefClkInP      => timingRefClkInP,
         timingRefClkInN      => timingRefClkInN,
         timingRecClkOutP     => timingRecClkOutP,
         timingRecClkOutN     => timingRecClkOutN,
         timingClkSel         => timingClkSel,
         timingClkScl         => timingClkScl,
         timingClkSda         => timingClkSda,
         -- Crossbar Ports
         xBarSin              => xBarSin,
         xBarSout             => xBarSout,
         xBarConfig           => xBarConfig,
         xBarLoad             => xBarLoad,
         -- Secondary AMC Auxiliary Power Enable Port
         enAuxPwrL            => enAuxPwrL,

         -- IPMC Ports
         ipmcScl              => ipmcScl,
         ipmcSda              => ipmcSda,
         -- Configuration PROM Ports
         calScl               => calScl,
         calSda               => calSda,
         -- DDR3L SO-DIMM Ports
         ddrClkP              => ddrClkP,
         ddrClkN              => ddrClkN,
         ddrDqsP              => ddrDqsP,
         ddrDqsN              => ddrDqsN,
         ddrDm                => ddrDm,
         ddrDq                => ddrDq,
         ddrA                 => ddrA,
         ddrBa                => ddrBa,
         ddrCsL               => ddrCsL,
         ddrOdt               => ddrOdt,
         ddrCke               => ddrCke,
         ddrCkP               => ddrCkP,
         ddrCkN               => ddrCkN,
         ddrWeL               => ddrWeL,
         ddrRasL              => ddrRasL,
         ddrCasL              => ddrCasL,
         ddrRstL              => ddrRstL,
         ddrPwrEnL            => ddrPwrEnL,
         ddrPg                => ddrPg,
         ddrAlertL            => ddrAlertL,
         ddrScl               => ddrScl,
         ddrSda               => ddrSda,
         -- SYSMON Ports
         vPIn                 => vPIn,
         vNIn                 => vNIn);

end top_level;
