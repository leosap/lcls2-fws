-------------------------------------------------------------------------------
-- File       : AppCore.vhd
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2017-02-04
-- Last update: 2017-02-23
-------------------------------------------------------------------------------
-- Description: Application Core's Top Level
--
-- Note: Common-to-Application interface defined in HPS ESD: LCLSII-2.7-ES-0536
--
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
use work.AppTopPkg.all;
use work.AdcIntProcPkg.all;

entity AppCore is
   generic (
      TPD_G            : time             := 1 ns;
      SIM_SPEEDUP_G    : boolean          := false;
      SIMULATION_G     : boolean          := false;
      INT_TRIG_SIZE_G  : positive         := 7;
      DIAGNOSTIC_OUTPUTS_G  : integer range 1 to 32     := 28;
      AXI_BASE_ADDR_G  : slv(31 downto 0) := x"80000000";
      AXI_ERROR_RESP_G : slv(1 downto 0)  := AXI_RESP_SLVERR_C);
   port (
      -- Clocks and resets   
      jesdClk             : in    slv(1 downto 0);
      jesdRst             : in    slv(1 downto 0);
      jesdClk2x           : in    slv(1 downto 0);
      jesdRst2x           : in    slv(1 downto 0);
      -- DaqMux/Trig Interface (timingClk domain) 
      freezeHw            : out   slv(1 downto 0);
      evrTrig             : in    AppTopTrigType;
      trigHw              : out   slv(1 downto 0);
      -- JESD SYNC Interface (jesdClk[1:0] domain)
      jesdSysRef          : out   slv(1 downto 0);
      jesdRxSync          : in    slv(1 downto 0);
      jesdTxSync          : out   slv(1 downto 0);
      -- ADC/DAC/Debug Interface (jesdClk[1:0] domain)
      adcValids           : in    Slv7Array(1 downto 0);
      adcValues           : in    sampleDataVectorArray(1 downto 0, 6 downto 0);
      dacValids           : out   Slv7Array(1 downto 0);
      dacValues           : out   sampleDataVectorArray(1 downto 0, 6 downto 0);
      debugValids         : out   Slv4Array(1 downto 0);
      debugValues         : out   sampleDataVectorArray(1 downto 0, 3 downto 0);
      -- DAC Signal Generator Interface
      -- If SIG_GEN_LANE_MODE_G = '0', (jesdClk[1:0] domain)
      -- If SIG_GEN_LANE_MODE_G = '1', (jesdClk2x[1:0] domain)
      dacSigCtrl          : out   DacSigCtrlArray(1 downto 0);
      dacSigStatus        : in    DacSigStatusArray(1 downto 0);
      dacSigValids        : in    Slv7Array(1 downto 0);
      dacSigValues        : in    sampleDataVectorArray(1 downto 0, 6 downto 0);
      -- AXI-Lite Interface (axilClk domain) [0x8FFFFFFF:0x80000000]
      axilClk             : in    sl;
      axilRst             : in    sl;
      axilReadMaster      : in    AxiLiteReadMasterType;
      axilReadSlave       : out   AxiLiteReadSlaveType;
      axilWriteMaster     : in    AxiLiteWriteMasterType;
      axilWriteSlave      : out   AxiLiteWriteSlaveType;
      ----------------------
      -- Top Level Interface
      ----------------------
      -- Timing Interface (timingClk domain) 
      timingClk           : in    sl;
      timingRst           : in    sl;
      timingBus           : in    TimingBusType;
      timingPhy           : out   TimingPhyType;
      timingPhyClk        : in    sl;
      timingPhyRst        : in    sl;
      -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk       : out   sl;
      diagnosticRst       : out   sl;
      diagnosticBus       : out   DiagnosticBusType;
      -- Backplane Messaging Interface  (axilClk domain)
      obBpMsgClientMaster : out   AxiStreamMasterType;
      obBpMsgClientSlave  : in    AxiStreamSlaveType;
      ibBpMsgClientMaster : in    AxiStreamMasterType;
      ibBpMsgClientSlave  : out   AxiStreamSlaveType;
      obBpMsgServerMaster : out   AxiStreamMasterType;
      obBpMsgServerSlave  : in    AxiStreamSlaveType;
      ibBpMsgServerMaster : in    AxiStreamMasterType;
      ibBpMsgServerSlave  : out   AxiStreamSlaveType;
      -- Application Debug Interface (axilClk domain)
      obAppDebugMaster    : out   AxiStreamMasterType;
      obAppDebugSlave     : in    AxiStreamSlaveType;
      ibAppDebugMaster    : in    AxiStreamMasterType;
      ibAppDebugSlave     : out   AxiStreamSlaveType;
      -- MPS Concentrator Interface (ref156MHzClk domain)
      mpsObMasters        : in    AxiStreamMasterArray(14 downto 0);
      mpsObSlaves         : out   AxiStreamSlaveArray(14 downto 0);
      -- Misc. Interface
      ipmiBsi             : in    BsiBusType;
      gthFabClk           : in    sl;
      ethPhyReady         : in    sl;
      -----------------------
      -- Application Ports --
      -----------------------      
      -- AMC's JTAG Ports
      jtagPri             : inout Slv5Array(1 downto 0);
      jtagSec             : inout Slv5Array(1 downto 0);
      -- AMC's FPGA Clock Ports
      fpgaClkP            : inout Slv2Array(1 downto 0);
      fpgaClkN            : inout Slv2Array(1 downto 0);
      -- AMC's System Reference Ports
      sysRefP             : inout Slv4Array(1 downto 0);
      sysRefN             : inout Slv4Array(1 downto 0);
      -- AMC's Sync Ports
      syncInP             : inout Slv4Array(1 downto 0);
      syncInN             : inout Slv4Array(1 downto 0);
      syncOutP            : inout Slv10Array(1 downto 0);
      syncOutN            : inout Slv10Array(1 downto 0);
      -- AMC's Spare Ports
      spareP              : inout Slv16Array(1 downto 0);
      spareN              : inout Slv16Array(1 downto 0);
      -- RTM's Low Speed Ports
      rtmLsP              : inout slv(53 downto 0);
      rtmLsN              : inout slv(53 downto 0);
      -- RTM's High Speed Ports
      rtmHsRxP            : in    sl;
      rtmHsRxN            : in    sl;
      rtmHsTxP            : out   sl := '0';
      rtmHsTxN            : out   sl := '1';
      -- RTM's Clock Reference 
      genClkP             : in    sl;
      genClkN             : in    sl);
end AppCore;

architecture mapping of AppCore is

   constant NUM_AXI_MASTERS_C : natural := 6;

   constant AXI_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := genAxiLiteConfig(NUM_AXI_MASTERS_C, AXI_BASE_ADDR_G, 28, 24);  -- [0x8FFFFFFF:0x80000000]

   constant AMC_INDEX_C          : natural := 0;
   constant SYSGEN0_INDEX_C      : natural := 1;
   constant SYSGEN1_INDEX_C      : natural := 2;
   constant TIMPROC0_INDEX_C     : natural := 3;
   constant TIMPROC1_INDEX_C     : natural := 4;
   constant RTM_INDEX_C          : natural := 5;

   signal axilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal axilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal locDacValids   : Slv7Array(1 downto 0)                         := (others => (others => '0'));
   signal locDacValues   : sampleDataVectorArray(1 downto 0, 6 downto 0) := (others => (others => x"0000_0000"));
   signal locDebugValids : Slv4Array(1 downto 0)                         := (others => (others => '0'));
   signal locDebugValues : sampleDataVectorArray(1 downto 0, 3 downto 0) := (others => (others => x"0000_0000"));

   -- Modifications LS
   -- to make debugging hack
   signal lemoDout  : Slv2Array(1 downto 0);
   signal lemoDin   : Slv2Array(1 downto 0);
   signal bcm       : slv(1 downto 0);
   signal smaTrig : slv(1 downto 0);
   signal adcCal : slv(1 downto 0);
   signal fpgaClk : slv(1 downto 0);

   signal TimingClkDouble   : slv(0 downto 0);
   signal diagnosticBusArr     : DiagnosticBusArray( 1 downto 0);

   signal timingStrobe  : sl;

   signal Board_health  : sl;
   signal EnableMsg     : sl;
   signal testMode     : sl;

   signal AMCconfigured : slv(1 downto 0);
   type   timingStreamArType is array (natural range<>) of timingStreamType;
   signal timingStream  : timingStreamArType( 1 downto 0);

   signal dout      : slv(7 downto 0);
   signal intTrig   : Slv7Array(1 downto 0);

   
begin

   dacValids <= locDacValids;
   dacValues <= locDacValues;

   debugValids <= locDebugValids;
   debugValues <= locDebugValues;

   --------------------------
   -- Terminate usued outputs
   --------------------------
--   diagnosticClk <= axilClk;
--   diagnosticRst <= axilRst;
--   diagnosticBus <= DIAGNOSTIC_BUS_INIT_C;

   obBpMsgClientMaster <= AXI_STREAM_MASTER_INIT_C;
   ibBpMsgClientSlave  <= AXI_STREAM_SLAVE_FORCE_C;

   obBpMsgServerMaster <= AXI_STREAM_MASTER_INIT_C;
   ibBpMsgServerSlave  <= AXI_STREAM_SLAVE_FORCE_C;

   obAppDebugMaster <= AXI_STREAM_MASTER_INIT_C;
   ibAppDebugSlave  <= AXI_STREAM_SLAVE_FORCE_C;

   mpsObSlaves <= (others => AXI_STREAM_SLAVE_FORCE_C);
   dacSigCtrl(0).start(0)  <= intTrig(0)(1);
   dacSigCtrl(1).start(0)  <= intTrig(1)(1);
   timingPhy   <= TIMING_PHY_INIT_C;

   freezeHw <= intTrig(1)(6) & intTrig(0)(6);
   trigHw   <= intTrig(1)(0) & intTrig(0)(0);


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
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => axilWriteMasters,
         mAxiWriteSlaves     => axilWriteSlaves,
         mAxiReadMasters     => axilReadMasters,
         mAxiReadSlaves      => axilReadSlaves);

   ----------------
   -- AMC Interface
   ----------------
   U_DualAMC : entity work.AmcGenericAdcDacDualCore
      generic map (
         TPD_G            => TPD_G,
         TRIG_CLK_G       => false,
         CAL_CLK_G        => false,
         AXI_CLK_FREQ_G   => AXI_CLK_FREQ_C,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
         AXI_BASE_ADDR_G  => AXI_CONFIG_C(AMC_INDEX_C).baseAddr)
      port map (
         -- JESD SYNC Interface
         jesdClk         => jesdClk,
         jesdRst         => jesdRst,
         jesdSysRef      => jesdSysRef,
         jesdRxSync      => jesdRxSync,
         jesdTxSync      => jesdTxSync,
         -- ADC/DAC Interface (jesdClk domain)
         adcValids       => adcValids,
         adcValues       => adcValues,
         dacValues       => locDacValues,
         dacVcoCtrl      => (others => x"0000"),
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(AMC_INDEX_C),
         axilReadSlave   => axilReadSlaves(AMC_INDEX_C),
         axilWriteMaster => axilWriteMasters(AMC_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(AMC_INDEX_C),
         -- Pass through Interfaces
         fpgaClk         => "00",
         smaTrig         => "00",
         adcCal          => "00",
         lemoDin         => open,
         lemoDout        => (others => "00"),
         bcm             => "00",
         -----------------------
         -- Application Ports --
         -----------------------
         -- AMC's JTAG Ports
         jtagPri         => jtagPri,
         jtagSec         => jtagSec,
         -- AMC's FPGA Clock Ports
         fpgaClkP        => fpgaClkP,
         fpgaClkN        => fpgaClkN,
         -- AMC's System Reference Ports
         sysRefP         => sysRefP,
         sysRefN         => sysRefN,
         -- AMC's Sync Ports
         syncInP         => syncInP,
         syncInN         => syncInN,
         syncOutP        => syncOutP,
         syncOutN        => syncOutN,
         -- AMC's Spare Ports
         spareP          => spareP,
         spareN          => spareN);

   ----------------
   -- RTM Interface
   ----------------
   U_Rtm : entity work.RtmEmptyCore
      generic map (
         TPD_G            => TPD_G,
         AXI_ERROR_RESP_G => AXI_ERROR_RESP_G)
      port map (
         -- AXI-Lite Interface
         axilClk         => axilClk,
         axilRst         => axilRst,
         axilReadMaster  => axilReadMasters(RTM_INDEX_C),
         axilReadSlave   => axilReadSlaves(RTM_INDEX_C),
         axilWriteMaster => axilWriteMasters(RTM_INDEX_C),
         axilWriteSlave  => axilWriteSlaves(RTM_INDEX_C),
         -----------------------
         -- Application Ports --
         -----------------------      
         -- RTM's Low Speed Ports
         rtmLsP          => rtmLsP,
         rtmLsN          => rtmLsN,
         -- RTM's Clock Reference 
         genClkP         => genClkP,
         genClkN         => genClkN);
		 
		
		
--New Stuff
   GEN_AMC : for i in 1 downto 0 generate
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
            jesdClk        => jesdClk(i),
            jesdRst        => jesdRst(i),
            adcValids       => adcValids(i)(3 downto 0),
  
            adcValues(0)   => adcValues(i, 0),
            adcValues(1)   => adcValues(i, 1),
            adcValues(2)   => adcValues(i, 2),
            adcValues(3)   => adcValues(i, 3),
            dacValidsOut   => locDacValids(i)(1 downto 0),
            dacValidsIn    => dacSigValids(i)(1 downto 0),
            dacValuesOut(0) => locDacValues(i, 0),
            dacValuesOut(1) => locDacValues(i, 1),
            dacValuesin(0)  => dacSigValues(i, 0),
            dacValuesin(1)  => dacSigValues(i, 1),
            intTrig        => intTrig(i)(5 downto 2),

                  -- Timing bus
            timingClk      => TimingClk,
            timingRst      => TimingRst,
            timingBus      => timingBus,
                  -- Diagnostic Interface (diagnosticClk domain)
            diagnosticClk  => diagnosticClk,
            diagnosticRst  => diagnosticRst,
            diagnosticBus  => diagnosticBusArr(i),

            -- AXI-Lite Port
            axiClk         => axilClk,
            axiRst         => axilRst,
            axiReadMaster  => axilReadMasters(SYSGEN0_INDEX_C+i),
            axiReadSlave   => axilReadSlaves(SYSGEN0_INDEX_C+i),
            axiWriteMaster => axilWriteMasters(SYSGEN0_INDEX_C+i),
            axiWriteSlave  => axilWriteSlaves(SYSGEN0_INDEX_C+i));


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
            devClk             => jesdClk(i),
            devRst             => jesdRst(i),
            timingClk          => TimingClk,
            timingRst          => TimingRst,
            timingBus          => timingBus,
			 
			axilReadMaster     => axilReadMasters(TIMPROC0_INDEX_C + i),
			axilReadSlave      => axilReadSlaves(TIMPROC0_INDEX_C + i),
			axilWriteMaster    => axilWriteMasters(TIMPROC0_INDEX_C + i),
			axilWriteSlave     => axilWriteSlaves(TIMPROC0_INDEX_C + i),

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
            clkIn           => TimingClk,
            rstIn           => TimingRst,
            clkOut          => TimingClkDouble,
            rstOut          => open,
            locked          => open);

    diagnosticBus.strobe <= diagnosticBusArr(0).strobe;   -- Make output of one of the 2 AMC as master (it is delayed by 2 clock to garanty ambiguity of 2 AMC clk) --DIAGNOSTIC_BUS_INIT_C;
    diagnosticBus.timingMessage <= diagnosticBusArr(0).timingMessage;   -- same for timing
    diagnosticBus.data(DIAGNOSTIC_OUTPUTS_G/2-1 downto 0) <= diagnosticBusArr(0).data(DIAGNOSTIC_OUTPUTS_G/2-1 downto 0);
    diagnosticBus.data(DIAGNOSTIC_OUTPUTS_G-1 downto DIAGNOSTIC_OUTPUTS_G/2) <= diagnosticBusArr(1).data(DIAGNOSTIC_OUTPUTS_G/2-1 downto 0);


end mapping;
