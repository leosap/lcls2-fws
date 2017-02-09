-------------------------------------------------------------------------------
-- Title      : Signal Generator for trigger forming
-------------------------------------------------------------------------------
-- File       : TrigProcBlkMr.vhd
-- Author     : Uros Legat  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Signal trigger generator top module.
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


entity TrigProcBlkMr is
   generic (
      TPD_G             : time                        := 1 ns;
      -- AXI Lite and stream generics
      AXI_ERROR_RESP_G  : slv(1 downto 0)             := AXI_RESP_SLVERR_C;

      -- Number of trigger lines
      INT_TRIG_SIZE_G   : integer range 1 to 8      := 7;
      AXI_BASE_ADDR_G          : slv(31 downto 0)       := (others => '0')
   );
   port (

      -- Clocks and Resets
      axiClk         : in    sl;
      axiRst         : in    sl;

      -- Clocks and Resets
      devClk          : in   sl;
      devRst          : in   sl;
      timingClk       : in   sl;
      timingRst       : in   sl;
      timingBus       : in   TimingBusType;

      -- AXI-Lite Register Interface
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      intTrig         : out slv(INT_TRIG_SIZE_G-1 downto 0);

      -- Trigger input/output signals

      smaTrigO        : out   sl;
      lemoDinI        : in    slv(1 downto 0);
      lemoDoutO       : out   slv(1 downto 0);
      bcmO            : out   sl

   );
end TrigProcBlkMr;

architecture rtl of TrigProcBlkMr is

 -- Internal signals

   signal lemoDinIR : slv(1 downto 0);
   signal Tstrobe   : sl;
--   signal TstrIn : slv(0 downto 0);
--   signal Tstrout : slv(0 downto 0);
   signal intTrig_l : slv(INT_TRIG_SIZE_G+3 downto 0);


   -------------------------------------------------------------------------------------------------
   -- AXI Lite Config and Signals
   -------------------------------------------------------------------------------------------------

   constant NUM_AXI_MASTERS_C : natural := INT_TRIG_SIZE_G+5;

   constant DAC_AXIL_INDEX_C       : natural   := 0;
   constant LANE_INDEX_C           : natural   := 1;


   constant TRIGBASE_ADDR_C     : slv(31 downto 0)   := X"0000_0000"+ AXI_BASE_ADDR_G;
   constant LANE0_C             : slv(31 downto 0)   := X"0001_0000"+ AXI_BASE_ADDR_G;
   constant LANE1_C             : slv(31 downto 0)   := X"0002_0000"+ AXI_BASE_ADDR_G;
   constant LANE2_C             : slv(31 downto 0)   := X"0003_0000"+ AXI_BASE_ADDR_G;
   constant LANE3_C             : slv(31 downto 0)   := X"0004_0000"+ AXI_BASE_ADDR_G;
   constant LANE4_C             : slv(31 downto 0)   := X"0005_0000"+ AXI_BASE_ADDR_G;
   constant LANE5_C             : slv(31 downto 0)   := X"0006_0000"+ AXI_BASE_ADDR_G;
   constant LANE6_C             : slv(31 downto 0)   := X"0007_0000"+ AXI_BASE_ADDR_G;
   constant LANE7_C             : slv(31 downto 0)   := X"0008_0000"+ AXI_BASE_ADDR_G;
   constant LANE8_C             : slv(31 downto 0)   := X"0009_0000"+ AXI_BASE_ADDR_G;
   constant LANE9_C             : slv(31 downto 0)   := X"000A_0000"+ AXI_BASE_ADDR_G;
   constant LANEA_C             : slv(31 downto 0)   := X"000B_0000"+ AXI_BASE_ADDR_G;
   constant LANEB_C             : slv(31 downto 0)   := X"000C_0000"+ AXI_BASE_ADDR_G;
-- total 12 lines

   constant AXI_CROSSBAR_MASTERS_CONFIG_C : AxiLiteCrossbarMasterConfigArray(NUM_AXI_MASTERS_C-1 downto 0) := (
      DAC_AXIL_INDEX_C => (
         baseAddr          => TRIGBASE_ADDR_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+0    => (
         baseAddr          => LANE0_C ,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+1    => (
         baseAddr          => LANE1_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+2    => (
         baseAddr          => LANE2_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+3 => (
         baseAddr          => LANE3_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+4    => (
         baseAddr          => LANE4_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+5    => (
         baseAddr          => LANE5_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+6    => (
         baseAddr          => LANE6_C ,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+7    => (
         baseAddr         => LANE7_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+8    => (
         baseAddr          => LANE8_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+9 => (
         baseAddr          => LANE9_C,
         addrBits          => 12,
         connectivity      => X"0001"),
      LANE_INDEX_C+10    => (
         baseAddr          => LANEA_C,
         addrBits          => 12,
         connectivity      => X"0001")
         -- Only 11 channels enabled in version
--      LANE_INDEX_C+11    => (
--         baseAddr          => LANEB_C,
--         addrBits          => 12,
--         connectivity      => X"0001")
         );

   signal locAxilWriteMasters : AxiLiteWriteMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilWriteSlaves  : AxiLiteWriteSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadMasters  : AxiLiteReadMasterArray(NUM_AXI_MASTERS_C-1 downto 0);
   signal locAxilReadSlaves   : AxiLiteReadSlaveArray(NUM_AXI_MASTERS_C-1 downto 0);

begin

   -----------------------------------------------------------
   -- AXI lite
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
         sAxiWriteMasters(0) => axilWriteMaster,
         sAxiWriteSlaves(0)  => axilWriteSlave,
         sAxiReadMasters(0)  => axilReadMaster,
         sAxiReadSlaves(0)   => axilReadSlave,
         mAxiWriteMasters    => locAxilWriteMasters,
         mAxiWriteSlaves     => locAxilWriteSlaves,
         mAxiReadMasters     => locAxilReadMasters,
         mAxiReadSlaves      => locAxilReadSlaves);


   -- DAQ control register interface
   AxiLiteGenRegTrigCommon_INST: entity work.AxiLiteGenRegTrigCommon
   generic map (
      TPD_G            => TPD_G,
      AXI_ERROR_RESP_G => AXI_ERROR_RESP_G
      )
   port map (
      axiClk          => axiClk,
      axiRst          => axiRst,
      devClk          => devClk,
      devRst          => devRst,
      axilReadMaster  => locAxilReadMasters(DAC_AXIL_INDEX_C),
      axilReadSlave   => locAxilReadSlaves(DAC_AXIL_INDEX_C),
      axilWriteMaster => locAxilWriteMasters(DAC_AXIL_INDEX_C),
      axilWriteSlave  => locAxilWriteSlaves(DAC_AXIL_INDEX_C));

   -----------------------------------------------------------
   -- Signal generator lanes
   -----------------------------------------------------------
   genTxLanes : for I in INT_TRIG_SIZE_G+3 downto 0 generate
      TrigGenLaneMr_INST: entity work.TrigGenLaneMr
         generic map (
            TPD_G        => TPD_G,
            AXI_ERROR_RESP_G => AXI_ERROR_RESP_G,
            AXI_BASE_ADDR_G => AXI_BASE_ADDR_G)
         port map (
            axiClk          => axiClk,
            axiRst          => axiRst,
            devClk          => devClk,
            devRst          => devRst,
            TimingBus       => TimingBus,
            axilReadMaster  => locAxilReadMasters(LANE_INDEX_C+I),
            axilReadSlave   => locAxilReadSlaves(LANE_INDEX_C+I),
            axilWriteMaster => locAxilWriteMasters(LANE_INDEX_C+I),
            axilWriteSlave  => locAxilWriteSlaves(LANE_INDEX_C+I),
            lemoDinI        => lemoDinIR,
            Tstrobe         => Tstrobe,
            IntTrig         => intTrig_l(I));
   end generate genTxLanes;
   -----------------------------------------------------
-- Output triggers
      smaTrigO  <= intTrig_l(0);
      lemoDoutO <= intTrig_l(2 downto 1);
      bcmO   <= intTrig_l(3);
      intTrig <= intTrig_l(INT_TRIG_SIZE_G + 3 downto 4);

 ------------------------------------
   -- To sync input to clock and make one shot
   ------------------------------------
  genInpSync : for i in 1 downto 0 generate
      SynchronizerOneShot_Inst : entity work.SynchronizerOneShot
      generic map (
         TPD_G           => TPD_G)
      port map (
         clk      => devClk,
         rst      => devRst,
         dataIn   => lemoDinI(i),
         dataOut  => lemoDinIR(i));
  end generate genInpSync;


 ------------------------------------
   -- To sync inputs. Need to sync only strobe of timing message the rest of message should be stable in relation to strobe
   ------------------------------------
       SynchronizerOneShotStr_Inst : entity work.SynchronizerOneShot
       generic map (
          TPD_G           => TPD_G)
       port map (
          clk      => devClk,
          rst      => devRst,
          dataIn   => timingBus.strobe,
          dataOut  => Tstrobe);


end rtl;
