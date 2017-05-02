-------------------------------------------------------------------------------
-- Title      : System Generator core wrapper
-------------------------------------------------------------------------------
-- File       : DspCoreWrapper.vhd
-- Author     : Larry Ruckman  <ruckman@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-02-26
-- Last update: 2016-02-26
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
--
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
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.Jesd204bPkg.all;
use work.TimingPkg.all;
use work.AmcCarrierPkg.all;
use work.AdcIntProcPkg.all;
use work.BpmPkg.all;

entity DspCoreWrapper is
   generic (
      TPD_G : time := 1 ns;
      BCM_APP_TYPE_C    : slv(1 downto 0)             := "00";
      DIAGNOSTIC_OUTPUTS_G  : integer range 1 to 32     := DIAGNOSTIC_OUTPUTS_G;
      AXI_ERROR_RESP_G  : slv(1 downto 0)             := AXI_RESP_SLVERR_C;
      AXI_BASE_ADDR_G   : slv(31 downto 0)     := (others => '0')
      );
   port (
      -- JESD Interface
      jesdClk        : in  sl;
      jesdRst        : in  sl;
      adcValids      : in    slv(3 downto 0);
      adcValues      : in  sampleDataArray(3 downto 0);
      dacValidsOut   : out    slv(1 downto 0);
      dacValidsIn    : in    slv(1 downto 0);
      dacValuesOut   : out sampleDataArray(1 downto 0);
      dacValuesIn    : in  sampleDataArray(1 downto 0);
      intTrig        : in  slv(3 downto 0);
	  commonConfig   : in  commonConfigType;
	  ethPhyReady    : in  sl;
      -- Timing Interface (Timing domain)
      timingClk      : in   sl;  --
      timingRst      : in   sl;  --
      timingBus      : in    TimingBusType;
    -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : out  sl;
      diagnosticRst        : out  sl;
      diagnosticBus        : out   DiagnosticBusType := DIAGNOSTIC_BUS_INIT_C;
            -- Backplane Messaging Interface (bpMsgClk domain)
      bpMsgClk             : out   sl;
      bpMsgRst             : out   sl;
      tmitMessage          : out  tmitMessageType;
      -- AXI-Lite Port
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType);
end DspCoreWrapper;

architecture mapping of DspCoreWrapper is

   signal readMaster  : AxiLiteReadMasterType;
   signal readSlave   : AxiLiteReadSlaveType;
   signal writeMaster : AxiLiteWriteMasterType;
   signal writeSlave  : AxiLiteWriteSlaveType;
   signal axiRstL    : sl;

    -------------------------------------------------------------------------------------------------
   -- AXI Lite Config and Signals
   -------------------------------------------------------------------------------------------------

   constant NUM_AXI_MASTERS_C : natural := 8;

   constant DSP_CORE0_INDEX_C       : natural   := 0;
   constant REG_SPACE0_INDEX_C     : natural   := 4;


   constant DSP_CORE0_ADDR_C       : slv(31 downto 0)   := X"0000_0000" + AXI_BASE_ADDR_G;
   constant DSP_CORE1_ADDR_C       : slv(31 downto 0)   := X"0001_0000" + AXI_BASE_ADDR_G;
   constant DSP_CORE2_ADDR_C       : slv(31 downto 0)   := X"0002_0000" + AXI_BASE_ADDR_G;
   constant DSP_CORE3_ADDR_C       : slv(31 downto 0)   := X"0003_0000" + AXI_BASE_ADDR_G;
   constant REG_SPACE0_ADDR_C      : slv(31 downto 0)   := X"0004_0000" + AXI_BASE_ADDR_G;
   constant REG_SPACE1_ADDR_C      : slv(31 downto 0)   := X"0005_0000" + AXI_BASE_ADDR_G;
   constant REG_SPACE2_ADDR_C      : slv(31 downto 0)   := X"0006_0000" + AXI_BASE_ADDR_G;
   constant REG_SPACE3_ADDR_C      : slv(31 downto 0)   := X"0007_0000" + AXI_BASE_ADDR_G;

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      DSP_CORE0_INDEX_C => (
         baseAddr          => DSP_CORE0_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      DSP_CORE0_INDEX_C+1 => (
         baseAddr          => DSP_CORE1_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      DSP_CORE0_INDEX_C+2 => (
         baseAddr          => DSP_CORE2_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      DSP_CORE0_INDEX_C+3 => (
         baseAddr          => DSP_CORE3_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      REG_SPACE0_INDEX_C    => (
         baseAddr          => REG_SPACE0_ADDR_C ,
         addrBits          => 12,
         connectivity      => X"0001"),
      REG_SPACE0_INDEX_C+1    => (
         baseAddr          => REG_SPACE1_ADDR_C ,
         addrBits          => 12,
         connectivity      => X"0001"),
      REG_SPACE0_INDEX_C+2    => (
         baseAddr          => REG_SPACE2_ADDR_C ,
         addrBits          => 12,
         connectivity      => X"0001"),
      REG_SPACE0_INDEX_C+3    => (
         baseAddr          => REG_SPACE3_ADDR_C ,
         addrBits          => 12,
         connectivity      => X"0001")
         );



   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

   signal adcValuesOut        : sampleDataArray3Array(3 downto 0);
   signal ConfigSpace         : ConfigSpaceArrayType(3 downto 0);
   signal adcValidOut         : Slv(3 downto 0);

  signal resultValuesOut        : sampleDataArray3Array(3 downto 0) := (Others => (Others => (Others => '0')));
  signal floatRes               : Slv32Array(1 downto 0) := (Others => (Others => '0'));

  signal resultValidOut         : slv(3 downto 0);
  signal dsperr                 : slv(7 downto 0);


   signal lclDataBus             : Slv32Array(DIAGNOSTIC_OUTPUTS_G-1 downto 0);

   signal Bcm2DspRcrdArr : Bcm2DspRcrdArrType(3 downto 0);
   signal ADCenabled      : slv(3 downto 0);
   signal axiRstVect      : slv(1 downto 0);
   signal adcvalidvect    : slv(3 downto 0);
   signal StatusVect      : Slv32Array(1 downto 0) := (Others => (Others => '0'));
   signal tmitOut         : sl;
   signal detError        : detErrorType;
   signal AppTypeV        : slv(0 downto 0);




begin

   axiRstL <= not(axiRst);
   bpMsgClk <= axiClk;
   bpMsgRst<= axiRst;

 --  dacValues <= adcValues(1 downto 0);
   -----------------------------------------------------------
   -- AXI lite cross bar
   -----------------------------------------------------------
   U_XBAR : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         DEC_ERROR_RESP_G   => AXI_ERROR_RESP_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
      port map (
         axiClk              => axiClk,
         axiClkRst           => axiRst,
         sAxiWriteMasters(0) => axiWriteMaster,
         sAxiWriteSlaves(0)  => axiWriteSlave,
         sAxiReadMasters(0)  => axiReadMaster,
         sAxiReadSlaves(0)   => axiReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);



  -----------------------------------------------------------
   -- Initial ADC processing per ADC
   -----------------------------------------------------------
   genAdcLanes10 : for I in 1 downto 0 generate
      AdcIntProc_INST: entity work.AdcIntProc
         generic map (
            TPD_G        => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
            AXI_BASE_ADDR_G => AXI_CROSSBAR_MASTERS_CONFIG_C(REG_SPACE0_INDEX_C+I).baseAddr)
         port map (
            axiClk          => axiClk,
            axiRst          => axiRst,
            jesdClk         => jesdClk,
            jesdRst         => jesdRst,
            ConfigSpace     => ConfigSpace(I), -- Synced to axiClk
            adcValids       => adcValids(I),
            adcValuesIn     => adcValues(I),
            adcValids2      => adcValids(I+2),
            adcValuesIn2    => adcValues(I+2),
            adcValuesOut    => adcValuesOut(I),
            adcValidOut     => adcValidOut(I),
            dacValidsOut    => dacValidsOut(I),
            dacValidsIn     => dacValidsIn(I),
            dacValuesIn     => dacValuesIn(I),
            dacValuesOut    => dacValuesOut(I),
            timingMessage   => TIMING_MESSAGE_INIT_C, -- unused
            resultValidOut  => resultValidOut(I),
            axilReadMaster  => locAxilReadMasters(REG_SPACE0_INDEX_C+I),
            axilReadSlave   => locAxilReadSlaves(REG_SPACE0_INDEX_C+I),
            axilWriteMaster => locAxilWriteMasters(REG_SPACE0_INDEX_C+I),
            axilWriteSlave  => locAxilWriteSlaves(REG_SPACE0_INDEX_C+I),
            IntTrig         => intTrig(I));
   end generate genAdcLanes10;

   genAdcLanes32 : for I in 3 downto 2 generate
      AdcIntProc_INST: entity work.AdcIntProc
         generic map (
            TPD_G        => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
            AXI_BASE_ADDR_G => AXI_CROSSBAR_MASTERS_CONFIG_C(REG_SPACE0_INDEX_C+I).baseAddr)
         port map (
            axiClk          => axiClk,
            axiRst          => axiRst,
            jesdClk         => jesdClk,
            jesdRst         => jesdRst,
            ConfigSpace     => ConfigSpace(I), -- Synced to axiClk
            adcValids       => adcValids(I),
            adcValuesIn     => adcValues(I),
            adcValuesOut    => adcValuesOut(I),
            adcValidOut     => adcValidOut(I),
            dacValidsOut    => open,
            dacValidsIn     => '0',
            dacValuesIn     => (others=>'0'),
            dacValuesOut    => open,
            timingMessage   => TIMING_MESSAGE_INIT_C, -- unused
            resultValidOut  => resultValidOut(I),
            axilReadMaster  => locAxilReadMasters(REG_SPACE0_INDEX_C+I),
            axilReadSlave   => locAxilReadSlaves(REG_SPACE0_INDEX_C+I),
            axilWriteMaster => locAxilWriteMasters(REG_SPACE0_INDEX_C+I),
            axilWriteSlave  => locAxilWriteSlaves(REG_SPACE0_INDEX_C+I),
            IntTrig         => intTrig(I));
   end generate genAdcLanes32;
   -----------------------------------------------------

 genDSPCores : for I in 0 downto 0 generate

   U_BCMAlignment : entity work.BCMAlignment
      port map (
         axiClk          => axiClk,
         axiRst          => axiRst,

         jesdClk         => jesdClk,
         jesdRst         => jesdRst,

         AdcSumData      => adcValuesOut(I)(2 downto 0),
         AdcSumDataWe    => adcValidOut(I),

         timingClk       => timingClk,
         timingRst       => timingRst,
         timingBus       => timingBus,

         SimAdcSumData   => ConfigSpace(I).SimAdcSumData,
         TestMode        => ConfigSpace(I).TestMode,
		 commonConfig    => commonConfig,

         Bcm2DspRcrd    => Bcm2DspRcrdArr(I));

  axiRstVect(1 downto 0) <= axiRst & axiRst;
  AdcValidVect <= Bcm2DspRcrdArr(3).ADCValid & Bcm2DspRcrdArr(2).ADCValid & Bcm2DspRcrdArr(1).ADCValid & Bcm2DspRcrdArr(0).ADCValid;
  AppTypeV(0) <= commonConfig.AppType;
   U_DspCore : entity work.DspCore
       port map (
          rst => axiRstVect(0 downto 0),
          clk => axiClk,
          dspcore_aresetn => axiRstL,
            --Inputs
		  AppType  => AppTypeV(0 downto 0),
          ADCvalid => AdcValidVect(I downto I),
          adcsum0 => Bcm2DspRcrdArr(I).AdcSumDataOut(0),
          adcsum1 => Bcm2DspRcrdArr(I).AdcSumDataOut(1),
          adcsum2 => Bcm2DspRcrdArr(I).AdcSumDataOut(2),
            --Outputs
          adcvalidout => resultValidOut(I downto I),    --Need vector
          adcres0 => resultValuesOut(I)(0)(31 downto 0),
          adcres1 => resultValuesOut(I)(1)(31 downto 0),
          adcres2 => resultValuesOut(I)(2)(31 downto 0),
		  floatres => floatRes(I),
           -- Error vector
          dsperr => dsperr(I+0 downto I+0 ),    --Need vector
          dsperr1 => dsperr(I+1 downto I+1 ),    --Need vector

            --AXI-Lite Interface 0 - rwreg
          dspcore_rwreg_s_axi_awaddr  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).awaddr(5 downto 0),
          dspcore_rwreg_s_axi_awvalid => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).awvalid,
          dspcore_rwreg_s_axi_wdata   => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).wdata,
          dspcore_rwreg_s_axi_wstrb   => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).wstrb,
          dspcore_rwreg_s_axi_wvalid  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).wvalid,
          dspcore_rwreg_s_axi_bready  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).bready,
          dspcore_rwreg_s_axi_araddr  => locAxilReadMasters(DSP_CORE0_INDEX_C+I).araddr(5 downto 0),
          dspcore_rwreg_s_axi_arvalid => locAxilReadMasters(DSP_CORE0_INDEX_C+I).arvalid,
          dspcore_rwreg_s_axi_rready  => locAxilReadMasters(DSP_CORE0_INDEX_C+I).rready,
          dspcore_rwreg_s_axi_awready => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I).awready,
          dspcore_rwreg_s_axi_wready  => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I).wready,
          dspcore_rwreg_s_axi_bresp   => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I).bresp,
          dspcore_rwreg_s_axi_bvalid  => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I).bvalid,
          dspcore_rwreg_s_axi_arready => locAxilReadSlaves(DSP_CORE0_INDEX_C+I).arready,
          dspcore_rwreg_s_axi_rdata   => locAxilReadSlaves(DSP_CORE0_INDEX_C+I).rdata,
          dspcore_rwreg_s_axi_rresp   => locAxilReadSlaves(DSP_CORE0_INDEX_C+I).rresp,
          dspcore_rwreg_s_axi_rvalid  => locAxilReadSlaves(DSP_CORE0_INDEX_C+I).rvalid,
          --AXI-Lite Interface 1
          dspcore_s_axi_awaddr  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).awaddr(11 downto 0),
          dspcore_s_axi_awvalid => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).awvalid,
          dspcore_s_axi_wdata   => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).wdata,
          dspcore_s_axi_wstrb   => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).wstrb,
          dspcore_s_axi_wvalid  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).wvalid,
          dspcore_s_axi_bready  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).bready,
          dspcore_s_axi_araddr  => locAxilReadMasters(DSP_CORE0_INDEX_C+I+1).araddr(11 downto 0),
          dspcore_s_axi_arvalid => locAxilReadMasters(DSP_CORE0_INDEX_C+I+1).arvalid,
          dspcore_s_axi_rready  => locAxilReadMasters(DSP_CORE0_INDEX_C+I+1).rready,
          dspcore_s_axi_awready => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I+1).awready,
          dspcore_s_axi_wready  => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I+1).wready,
          dspcore_s_axi_bresp   => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I+1).bresp,
          dspcore_s_axi_bvalid  => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I+1).bvalid,
          dspcore_s_axi_arready => locAxilReadSlaves(DSP_CORE0_INDEX_C+I+1).arready,
          dspcore_s_axi_rdata   => locAxilReadSlaves(DSP_CORE0_INDEX_C+I+1).rdata,
          dspcore_s_axi_rresp   => locAxilReadSlaves(DSP_CORE0_INDEX_C+I+1).rresp,
          dspcore_s_axi_rvalid  => locAxilReadSlaves(DSP_CORE0_INDEX_C+I+1).rvalid);
          ADCenabled(I) <= '1';
   end generate genDSPCores;

   unusedDSPCores : for I in 3 downto 1 generate
       dsperr(((I+1)*2-1) downto (I*2)) <= (Others => '0');
       ADCenabled(I) <= '0';
       resultValidOut(I)     <= adcValidOut(I);
       resultValuesOut(I)(0) <= adcValuesOut(I)(0);
       resultValuesOut(I)(1) <= adcValuesOut(I)(1);
       resultValuesOut(I)(2) <= adcValuesOut(I)(2);

   end generate unusedDSPCores;

   unusedDSPCores1 : for I in 3 downto 2 generate

         AxiLiteEmpty_INST: entity work.AxiLiteEmpty
         generic map (
            TPD_G        => TPD_G)
         port map (
            axiClk          => axiClk,
            axiClkRst       => axiRst,
            axiReadMaster   => locAxilReadMasters(DSP_CORE0_INDEX_C+I),
            axiReadSlave    => locAxilReadSlaves(DSP_CORE0_INDEX_C+I),
            axiWriteMaster  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I),
            axiWriteSlave   => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I));

   end generate unusedDSPCores1;


-- Inter-trigger error capture to report it with processed data (event by event)
    errorCaptureBCM_INST: entity work.errorCaptureBCM
    generic map (
      TPD_G            => TPD_G
      )
    port map (
      jesdClk              => jesdClk,
      jesdRst              => jesdRst,
	  Clk                  => axiClk,
      Rst                  => axiRst,
	  adcValidOut          => adcValidOut,
	  AdcValids            => AdcValids,
	  ethPhyReady          => ethPhyReady,
	  timingBus            => timingBus,
	  dsperr               => dsperr,
	  detError             => detError
      );

   bsaBcmAmc_INST: entity work.bsaBcmAmc
    generic map (
      TPD_G            => TPD_G,
	  DIAGNOSTIC_OUTPUTS_G  => DIAGNOSTIC_OUTPUTS_G
      )
    port map (
      Clk                  => axiClk,
      Rst                  => axiRst,
	  ADCenabled           => ADCenabled,
	  commonConfig         => commonConfig,
	  resultValuesOut      => resultValuesOut,
	  floatRes             => floatRes,
	  detError             => detError,
	  resultValidOut       => resultValidOut,
	  Bcm2DspRcrdArr       => Bcm2DspRcrdArr,
	  diagnosticClk        => diagnosticClk,
      diagnosticRst        => diagnosticRst,
	  tmitOut              => tmitOut,
	  diagnosticBus        => diagnosticBus
      );


  tmitMessage.strobe <= tmitOut; -- always run at full MHz rate
  tmitMessage.timeStamp <= Bcm2DspRcrdArr(0).TimingMessageOut.timeStamp;
  tmitMessage.data(BPM_A_MSG_STAT_IDX) <= StatusVect(0);
  tmitMessage.data(BPM_A_MSG_TMIT_IDX) <= resultValuesOut(0)(0); --floatRes(0);
  tmitMessage.data(BPM_A_MSG_XPOS_IDX) <= x"12345678"; -- test word , unused
  tmitMessage.data(BPM_A_MSG_YPOS_IDX) <= x"87654321"; -- test word , unused
  tmitMessage.data(BPM_B_MSG_STAT_IDX) <= StatusVect(1);
  tmitMessage.data(BPM_B_MSG_TMIT_IDX) <= resultValuesOut(0)(1); --floatRes(1);   -- unused
  tmitMessage.data(BPM_B_MSG_XPOS_IDX) <= x"abcdef00"; -- test word , unused
  tmitMessage.data(BPM_B_MSG_YPOS_IDX) <= x"00fedcba"; -- test word , unused
end mapping;
