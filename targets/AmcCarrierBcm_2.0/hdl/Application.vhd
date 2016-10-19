-------------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : Application.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-12-04
-- Last update: 2016-03-04
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Application's Top Level
--
-- Note: Common-to-Application interface defined in HPS ESD: LCLSII-2.7-ES-0536
-- Modifications:
-- 2/17/2016 Added DAC data stream coppied from LLRF
-- 2/26/2016 Added DAQ MUX[bay=0] and SysGenWrapper
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 AMC Carrier Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 AMC Carrier Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AxiLitePkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.jesd204bpkg.all;
use work.AdcIntProcPkg.all;

entity Application is
   generic (
      TPD_G                 : time            := 1 ns;
      SIM_SPEEDUP_G         : boolean         := false;
      SIMULATION_G          : boolean         := false;
      AXI_CLK_FREQ_G        : real            := 156.25E+6;
      GEN_BRAM_ADDR_WIDTH_G : positive        := 12;
      INT_TRIG_SIZE_G       : positive        := 7;
      DIAGNOSTIC_OUTPUTS_G  : integer range 1 to 32     := 28;
      AXI_ERROR_RESP_G      : slv(1 downto 0) := AXI_RESP_DECERR_C);
   port (
      ----------------------
      -- Top Level Interface
      ----------------------
      -- AXI-Lite Interface (regClk domain)
      -- Address Range = [0x80000000:0xFFFFFFFF]
      regClk               : out   sl;
      regRst               : out   sl;
      regReadMaster        : in    AxiLiteReadMasterType;
      regReadSlave         : out   AxiLiteReadSlaveType;
      regWriteMaster       : in    AxiLiteWriteMasterType;
      regWriteSlave        : out   AxiLiteWriteSlaveType;
      -- Timing Interface (timingClk domain)
      timingClk            : out   sl;
      timingRst            : out   sl;
      timingBus            : in    TimingBusType;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : out   sl;
      diagnosticRst        : out   sl;
      diagnosticBus        : out   DiagnosticBusType;
      --  Waveform interface (waveformClk domain)
      waveformClk          : in  sl;
      waveformRst          : in  sl;
      obAppWaveformMasters : out WaveformMasterArrayType;
      obAppWaveformSlaves  : in  WaveformSlaveArrayType      := WAVEFORM_SLAVE_ARRAY_INIT_C;
      ibAppWaveformMasters : in  WaveformMasterArrayType     := WAVEFORM_MASTER_ARRAY_INIT_C;
      ibAppWaveformSlaves  : out WaveformSlaveArrayType;




      -- Reference Clocks and Resets
      recTimingClk         : in    sl;
      recTimingRst         : in    sl;
      ref156MHzClk         : in    sl;
      ref156MHzRst         : in    sl;

      -----------------------
      -- Application Ports --
      -----------------------
      -- JESD High Speed Ports
      jesdRxP              : in    Slv4Array(1 downto 0);
      jesdRxN              : in    Slv4Array(1 downto 0);
      jesdTxP              : out   Slv4Array(1 downto 0);
      jesdTxN              : out   Slv4Array(1 downto 0);
      -- JESD Reference Ports
      jesdClkP             : in    slv(1 downto 0);
      jesdClkN             : in    slv(1 downto 0);
      jesdSysRefP          : in    slv(1 downto 0);
      jesdSysRefN          : in    slv(1 downto 0);
      -- JESD ADC Sync Ports
      jesdRxSyncP          : out   Slv2Array(1 downto 0);
      jesdRxSyncN          : out   Slv2Array(1 downto 0);
      jesdTxSyncP          : in    slv(1 downto 0);
      jesdTxSyncN          : in    slv(1 downto 0);
      -- LMK Ports
      lmkMuxSel            : out   slv(1 downto 0);
      lmkClkSel            : out   Slv2Array(1 downto 0);
      lmkStatus            : in    Slv2Array(1 downto 0);
      lmkSck               : out   slv(1 downto 0);
      lmkDio               : inout slv(1 downto 0);
      lmkSync              : out   Slv2Array(1 downto 0);
      lmkCsL               : out   slv(1 downto 0);
      lmkRst               : out   slv(1 downto 0);
      -- Fast ADC's SPI Ports
      adcCsL               : out   Slv2Array(1 downto 0);
      adcSck               : out   Slv2Array(1 downto 0);
      adcMiso              : in    Slv2Array(1 downto 0);
      adcMosi              : out   Slv2Array(1 downto 0);
      -- Fast DAC's SPI Ports
      dacCsL               : out   slv(1 downto 0);
      dacSck               : out   slv(1 downto 0);
      dacMiso              : in    slv(1 downto 0);
      dacMosi              : out   slv(1 downto 0);
      -- Slow DAC's SPI Ports
      dacVcoCsP            : out   slv(1 downto 0);
      dacVcoCsN            : out   slv(1 downto 0);
      dacVcoSckP           : out   slv(1 downto 0);
      dacVcoSckN           : out   slv(1 downto 0);
      dacVcoDinP           : out   slv(1 downto 0);
      dacVcoDinN           : out   slv(1 downto 0);
      -- Pass through Interfaces
      fpgaClkP             : out   slv(1 downto 0);
      fpgaClkN             : out   slv(1 downto 0);
      smaTrigP             : out   slv(1 downto 0);
      smaTrigN             : out   slv(1 downto 0);
      adcCalP              : out   slv(1 downto 0);
      adcCalN              : out   slv(1 downto 0);
      lemoDinP             : in    Slv2Array(1 downto 0);
      lemoDinN             : in    Slv2Array(1 downto 0);
      lemoDoutP            : out   Slv2Array(1 downto 0);
      lemoDoutN            : out   Slv2Array(1 downto 0);
      bcmL                 : out   slv(1 downto 0));
end Application;

architecture mapping of Application is

   constant AXI_BASE_ADDR_C : slv(31 downto 0) := x"80000000";

   constant NUM_AXI_MASTERS_C : natural := 9;

   constant AMC_INDEX_C          : natural := 0;
   constant DAQ_MUX0_INDEX_C     : natural := 1;
   constant DAQ_MUX1_INDEX_C     : natural := 2;
   constant DAC_SIG_GEN0_INDEX_C : natural := 3;
   constant DAC_SIG_GEN1_INDEX_C : natural := 4;
   constant SYSGEN0_INDEX_C      : natural := 5;
   constant SYSGEN1_INDEX_C      : natural := 6;
   constant TIMPROC0_INDEX_C     : natural := 7;
   constant TIMPROC1_INDEX_C     : natural := 8;

   constant AMC_BASE_ADDR_C     : slv(31 downto 0) := x"00000000" + AXI_BASE_ADDR_C;
   constant DAQ_MUX0_ADDR_C     : slv(31 downto 0) := x"01000000" + AXI_BASE_ADDR_C;
   constant DAQ_MUX1_ADDR_C     : slv(31 downto 0) := x"02000000" + AXI_BASE_ADDR_C;
   constant DAC_SIG_GEN0_ADDR_C : slv(31 downto 0) := X"03000000" + AXI_BASE_ADDR_C;
   constant DAC_SIG_GEN1_ADDR_C : slv(31 downto 0) := X"04000000" + AXI_BASE_ADDR_C;
   constant SYSGEN0_ADDR_C      : slv(31 downto 0) := x"05000000" + AXI_BASE_ADDR_C;
   constant SYSGEN1_ADDR_C      : slv(31 downto 0) := x"06000000" + AXI_BASE_ADDR_C;
   constant TIMPROC0_ADDR_C     : slv(31 downto 0) := x"07000000" + AXI_BASE_ADDR_C;
   constant TIMPROC1_ADDR_C     : slv(31 downto 0) := x"08000000" + AXI_BASE_ADDR_C;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      AMC_INDEX_C          => (
         baseAddr          => AMC_BASE_ADDR_C,
         addrBits          => 24,
         connectivity      => X"0001"),
      DAQ_MUX0_INDEX_C     => (
         baseAddr          => DAQ_MUX0_ADDR_C,
         addrBits          => 24,
         connectivity      => X"0001"),
      DAQ_MUX1_INDEX_C     => (
         baseAddr          => DAQ_MUX1_ADDR_C,
         addrBits          => 24,
         connectivity      => X"0001"),
      DAC_SIG_GEN0_INDEX_C => (
         baseAddr          => DAC_SIG_GEN0_ADDR_C,
         addrBits          => 24,
         connectivity      => X"0001"),
      DAC_SIG_GEN1_INDEX_C => (
         baseAddr          => DAC_SIG_GEN1_ADDR_C,
         addrBits          => 24,
         connectivity      => X"0001"),
      SYSGEN0_INDEX_C      => (
         baseAddr          => SYSGEN0_ADDR_C,
         addrBits          => 24,
         connectivity      => X"0001"),
      SYSGEN1_INDEX_C      => (
         baseAddr          => SYSGEN1_ADDR_C,
         addrBits          => 24,
         connectivity      => X"0001"),
       TIMPROC0_INDEX_C      => (
          baseAddr          => TIMPROC0_ADDR_C,
          addrBits          => 24,
          connectivity      => X"0001"),
       TIMPROC1_INDEX_C      => (
          baseAddr          => TIMPROC1_ADDR_C,
          addrBits          => 24,
          connectivity      => X"0001")
         );

   signal writeMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal writeSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal readSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal adcClk : slv(1 downto 0);
   signal adcRst : slv(1 downto 0);

   signal jesdClk    : slv(1 downto 0);
   signal jesdClkRst : slv(1 downto 0);

   signal adcValids : Slv4Array(1 downto 0);


   signal adcValues : sampleDataVectorArray(1 downto 0, 3 downto 0);

   signal dataValids : Slv6Array(1 downto 0);

   signal dacMuxSel : slv(1 downto 0);
   signal dacSigGen : sampleDataVectorArray(1 downto 0, 1 downto 0);
   signal dacSysGen : sampleDataVectorArray(1 downto 0, 1 downto 0);
   signal dacValues : sampleDataVectorArray(1 downto 0, 1 downto 0);

   signal axilClk : sl;
   signal axilRst : sl;
   signal trigHW  : sl;
   signal trigCascBay : slv(2 downto 0);


   signal smaTrig   : slv(1 downto 0);
   signal lemoDin   : Slv2Array(1 downto 0);
   signal lemoDout  : Slv2Array(1 downto 0);
   -- to make debugging hack
   signal lemoDoutL  : Slv2Array(1 downto 0);
   signal bcm       : slv(1 downto 0);
   signal intTrig   : Slv7Array(1 downto 0);

   signal recTimingClkDouble   : slv(0 downto 0);
   signal diagnosticBusArr     : DiagnosticBusArray( 1 downto 0);

begin

   -----------------
   -- System Mapping
   -----------------
   regClk  <= ref156MHzClk;
   regRst  <= ref156MHzRst;
   axilClk <= ref156MHzClk;
   axilRst <= ref156MHzRst;

--   timingClk <= ref156MHzClk;
--   timingRst <= ref156MHzRst;

-- Due to split interface to JESD0 and JESD1 keep massage in original domain, the sync only strobe to desired clock domain (message should be stable for 1uSec or so)
   timingClk <= recTimingClk;
   timingRst <= recTimingRst;




-- configure per usage of diag data by specific Application
--   diagnosticClk <= ref156MHzClk;
--   diagnosticRst <= ref156MHzRst;
   diagnosticBus.strobe <= diagnosticBusArr(0).strobe;   -- Make output of one of the 2 AMC as master (it is delayed by 2 clock to garanty ambiguity of 2 AMC clk) --DIAGNOSTIC_BUS_INIT_C;
   diagnosticBus.timingMessage <= diagnosticBusArr(0).timingMessage;   -- same for timing
   diagnosticBus.data(DIAGNOSTIC_OUTPUTS_G/2-1 downto 0) <= diagnosticBusArr(0).data(DIAGNOSTIC_OUTPUTS_G/2-1 downto 0);
   diagnosticBus.data(DIAGNOSTIC_OUTPUTS_G-1 downto DIAGNOSTIC_OUTPUTS_G/2) <= diagnosticBusArr(1).data(DIAGNOSTIC_OUTPUTS_G/2-1 downto 0);

--   trigHW <= '0';

   ---------------------
   -- AXI-Lite Crossbar
   ---------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CONFIG_C)
      port map (
         axiClk              => axilClk,
         axiClkRst           => axilRst,
         sAxiWriteMasters(0) => regWriteMaster,
         sAxiWriteSlaves(0)  => regWriteSlave,
         sAxiReadMasters(0)  => regReadMaster,
         sAxiReadSlaves(0)   => regReadSlave,
         mAxiWriteMasters    => writeMasters,
         mAxiWriteSlaves     => writeSlaves,
         mAxiReadMasters     => readMasters,
         mAxiReadSlaves      => readSlaves);

   ----------------
   -- Dual AMC Core
   ----------------
   U_DualAmc : entity work.AmcGenericAdcDacDualCore
      generic map (
         TPD_G            => TPD_G,
         SIM_SPEEDUP_G    => SIM_SPEEDUP_G,
         SIMULATION_G     => SIMULATION_G,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(AMC_INDEX_C).baseAddr)
      port map (
         -- ADC Interface
         adcClk          => adcClk,
         adcRst          => adcRst,
         adcValids       => adcValids,
         adcValues       => adcValues,
         -- DAC interface
         dacClk          => jesdClk,
         dacRst          => jesdClkRst,
         dacValues       => dacValues,
         dacVcoCtrl      => (others => x"0000"),
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => readMasters(AMC_INDEX_C),
         axilReadSlave   => readSlaves(AMC_INDEX_C),
         axilWriteMaster => writeMasters(AMC_INDEX_C),
         axilWriteSlave  => writeSlaves(AMC_INDEX_C),
         -- Pass through Interfaces
         debugTrig       => '0', --trigHW,
         fpgaClk         => (others => recTimingClkDouble(0)),
         smaTrig         => smaTrig,
         adcCal          => "00",
         lemoDin         => lemoDin,
         lemoDout        => lemoDout,
         bcm             => bcm,
         -----------------------
         -- Application Ports --
         -----------------------
         -- JESD High Speed Ports
         jesdRxP         => jesdRxP,
         jesdRxN         => jesdRxN,
         jesdTxP         => jesdTxP,
         jesdTxN         => jesdTxN,
         -- JESD Reference Ports
         jesdClkP        => jesdClkP,
         jesdClkN        => jesdClkN,
         jesdSysRefP     => jesdSysRefP,
         jesdSysRefN     => jesdSysRefN,
         -- JESD ADC Sync Ports
         jesdRxSyncP     => jesdRxSyncP,
         jesdRxSyncN     => jesdRxSyncN,
         jesdTxSyncP     => jesdTxSyncP,
         jesdTxSyncN     => jesdTxSyncN,
         -- LMK Ports
         lmkMuxSel       => lmkMuxSel,
         lmkClkSel       => lmkClkSel,
         lmkStatus       => lmkStatus,
         lmkSck          => lmkSck,
         lmkDio          => lmkDio,
         lmkSync         => lmkSync,
         lmkCsL          => lmkCsL,
         lmkRst          => lmkRst,
         -- Fast ADC's SPI Ports
         adcCsL          => adcCsL,
         adcSck          => adcSck,
         adcMiso         => adcMiso,
         adcMosi         => adcMosi,
         -- Fast DAC's SPI Ports
         dacCsL          => dacCsL,
         dacSck          => dacSck,
         dacMiso         => dacMiso,
         dacMosi         => dacMosi,
         -- Slow DAC's SPI Ports
         dacVcoCsP       => dacVcoCsP,
         dacVcoCsN       => dacVcoCsN,
         dacVcoSckP      => dacVcoSckP,
         dacVcoSckN      => dacVcoSckN,
         dacVcoDinP      => dacVcoDinP,
         dacVcoDinN      => dacVcoDinN,
         -- Pass through Interfaces
         fpgaClkP        => fpgaClkP,
         fpgaClkN        => fpgaClkN,
         smaTrigP        => smaTrigP,
         smaTrigN        => smaTrigN,
         adcCalP         => adcCalP,
         adcCalN         => adcCalN,
         lemoDinP        => lemoDinP,
         lemoDinN        => lemoDinN,
         lemoDoutP       => lemoDoutP,
         lemoDoutN       => lemoDoutN,
         bcmL            => bcmL);

   trigCascBay(2) <= trigCascBay(0); -- to make cross and use generate
   GEN_AMC : for i in 1 downto 0 generate

      -----------------------------
      -- DAC Signal Generator block
      -----------------------------
      U_DacSignalGenerator : entity work.DacSignalGenerator
         generic map (
            TPD_G            => TPD_G,
            AXI_ERROR_RESP_G => AXI_RESP_SLVERR_C,
            ADDR_WIDTH_G     => 12,
            DATA_WIDTH_G     => 32,
            L_G              => 2,
            AXI_BASE_ADDR_G  => AXI_CONFIG_C(DAC_SIG_GEN0_INDEX_C + i).baseAddr)
         port map (
            axiClk             => axilClk,
            axiRst             => axilRst,
            devClk_i           => jesdClk(i),
            devRst_i           => jesdClkRst(i),
            trigHW_i           => intTrig(i)(1),
            axilReadMaster     => readMasters(DAC_SIG_GEN0_INDEX_C + i),
            axilReadSlave      => readSlaves(DAC_SIG_GEN0_INDEX_C + i),
            axilWriteMaster    => writeMasters(DAC_SIG_GEN0_INDEX_C + i),
            axilWriteSlave     => writeSlaves(DAC_SIG_GEN0_INDEX_C + i),
            sampleDataArr_o(0) => dacSigGen(i, 0),
            sampleDataArr_o(1) => dacSigGen(i, 1),
            enable_o           => dacMuxSel(i));


      -- DAC input Multiplexer
      -- If any of the DAC Signal generator lanes are enabled the
      -- DAC Signal generator is selected
      dacValues(i, 0) <= dacSysGen(i, 0) when dacMuxSel(i) = '0' else dacSigGen(i, 0);
      dacValues(i, 1) <= dacSysGen(i, 0) when dacMuxSel(i) = '0' else dacSigGen(i, 1);

   ------------------
   -- DAQ MUXV2 Module
   ------------------
   U_DaqMuxV2_Bay0 : entity work.DaqMuxV2
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         N_DATA_IN_G      => 6,
         N_DATA_OUT_G     => 4)
      port map (
         axiClk                        => axilClk,
         axiRst                        => axilRst,
         devClk_i                      => adcClk(i),
         devRst_i                      => adcRst(i),
         trigHw_i                      => intTrig(i)(0),
         trigCasc_i                    => trigCascBay(i+1),
         trigCasc_o                    => trigCascBay(i),
         freezeHw_i                    => intTrig(i)(INT_TRIG_SIZE_G-1),                              --freezeHwBay0,
         timeStamp_i                   => timingBus.message.timeStamp,
         axilReadMaster                => readMasters(DAQ_MUX0_INDEX_C+i),
         axilReadSlave                 => readSlaves(DAQ_MUX0_INDEX_C+i),
         axilWriteMaster               => writeMasters(DAQ_MUX0_INDEX_C+i),
         axilWriteSlave                => writeSlaves(DAQ_MUX0_INDEX_C+i),
         sampleDataArr_i(0)            => adcValues(i, 0),
         sampleDataArr_i(1)            => adcValues(i, 1),
         sampleDataArr_i(2)            => adcValues(i, 2),
         sampleDataArr_i(3)            => adcValues(i, 3),
         sampleDataArr_i(4)            => dacValues(i, 0),
         sampleDataArr_i(5)            => dacValues(i, 1),
         dataValidVec_i                => dataValids(i),
         wfClk_i                       => waveformClk,
         wfRst_i                       => waveformRst,
         rxAxisMasterArr_o             => obAppWaveformMasters(i),          -- AXIS DDR Interface
         rxAxisSlaveArr_i(0)           => obAppWaveformSlaves(i)(0).slave,  -- AXIS DDR Interface
         rxAxisSlaveArr_i(1)           => obAppWaveformSlaves(i)(1).slave,  -- AXIS DDR Interface
         rxAxisSlaveArr_i(2)           => obAppWaveformSlaves(i)(2).slave,  -- AXIS DDR Interface
         rxAxisSlaveArr_i(3)           => obAppWaveformSlaves(i)(3).slave,  -- AXIS DDR Interface
         rxAxisCtrlArr_i(0)            => obAppWaveformSlaves(i)(0).ctrl,
         rxAxisCtrlArr_i(1)            => obAppWaveformSlaves(i)(1).ctrl,
         rxAxisCtrlArr_i(2)            => obAppWaveformSlaves(i)(2).ctrl,
         rxAxisCtrlArr_i(3)            => obAppWaveformSlaves(i)(3).ctrl);  -- AXIS DDR Interface

   dataValids(i) <= adcValids(i)(1) & adcValids(i)(0) & adcValids(i);



      ----------------
      -- SYSGEN Module
      ----------------
      U_SysGen : entity work.DspCoreWrapper
         generic map (
            TPD_G => TPD_G,
            BCM_APP_TYPE_C   => BCM_APP_TYPE_C(i),
            DIAGNOSTIC_OUTPUTS_G => DIAGNOSTIC_OUTPUTS_G/2,
            AXI_ERROR_RESP_G => AXI_RESP_SLVERR_C,
            AXI_BASE_ADDR_G  => AXI_CONFIG_C(SYSGEN0_INDEX_C + i).baseAddr)
         port map(
            -- JESD Interface
            jesdClk        => adcClk(i),
            jesdRst        => adcRst(i),
            adcValues(0)   => adcValues(i, 0),
            adcValues(1)   => adcValues(i, 1),
            adcValues(2)   => adcValues(i, 2),
            adcValues(3)   => adcValues(i, 3),
            dacValues(0)   => dacSysGen(i, 0),
            dacValues(1)   => dacSysGen(i, 1),
            intTrig        => intTrig(i)(5 downto 2),

                  -- Timing bus
            timingClk      => recTimingClk,
            timingRst      => recTimingRst,
            timingBus      => timingBus,
                  -- Diagnostic Interface (diagnosticClk domain)
            diagnosticClk  => diagnosticClk,
            diagnosticRst  => diagnosticRst,
            diagnosticBus  => diagnosticBusArr(i),




            -- AXI-Lite Port
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => readMasters(SYSGEN0_INDEX_C+i),
            axiReadSlave   => readSlaves(SYSGEN0_INDEX_C+i),
            axiWriteMaster => writeMasters(SYSGEN0_INDEX_C+i),
            axiWriteSlave  => writeSlaves(SYSGEN0_INDEX_C+i));


           -----------------------------
      -- Trigger processing including timing message and generating proper local processing triggers
      -----------------------------
       U_TrigProcBlk : entity work.TrigProcBlk
          generic map (
             TPD_G            => TPD_G,
             AXI_ERROR_RESP_G => AXI_RESP_SLVERR_C,
             INT_TRIG_SIZE_G  => INT_TRIG_SIZE_G,
             AXI_BASE_ADDR_G  => AXI_CONFIG_C(TIMPROC0_INDEX_C + i).baseAddr)
          port map (
             axiClk             => axilClk,
             axiRst             => axilRst,
             devClk             => adcClk(i),
             devRst             => adcRst(i),
             timingClk          => recTimingClk,
             timingRst          => recTimingRst,
             timingBus          => timingBus,

             axilReadMaster     => readMasters(TIMPROC0_INDEX_C + i),
             axilReadSlave      => readSlaves(TIMPROC0_INDEX_C + i),
             axilWriteMaster    => writeMasters(TIMPROC0_INDEX_C + i),
             axilWriteSlave     => writeSlaves(TIMPROC0_INDEX_C + i),

             smaTrigO           => smaTrig(i),
             lemoDinI           => lemoDin(i),
             lemoDoutO          => lemoDout(i),
             bcmO               => bcm(i),

             intTrig            => intTrig(i)(INT_TRIG_SIZE_G-1 downto 0));

   end generate GEN_AMC;


   --------------------------------------------------------
-- Add clock manager to generate double of RecTimingClock

       U_ClockManagerUltraScale : entity work.ClockManagerUltraScale
         generic map (
            TPD_G               => TPD_G,
            INPUT_BUFG_G        => false,
            FB_BUFG_G           => true,
            NUM_CLOCKS_G        => 1,
            -- MMCM attributes
            DIVCLK_DIVIDE_G     => 1,
            CLKFBOUT_MULT_F_G   => 1.0,
            CLKFBOUT_MULT_G     => 6,
            CLKOUT0_DIVIDE_F_G  => 1.0,
            CLKOUT0_DIVIDE_G    => 3,
            CLKIN_PERIOD_G      => 5.385

            )
         port map (
            clkIn           => recTimingClk,
            rstIn           => recTimingRst,
            clkOut          => recTimingClkDouble,
            rstOut          => open,
            locked          => open);

end mapping;
