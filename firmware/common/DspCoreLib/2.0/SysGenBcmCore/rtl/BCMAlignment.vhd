-------------------------------------------------------------------------------
-- Title      : Allign data streams from BLEN and BPM
-------------------------------------------------------------------------------
-- File       : BCMAlignment.vhd
-- Author     : Leonid Sapozhnikov <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: sync steams and form data to DSP core
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
use work.AmcCarrierPkg.all;
use work.Jesd204bPkg.all;
use work.TimingPkg.all;
use work.AdcIntProcPkg.all;


entity BCMAlignment is
   generic (
      TPD_G             : time                        := 1 ns
   );
   port (
         -- AXI clocks
      axiClk         : in  sl;
      axiRst         : in  sl;
         -- JESD clocks
      jesdClk        : in  sl;
      jesdRst        : in  sl;
            -- Precomputed ADC data
      AdcSumData     : in   sampleDataArray(2 downto 0); --Slv32Array(2 downto 0);
      AdcSumDataWe   : in  sl;
            -- Timing data
      timingClk      : in   sl;  --
      timingRst      : in   sl;  --
      timingBus      : in    TimingBusType;

         --Testing data
      SimAdcSumData  : in   Slv32Array(2 downto 0);
      TestMode       : in   slv(2 downto 0);   -- bit 0 unused, bit 1 replace ADCs, bit 2 enable operation(ready)
      -- Outputs
      Bcm2DspRcrd   : out  Bcm2DspRcrdType
   );

--   attribute dont_touch                 : string;
--   attribute dont_touch  of BCMAlignment : architecture is “yes”;
end BCMAlignment;

architecture rtl of BCMAlignment is

   signal ConfDoneAxi            : sl;
   signal ConfDoneJesd           : slv(0 downto 0);
   signal ConfDoneTim            : slv(0 downto 0);

   signal timingFrameSlv         : slv(TIMING_MESSAGE_BITS_C-1 downto 0);
   signal timingFrameOutSlv      : slv(TIMING_MESSAGE_BITS_C-1 downto 0);
   signal TimingMessageOut       : TimingMessageType;

   signal timingWe               : sl;

   signal AdcSumDataSlv         : slv(96-1 downto 0);
   signal AdcSumDataOutSlv      : slv(96-1 downto 0);
   signal AdcSumDataOut         : Slv32Array(2 downto 0);

   signal AdcSumsWe             : sl;

   signal AdcValid_lcl          : sl;


   type RegType is record
      ADCValid      : sl;
      Bcm2DspRcrd   : Bcm2DspRcrdType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      ADCValid   => '0',
      Bcm2DspRcrd => BCM_2_DSP_RCRD_INIT_C
      );


   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;


begin


     SyncFifo_Timing : entity work.SynchronizerFifo
     generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => 1
     )
     port map (
      wr_clk => axiClk,
      din    => TestMode(2 downto 2),
      rd_clk => timingClk,
      dout   => ConfDoneTim
     );


     SyncFifo_Jesd : entity work.SynchronizerFifo
     generic map (
      TPD_G        => TPD_G,
      DATA_WIDTH_G => 1
     )
     port map (
      wr_clk => axiClk,
      din    => TestMode(2 downto 2),
      rd_clk => jesdClk,
      dout   => ConfDoneJesd
     );

   ConfDoneAxi <= TestMode(2);
-- Preprocessing and store input data
-- Store Timing message for future processing
  timingFrameSlv       <= toSlv(TimingBus.message);
  timingWe       <= timingBus.strobe and ConfDoneTim(0);

   SynchronizerFifo_TM : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => timingFrameSlv'length)
      port map (
         rst    => timingRst,
         wr_clk => timingClk,
         wr_en  => timingWe,
         din    => timingFrameSlv,
         rd_clk => axiClk,
         valid  => open,
         dout   => timingFrameOutSlv);


  TimingMessageOut <=  toTimingMessageType(timingFrameOutSlv);

-- Store ADC sum data for future processing
  AdcSumDataSlv       <= AdcSumData(2) & AdcSumData(1) & AdcSumData(0);
  AdcSumsWe       <= AdcSumDataWe and ConfDoneJesd(0);

      SynchronizerFifo_D : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => AdcSumDataSlv'length)
      port map (
         rst    => jesdRst,
         wr_clk => jesdClk,
         wr_en  => AdcSumsWe,
         din    => AdcSumDataSlv,
         rd_clk => axiClk,
         valid  => AdcValid_lcl,   --
         dout   => AdcSumDataOutSlv);

   AdcSumDataOut(2) <=  AdcSumDataOutSlv(95 downto 64);
   AdcSumDataOut(1) <=  AdcSumDataOutSlv(63 downto 32);
   AdcSumDataOut(0) <=  AdcSumDataOutSlv(31 downto 0);


  ------------------------------------
   -- Logic sequence
   ------------------------------------

   comb : process (TimingMessageOut, SimAdcSumData, AdcSumDataOut, ADCValid_lcl, TestMode, axiRst , r) is
      variable v      : RegType;
   begin

      -- Keep at 0 unless detected
      v := r;
      v.ADCValid := '0';

      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      -- Outputs
     if (ADCValid_lcl = '1') then
        v.Bcm2DspRcrd.ADCvalid := '1';
        v.Bcm2DspRcrd.TimingMessageOut := TimingMessageOut;

        if (TestMode(1) = '1') then
           v.Bcm2DspRcrd.AdcSumDataOut := SimAdcSumData;
        elsif (TestMode(0) = '1') then   -- to substract bergoz offset
           v.Bcm2DspRcrd.AdcSumDataOut(2 downto 1) := AdcSumDataOut(2 downto 1);
           v.Bcm2DspRcrd.AdcSumDataOut(0) := SimAdcSumData(0);
        else
           v.Bcm2DspRcrd.AdcSumDataOut := AdcSumDataOut;
        end if;
      else
         v.Bcm2DspRcrd.ADCvalid := '0';
      end if;


      rin <= v;
   end process comb;

   Bcm2DspRcrd <= r.bcm2DspRcrd;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end rtl;
