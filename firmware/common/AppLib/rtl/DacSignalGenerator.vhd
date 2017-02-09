-------------------------------------------------------------------------------
-- Title      : Signal Generator for JESD DAC
-------------------------------------------------------------------------------
-- File       : DacSignalGenerator.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory (Cosylab)
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Signal generator top module.
--     Currently contains 2 signal generator lanes.
--     To change the number of lanes:
--          - Change L_G,
--          - adjust uncomment AXI Lite Config and Signals.
--
--     Module has its own AxiLite register interface and access to AXI lite and
--     AXIlite RAM modules for each lane.
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 LLRF Development'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 LLRF Development', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.

-- leosap 2/26/2016 changed to relative address to simplify flow
-- added hardware start
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.StdRtlPkg.all;
use work.AxiLitePkg.all;
use work.AxiStreamPkg.all;
use work.SsiPkg.all;
use work.AmcCarrierPkg.all;

use work.Jesd204bPkg.all;

entity DacSignalGenerator is
   generic (
      TPD_G             : time                        := 1 ns;

      -- AXI Lite and stream generics
      AXI_ERROR_RESP_G  : slv(1 downto 0)             := AXI_RESP_SLVERR_C;

      ADDR_WIDTH_G : integer range 1 to (2**24) := 9;
      DATA_WIDTH_G : integer range 1 to 32      := 32;

     --Number of data lanes
      L_G : positive := 2;
      AXI_BASE_ADDR_G          : slv(31 downto 0)       := (others => '0')
   );
   port (

      -- Clocks and Resets
      axiClk         : in    sl;
      axiRst         : in    sl;

      -- Clocks and Resets
      devClk_i       : in    sl;
      devRst_i       : in    sl;

      -- External DAQ trigger input
      trigHW_i       : in sl;

      -- AXI-Lite Register Interface
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Enabled output (DAC mux select)
      -- If the Signal gen is disabled the System generator core drives DAC
      enable_o  : out sl;

      -- Sample data output
      sampleDataArr_o   : out   sampleDataArray(L_G-1 downto 0)
   );
end DacSignalGenerator;

architecture rtl of DacSignalGenerator is

 -- Internal signals

   -- Generator signals
   signal s_laneEn     : slv(L_G-1 downto 0);
   signal s_periodSize : slv(ADDR_WIDTH_G-1 downto 0);
   signal s_dspDiv     : slv(15 downto 0);
   signal s_trigHw   : sl;

   -------------------------------------------------------------------------------------------------
   -- AXI Lite Config and Signals
   -------------------------------------------------------------------------------------------------

   constant NUM_AXI_MASTERS_C : natural := L_G+1;

   constant DAC_AXIL_INDEX_C       : natural   := 0;
   constant LANE_INDEX_C           : natural   := 1;


   constant DAC_ADDR_C     : slv(31 downto 0)   := X"0000_0000"+ AXI_BASE_ADDR_G;
   constant LANE0_C        : slv(31 downto 0)   := X"0001_0000"+ AXI_BASE_ADDR_G;
   constant LANE1_C        : slv(31 downto 0)   := X"0002_0000"+ AXI_BASE_ADDR_G;
   constant LANE2_C        : slv(31 downto 0)   := X"0003_0000"+ AXI_BASE_ADDR_G;
   constant LANE3_C        : slv(31 downto 0)   := X"0005_0000"+ AXI_BASE_ADDR_G;
   constant LANE4_C        : slv(31 downto 0)   := X"0006_0000"+ AXI_BASE_ADDR_G;
   constant LANE5_C        : slv(31 downto 0)   := X"0007_0000"+ AXI_BASE_ADDR_G;

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      DAC_AXIL_INDEX_C => (
         baseAddr          => DAC_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+0    => (
         baseAddr          => LANE0_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+1    => (
         baseAddr          => LANE1_C,
         addrBits          => 12,
         connectivity      => X"0001"));
      -- LANE_INDEX_C+2    => (
         -- baseAddr          => LANE2_C,
         -- addrBits          => 12,
         -- connectivity      => X"0001"),
      -- LANE_INDEX_C+3 => (
         -- baseAddr          => LANE3_C,
         -- addrBits          => 12,
         -- connectivity      => X"0001"),
      -- LANE_INDEX_C+4    => (
         -- baseAddr          => LANE4_C,
         -- addrBits          => 12,
         -- connectivity      => X"0001"),
      -- LANE_INDEX_C+5    => (
         -- baseAddr          => LANE5_C,
         -- addrBits          => 12,
         -- connectivity      => X"0001"));

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

begin
   -----------------------------------------------------------
   -- Trigger
   -----------------------------------------------------------
   -- Synchronise external HW trigger input to devClk_i
   Synchronizer_sysref_INST : entity work.Synchronizer
      generic map (
         TPD_G          => TPD_G,
         RST_POLARITY_G => '1',
         OUT_POLARITY_G => '1',
         RST_ASYNC_G    => false,
         STAGES_G       => 2,
         BYPASS_SYNC_G  => false,
         INIT_G         => "0")
      port map (
         clk     => devClk_i,
         rst     => devRst_i,
         dataIn  => trigHW_i,
         dataOut => s_trigHw
         );

   -----------------------------------------------------------
   -- AXI lite
   -----------------------------------------------------------

   -- DAC Axi Crossbar
   DACAxiCrossbar : entity work.AxiLiteCrossbar
      generic map (
         TPD_G              => TPD_G,
         NUM_SLAVE_SLOTS_G  => 1,
         NUM_MASTER_SLOTS_G => NUM_AXI_MASTERS_C,
         MASTERS_CONFIG_G   => AXI_CROSSBAR_MASTERS_CONFIG_C)
      port map (
         axiClk              => axiClk,
         axiClkRst           => axiRst,
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);

   -- DAQ control register interface
   AxiLiteGenRegItf_INST: entity work.AxiLiteGenRegItf
   generic map (
      TPD_G            => TPD_G,
      AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
      ADDR_WIDTH_G     => ADDR_WIDTH_G,
      L_G              => L_G)
   port map (
      axiClk_i        => axiClk,
      axiRst_i        => axiRst,
      devClk_i        => devClk_i,
      devRst_i        => devRst_i,
      axilReadMaster  => locAxilReadMasters(DAC_AXIL_INDEX_C),
      axilReadSlave   => locAxilReadSlaves(DAC_AXIL_INDEX_C),
      axilWriteMaster => locAxilWriteMasters(DAC_AXIL_INDEX_C),
      axilWriteSlave  => locAxilWriteSlaves(DAC_AXIL_INDEX_C),
      enable_o        => s_laneEn,
      periodSize_o    => s_periodSize,
      dspDiv_o        => s_dspDiv);

   -----------------------------------------------------------
   -- Signal generator lanes
   -----------------------------------------------------------
   genTxLanes : for I in L_G-1 downto 0 generate
      SigGenLane_INST: entity work.SigGenLane
         generic map (
            TPD_G        => TPD_G,
            ADDR_WIDTH_G => ADDR_WIDTH_G,
            DATA_WIDTH_G => DATA_WIDTH_G)
         port map (
            enable_i        => s_laneEn(I),
            devClk_i        => devClk_i,
            devRst_i        => devRst_i,
            axiClk_i        => axiClk,
            axiRst_i        => axiRst,
            trigHW_i        => s_trigHw,
            axilReadMaster  => locAxilReadMasters(LANE_INDEX_C+I),
            axilReadSlave   => locAxilReadSlaves(LANE_INDEX_C+I),
            axilWriteMaster => locAxilWriteMasters(LANE_INDEX_C+I),
            axilWriteSlave  => locAxilWriteSlaves(LANE_INDEX_C+I),
            periodSize_i    => s_periodSize,
            dspDiv_i        => s_dspDiv,
            sampleData_o    => sampleDataArr_o(I));
   end generate genTxLanes;
   -----------------------------------------------------

   -- Enable output (To select Signal generator or System generator)
   enable_o <= uOr(s_laneEn);

end rtl;
