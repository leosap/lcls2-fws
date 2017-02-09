-------------------------------------------------------------------------------
-- Title      : Signal Generator for trigger line
-------------------------------------------------------------------------------
-- File       : TrigGen.vhd
-- Author     : Leonid Sapozhnikov  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Trigger generator
--     Respond to timing request, input signal 0/1, or software request
--     For timing it has different options. If specific field selected it must match selection between
--     programmed and actual
--     Detected pulse delayed by upto 256 clocks, and then stretched between 1 and 256 clocks
--     Finally polarity of output can be inverted
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
use work.TrigGenPkg.all;



entity TrigGen is
   generic (
      TPD_G             : time                        := 1 ns
   );
   port (

      -- Clocks and Resets
      devClk          : in   sl;
      devRst          : in   sl;
      timingBus       : in   TimingBusType;
      lemoDinI        : in   slv(1 downto 0);
      TrigSpec        : in   TrigSpecType;
      Tstrobe         : in   sl;
      IntTrig         : out  sl
   );
end TrigGen;

architecture rtl of TrigGen is

   type RegType is record
      pulse          : sl;
      pulseDel       : sl;
      pulseStr       : sl;
      cnt            : slv(7 downto 0);
      cntStr         : slv(7 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      pulse          => '0',
      pulseDel       => '0',
      pulseStr       => '0',
      cnt            => (others=>'0'),
      cntStr         => (others=>'0'));

   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;

begin



  ------------------------------------
   -- Logic sequence
   ------------------------------------

   comb : process (timingBus, devRst, Tstrobe, lemoDinI, TrigSpec, r) is
      variable v      : RegType;
   begin

      -- Keep at 0 unless detected
      v := r;
      v.pulse := '0';
      v.pulseDel := '0';


      if (Tstrobe = '1' and TrigSpec.SelectSource = "01") then
        if (TrigSpec.SelectField = "11") then
           if ((TrigSpec.fixedRate = timingBus.message.fixedRates) and (TrigSpec.beamRequest = timingBus.message.beamRequest)) then
                                                   -- only selected field compared and pulse produced
               v.pulse := '1';
           end if;
        elsif (TrigSpec.SelectField = "01") then -- only selected field compared and pulse produced
           if (TrigSpec.fixedRate = timingBus.message.fixedRates) then
               v.pulse := '1';
           end if;
        elsif (TrigSpec.SelectField = "10") then  -- only selected field compared and pulse produced
           if (TrigSpec.beamRequest = timingBus.message.beamRequest) then
               v.pulse := '1';
           end if;
        else   -- any pulse is going through
            v.pulse := '1';
        end if;
      elsif (lemoDinI(0) = '1' and TrigSpec.SelectSource = "10") then
        v.pulse := '1';
      elsif (lemoDinI(1) = '1' and TrigSpec.SelectSource = "11") then
        v.pulse := '1';
      elsif (TrigSpec.SoftTrigP = '1' and TrigSpec.SelectSource = "00") then
        v.pulse := '1';
      end if;

      -- delay
      if (r.pulse = '1' and (TrigSpec.trigDelay = "00000000"))  then
          v.pulseDel := '1';
          v.cnt  := (others => '0');
      elsif (r.pulse = '1')  then
            v.cnt  := X"01";
      elsif (r.cnt = "00000000") then
         v.cnt  := (others => '0');
      elsif (r.cnt = TrigSpec.trigDelay) then
         v.pulseDel := '1';
         v.cnt  := (others => '0');
      else
         v.cnt := r.cnt + 1;
      end if;
      -- stretch
      if (r.pulseDel = '1' and (TrigSpec.trigStretch = "00000000"))  then
          v.cntStr  := (others => '0');
      elsif (r.pulseDel = '1')  then
            v.cntStr  := X"01";
      elsif (r.cntStr = "00000000") then
         v.cntStr  := (others => '0');
      elsif (r.cntStr = TrigSpec.trigStretch) then
         v.cntStr  := (others => '0');
      else
         v.cntStr := r.cntStr + 1;
      end if;
      if (r.pulseDel = '1')  then
            v.pulseStr := '1';
      elsif (r.cntStr = "00000000") then
         v.pulseStr := '0';
      end if;

      if (devRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

-- Outputs
      IntTrig   <= TrigSpec.outPolarity xor r.pulseStr;
   end process comb;

   seq : process (devClk) is
   begin
      if (rising_edge(devClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;



end rtl;
