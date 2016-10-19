-------------------------------------------------------------------------------
-- Title      : System Generator core wrapper
-------------------------------------------------------------------------------
-- File       : DspCoreMrWrapper.vhd
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

entity DspCoreMrWrapper is
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
      adcValues      : in  sampleDataArray(3 downto 0);
      dacValues      : out sampleDataArray(1 downto 0);
      intTrig        : in  slv(3 downto 0);
      mpsOut         : out  sl;
      -- Timing Interface (Timing domain)
      timingClk      : in   sl;  --
      timingRst      : in   sl;  --
      timingBus      : in    TimingBusType;
    -- Diagnostic Interface (diagnosticClk domain)
      diagnosticClk        : out  sl;
      diagnosticRst        : out  sl;
      diagnosticBus        : out   DiagnosticBusType := DIAGNOSTIC_BUS_INIT_C;
      -- AXI-Lite Port
      axiClk         : in  sl;
      axiRst         : in  sl;
      axiReadMaster  : in  AxiLiteReadMasterType;
      axiReadSlave   : out AxiLiteReadSlaveType;
      axiWriteMaster : in  AxiLiteWriteMasterType;
      axiWriteSlave  : out AxiLiteWriteSlaveType);
end DspCoreMrWrapper;

architecture mapping of DspCoreMrWrapper is

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

  signal resultValuesOut        : sampleDataArray3Array(3 downto 0);

  signal resultValidOut         : slv(3 downto 0);
  signal mpserr                 : slv(3 downto 0);


   signal lclDataBus             : Slv32Array(DIAGNOSTIC_OUTPUTS_G-1 downto 0);

   signal Bcm2DspRcrdArr : Bcm2DspRcrdArrType(3 downto 0);
   signal ADCenabled      : slv(3 downto 0);
   signal axiRstVect      : slv(1 downto 0);
   signal adcvalidvect    : slv(3 downto 0);

begin

   axiRstL <= not(axiRst);

   diagnosticClk <= axiClk;
   diagnosticRst <= axiRst;

   dacValues <= adcValues(1 downto 0);
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
   genAdcLanes : for I in 3 downto 0 generate
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
            adcValuesIn     => adcValues(I),
            adcValuesOut    => adcValuesOut(I),
            adcValidOut     => adcValidOut(I),
            timingMessage   => Bcm2DspRcrdArr(I).TimingMessageOut,
            resultValidOut  => resultValidOut(I),
            axilReadMaster  => locAxilReadMasters(REG_SPACE0_INDEX_C+I),
            axilReadSlave   => locAxilReadSlaves(REG_SPACE0_INDEX_C+I),
            axilWriteMaster => locAxilWriteMasters(REG_SPACE0_INDEX_C+I),
            axilWriteSlave  => locAxilWriteSlaves(REG_SPACE0_INDEX_C+I),
            IntTrig         => intTrig(I));
   end generate genAdcLanes;
   -----------------------------------------------------

 genDataAlign : for I in 1 downto 0 generate

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

         Bcm2DspRcrd    => Bcm2DspRcrdArr(I));
 end generate genDataAlign;

  axiRstVect(1 downto 0) <= axiRst & axiRst;
  AdcValidVect <= Bcm2DspRcrdArr(3).ADCValid & Bcm2DspRcrdArr(2).ADCValid & Bcm2DspRcrdArr(1).ADCValid & Bcm2DspRcrdArr(0).ADCValid;


 genDSPCores : for I in 0 downto 0 generate
   U_DspCoreMr : entity work.DspCoreMr
       port map (
          rst => axiRstVect(0 downto 0),
          clk => axiClk,
          dspcoremr_aresetn => axiRstL,
            --Inputs
          ADCvalid => AdcValidVect(I downto I),
          adcsum0 => Bcm2DspRcrdArr(I).AdcSumDataOut(0),
          adcsum1 => Bcm2DspRcrdArr(I).AdcSumDataOut(1),
          adcsum2 => Bcm2DspRcrdArr(I).AdcSumDataOut(2),
          ADCvalid1 => AdcValidVect(I+1 downto I+1),
          adcsum3 => Bcm2DspRcrdArr(I+1).AdcSumDataOut(0),
          adcsum4 => Bcm2DspRcrdArr(I+1).AdcSumDataOut(1),
          adcsum5 => Bcm2DspRcrdArr(I+1).AdcSumDataOut(2),
            --Outputs
          adcvalidout => resultValidOut(I downto I),    --Need vector
          adcres0 => resultValuesOut(I)(0),
          adcres1 => resultValuesOut(I)(1),
          adcres2 => resultValuesOut(I)(2),
           -- MPS Error vector
          mpserr => mpserr(I+0 downto I+0 ),    --Need vector

            --AXI-Lite Interface 0 - rwreg
          dspcoremr_rwreg_s_axi_awaddr  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).awaddr(5 downto 0),
          dspcoremr_rwreg_s_axi_awvalid => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).awvalid,
          dspcoremr_rwreg_s_axi_wdata   => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).wdata,
          dspcoremr_rwreg_s_axi_wstrb   => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).wstrb,
          dspcoremr_rwreg_s_axi_wvalid  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).wvalid,
          dspcoremr_rwreg_s_axi_bready  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I).bready,
          dspcoremr_rwreg_s_axi_araddr  => locAxilReadMasters(DSP_CORE0_INDEX_C+I).araddr(5 downto 0),
          dspcoremr_rwreg_s_axi_arvalid => locAxilReadMasters(DSP_CORE0_INDEX_C+I).arvalid,
          dspcoremr_rwreg_s_axi_rready  => locAxilReadMasters(DSP_CORE0_INDEX_C+I).rready,
          dspcoremr_rwreg_s_axi_awready => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I).awready,
          dspcoremr_rwreg_s_axi_wready  => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I).wready,
          dspcoremr_rwreg_s_axi_bresp   => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I).bresp,
          dspcoremr_rwreg_s_axi_bvalid  => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I).bvalid,
          dspcoremr_rwreg_s_axi_arready => locAxilReadSlaves(DSP_CORE0_INDEX_C+I).arready,
          dspcoremr_rwreg_s_axi_rdata   => locAxilReadSlaves(DSP_CORE0_INDEX_C+I).rdata,
          dspcoremr_rwreg_s_axi_rresp   => locAxilReadSlaves(DSP_CORE0_INDEX_C+I).rresp,
          dspcoremr_rwreg_s_axi_rvalid  => locAxilReadSlaves(DSP_CORE0_INDEX_C+I).rvalid,
          --AXI-Lite Interface 1
          dspcoremr_s_axi_awaddr  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).awaddr(11 downto 0),
          dspcoremr_s_axi_awvalid => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).awvalid,
          dspcoremr_s_axi_wdata   => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).wdata,
          dspcoremr_s_axi_wstrb   => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).wstrb,
          dspcoremr_s_axi_wvalid  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).wvalid,
          dspcoremr_s_axi_bready  => locAxilWriteMasters(DSP_CORE0_INDEX_C+I+1).bready,
          dspcoremr_s_axi_araddr  => locAxilReadMasters(DSP_CORE0_INDEX_C+I+1).araddr(11 downto 0),
          dspcoremr_s_axi_arvalid => locAxilReadMasters(DSP_CORE0_INDEX_C+I+1).arvalid,
          dspcoremr_s_axi_rready  => locAxilReadMasters(DSP_CORE0_INDEX_C+I+1).rready,
          dspcoremr_s_axi_awready => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I+1).awready,
          dspcoremr_s_axi_wready  => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I+1).wready,
          dspcoremr_s_axi_bresp   => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I+1).bresp,
          dspcoremr_s_axi_bvalid  => locAxilWriteSlaves(DSP_CORE0_INDEX_C+I+1).bvalid,
          dspcoremr_s_axi_arready => locAxilReadSlaves(DSP_CORE0_INDEX_C+I+1).arready,
          dspcoremr_s_axi_rdata   => locAxilReadSlaves(DSP_CORE0_INDEX_C+I+1).rdata,
          dspcoremr_s_axi_rresp   => locAxilReadSlaves(DSP_CORE0_INDEX_C+I+1).rresp,
          dspcoremr_s_axi_rvalid  => locAxilReadSlaves(DSP_CORE0_INDEX_C+I+1).rvalid);
          ADCenabled(I) <= '1';
   end generate genDSPCores;

   unusedDSPCores : for I in 3 downto 1 generate
       mpserr((I) downto (I)) <= (Others => '0');
       ADCenabled(I) <= '0';
       resultValidOut(I)     <= adcValidOut(I-1);
       resultValuesOut(I)(0) <= adcValuesOut(I-1)(0);
       resultValuesOut(I)(1) <= adcValuesOut(I-1)(1);
       resultValuesOut(I)(2) <= adcValuesOut(I-1)(2);

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




   -- assign BSA reported data
   lclDataBus(0) <= resultValuesOut(0)(0);
   lclDataBus(1) <= resultValuesOut(0)(1);
   lclDataBus(2) <= resultValuesOut(0)(2);
   lclDataBus(3) <= resultValuesOut(1)(0);
   lclDataBus(4) <= resultValuesOut(1)(1);
   lclDataBus(5) <= resultValuesOut(1)(2);
   lclDataBus(6) <= resultValuesOut(2)(0);
   lclDataBus(7) <= resultValuesOut(2)(1);
   lclDataBus(8) <= resultValuesOut(2)(2);
   lclDataBus(9) <= resultValuesOut(3)(0);
   lclDataBus(10) <= resultValuesOut(3)(1);
   lclDataBus(11) <= resultValuesOut(3)(2);
   lclDataBus(12) <=  ADCenabled(1) & '0'  & X"000" & '0' & mpsErr(1 downto 1) & ADCenabled(0) & '0' & X"000" & '0' & mpsErr(0 downto 0);
   lclDataBus(13) <=  ADCenabled(3) & '0'  & X"000" & '0' & mpsErr(3 downto 3) &  ADCenabled(2) & '0'  & X"000" & '0' & mpsErr(2 downto 2);

  diagnosticBus.strobe <= resultValidOut(0);
  diagnosticBus.data(DIAGNOSTIC_OUTPUTS_G -1 downto 0) <= lclDataBus(DIAGNOSTIC_OUTPUTS_G -1 downto 0);
  diagnosticBus.timingMessage <= Bcm2DspRcrdArr(0).TimingMessageOut;

  mpsOut <= mpsErr(0);

end mapping;
