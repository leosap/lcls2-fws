-------------------------------------------------------------------------------
-- Title      : Single lane signal generator
-------------------------------------------------------------------------------
-- File       : SigGenLane.vhd
-- Author     : Uros Legat  <ulegat@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2014-04-02
-- Last update: 2015-08-18
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:  Single lane arbitrary periodic signal generator
--               The module contains a AXI-Lite accessible block RAM where the
--               signal is defined.
--               When the module is enabled it periodically reads the block RAM contents
--               and outputs the contents.
--               The signal period is defined in user register.
--               Signal has to be disabled while the periodSize_i or RAM contents is being changed.
--               When disabled is outputs signal zero (Offset binary 0x8000) defined in Jesd204bPkg
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
use work.AxiStreamPkg.all;
use work.SsiPkg.all;

use work.Jesd204bPkg.all;

entity SigGenLane is
   generic (
      -- General Configurations
      TPD_G             : time                  := 1 ns;
      ADDR_WIDTH_G : integer range 1 to (2**24) := 9;
      DATA_WIDTH_G : integer range 1 to 32      := 32);
   port (
      -- AXI Clk
      axiClk_i : in sl;
      axiRst_i : in sl;

      -- JESD devClk
      devClk_i          : in  sl;
      devRst_i          : in  sl;

      -- External DAQ trigger input
      trigHW_i          : in sl;
      -- Lane number AXI number to be inserted into AXI stream
      axilReadMaster  : in    AxiLiteReadMasterType;
      axilReadSlave   : out   AxiLiteReadSlaveType;
      axilWriteMaster : in    AxiLiteWriteMasterType;
      axilWriteSlave  : out   AxiLiteWriteSlaveType;

      -- Control generation (Cannot be altered when running)
      enable_i        : in  sl;
      periodSize_i    : in  slv(ADDR_WIDTH_G-1 downto 0);
      dspDiv_i        : in  slv(15 downto 0);

      sampleData_o    : out  slv((GT_WORD_SIZE_C*8)-1 downto 0)
   );
end SigGenLane;

architecture rtl of SigGenLane is

   -- Register
   type RegType is record
      cnt    : slv(ADDR_WIDTH_G-1 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      cnt     => (others => '0')
   );

   signal r   : RegType := REG_INIT_C;
   signal rin : RegType;

   -- Signals
   signal s_rdEn : sl;
   signal s_ramData    : slv((GT_WORD_SIZE_C*8)-1 downto 0);
   signal s_sampleData : slv((GT_WORD_SIZE_C*8)-1 downto 0);

begin

   s_rdEn <= enable_i and trigHW_i; -- to play message only on request, or when enabled

   AxiDualPortRam_INST: entity work.AxiDualPortRam
   generic map (
      TPD_G        => TPD_G,
      BRAM_EN_G    => true,
      REG_EN_G     => true,
      MODE_G       => "write-first",
      ADDR_WIDTH_G => ADDR_WIDTH_G,
      DATA_WIDTH_G => DATA_WIDTH_G,
      INIT_G       => "0")
   port map (
      -- Axi clk domain
      axiClk         => axiClk_i,
      axiRst         => axiRst_i,
      axiReadMaster  => axilReadMaster,
      axiReadSlave   => axilReadSlave,
      axiWriteMaster => axilWriteMaster,
      axiWriteSlave  => axilWriteSlave,


      -- Dev clk domain
      clk            => devClk_i,
      rst            => devRst_i,
      en             => s_rdEn,
      addr           => r.cnt,
      dout           => s_ramData);

   -- Address counter
   comb : process (r, devRst_i, periodSize_i, s_rdEn) is
      variable v : RegType;
   begin
      -- rateDiv clock generator
      -- divClk is aligned to trig on rising edge of trig_i.
      if (s_rdEn = '0' ) then
         v.cnt  := (others => '0');
      elsif (r.cnt = periodSize_i) then
         v.cnt  := (others => '0');
      else
         v.cnt := r.cnt + 1;
      end if;

      if (devRst_i = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
   end process comb;

   seq : process (devClk_i) is
   begin
      if (rising_edge(devClk_i)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

   -- Output assignment
   s_sampleData <= s_ramData when s_rdEn = '1' else outSampleZero(2, GT_WORD_SIZE_C);
   sampleData_o <= s_sampleData;
end rtl;
