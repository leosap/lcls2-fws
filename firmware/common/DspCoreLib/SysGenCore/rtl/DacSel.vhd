-------------------------------------------------------------------------------
-- Title      : Select source of DAC - memory or ADC
-------------------------------------------------------------------------------
-- File       : DacSel.vhd
-- Author     : Leonid Sapozhnikov  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Combine 3 sum ready and generate pulse when all 3 ready
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
use work.AdcIntProcPkg.all;



entity DacSel is
   generic (
      TPD_G             : time                        := 1 ns
   );
   port (

      -- Clocks and Resets
      jesdClk         : in   sl;
      jesdRst         : in   sl;
      DacSrs          : in   slv(1 downto 0);
      adcValids       : in   sl;
      adcValuesIn     : in   slv(31 downto 0);
      adcValids2      : in   sl;
      adcValuesIn2    : in   slv(31 downto 0);
      dacValidsOut    : out  sl;
      dacValidsIn     : in   sl;
      dacValuesOut    : out  slv(31 downto 0);
      dacValuesIn     : in   slv(31 downto 0)

   );
end DacSel;

architecture rtl of DacSel is

   type RegType is record
      dacValidOut    : sl;
      dacValueOut   : slv(31 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      dacValidOut       => '0',
      dacValueOut      => (others => '0'));

   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;

begin


 ------------------------------------
   -- Logic sequence
   ------------------------------------

   comb : process (DacSrs, adcValids, adcValuesIn, dacValidsIn, dacValuesIn, jesdRst, r) is
      variable v      : RegType;
   begin

      v := r;
      -- reset
      if (DacSrs(0)= '1')  then
          v.dacValidOut  := adcValids;
          v.dacValueOut  := adcValuesIn;
      elsif (DacSrs(1)= '1')  then
          v.dacValidOut  := adcValids2;
          v.dacValueOut  := adcValuesIn2;
      else
         v.dacValidOut := dacValidsIn;
         v.dacValueOut := dacValuesIn;
      end if;

      if (jesdRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
   end process comb;

   dacValidsOut   <= r.dacValidOut;
   dacValuesOut   <= r.dacValueOut;

   seq : process (jesdClk) is
   begin
      if (rising_edge(jesdClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
