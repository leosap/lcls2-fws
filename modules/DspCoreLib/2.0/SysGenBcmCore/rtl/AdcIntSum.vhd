-------------------------------------------------------------------------------
-- Title      : Generate Integer sum of required number of words
-------------------------------------------------------------------------------
-- File       : AdcIntSum.vhd
-- Author     : Leonid Sapozhnikov  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Sum specified number of samples
--     Will handle any specified number of samples by properly extracting words from double word
--     Basic assumption that bits 31-16 preceed word in bits 15-0
--
-------------------------------------------------------------------------------
-- This file is part of 'LCLS2 BCM/BLEN Development'.
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
use work.TimingPkg.all;
use work.AdcIntProcPkg.all;



entity AdcIntSum is
   generic (
      TPD_G             : time                        := 1 ns
   );
   port (

      -- Clocks and Resets
      devClk          : in   sl;
      devRst          : in   sl;
      NumberSamples   : in   slv(7 downto 0);
      adcValuesIn     : in   slv(31 downto 0);
      adcValuesOut    : out  slv(31 downto 0);
      adcValidOut     : out  sl;
      IntTrig         : in  sl
   );
end AdcIntSum;

architecture rtl of AdcIntSum is

   type RegType is record
      pulseDel       : sl;
      pulseStr       : slv(1 downto 0);
      pulse          : sl;
      valid          : sl;
      cntSum         : slv(6 downto 0);
      adcDel0        : slv(31 downto 0);
      adcDel1        : slv(31 downto 0);
      adc2Sum        : slv(31 downto 0);
      adcSum         : slv(31 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      pulseDel       => '0',
      pulseStr       => "00",
      pulse          => '0',
      valid          => '0',
      cntSum         => (others=>'0'),
      adcDel0        => (others=>'0'),
      adcDel1        => (others=>'0'),
      adc2Sum        => (others=>'0'),
      adcSum         => (others=>'0'));

   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;

begin


  ------------------------------------
   -- Logic sequence
   ------------------------------------

   comb : process (NumberSamples, devRst, adcValuesIn, IntTrig, r) is
      variable v      : RegType;
   begin

      -- Keep at 0 unless detected
      v := r;
      v.pulseDel := '0';

      -- delay
      v.pulseDel := IntTrig;
      v.pulse    :=  NOT(r.pulseDel ) and IntTrig;
      v.adcDel1  := (x"0000" & adcValuesIn(31 downto 16));
      v.adcDel0  := (x"0000" & adcValuesIn(15 downto 0));
      v.adc2Sum  := (x"0000" & adcValuesIn(31 downto 16)) + (x"0000" & adcValuesIn(15 downto 0));
      v.valid    := r.pulseStr(0) or r.pulseStr(1);

      -- stretch
      if ((r.pulseDel = '0' and IntTrig = '1') and (NumberSamples(7 downto 1) = "0000000"))  then
          v.cntSum  := (others => '0');
      elsif ((r.pulseDel = '0' and IntTrig = '1') and (NumberSamples(7 downto 0) = "00000010"))  then  -- done in one clock
          v.cntSum  := (others => '0');
      elsif (r.pulseDel = '0' and IntTrig = '1')  then
            v.cntSum  := "0000001";
      elsif (r.cntSum = "00000000") then
         v.cntSum  := (others => '0');
      elsif (r.cntSum = NumberSamples(7 downto 1)) then
         v.cntSum  := (others => '0');
      else
         v.cntSum := r.cntSum + 1;
      end if;

-- generate enable pulses per word
      if (r.pulseDel = '0' and IntTrig = '1')  then
        if (NumberSamples(7 downto 1) = "0000000")  then
          if(NumberSamples(0) = '0') then
             v.pulseStr := "01";
          else
             v.pulseStr := "10";
          end if;
        else
          if(NumberSamples(0) = '0') then
             v.pulseStr := "11";
          else
             v.pulseStr := "10";
          end if;
        end if;
      elsif (r.cntSum = "0000000") then
          v.pulseStr := "00";
      elsif ((r.cntSum = NumberSamples(7 downto 1))and (NumberSamples(7 downto 1) > "0000000")) then
          if(NumberSamples(1 downto 0) = "01") then
             v.pulseStr := "01";
          elsif(NumberSamples(1 downto 0) = "11") then
             v.pulseStr := "01";
          else
             v.pulseStr := "00";
          end if;
      else
          v.pulseStr := "11";
      end if;
-- sum based on pulse enable
     -- if (r.pulse = '1')  then
      if (r.pulseDel = '0' and IntTrig = '1')  then
          v.adcSum := (Others => '0');
      elsif (r.pulseStr = "01")  then
            v.adcSum := r.adcDel0 + r.adcSum;
      elsif (r.pulseStr = "10")  then
            v.adcSum := r.adcDel1 + r.adcSum;
      elsif (r.pulseStr = "11")  then
            v.adcSum := r.adc2Sum + r.adcSum;
      end if;

      if (devRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

-- Outputs
      adcValuesOut   <= r.adcSum;
      adcValidOut   <= r.valid and NOT(r.pulseStr(0)) and NOT(r.pulseStr(1));
   end process comb;

   seq : process (devClk) is
   begin
      if (rising_edge(devClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;



end rtl;
