-------------------------------------------------------------------------------
-- Title      : Generate Integer sum of required number of words
-------------------------------------------------------------------------------
-- File       : DataReady.vhd
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



entity DataReady is
   generic (
      TPD_G             : time                        := 1 ns
   );
   port (

      -- Clocks and Resets
      jesdClk         : in   sl;
      jesdRst         : in   sl;
      adcValidOutV    : in   slv(2 downto 0);
      adcValidOut     : out  sl
   );
end DataReady;

architecture rtl of DataReady is

   type RegType is record
      adcValidOut    : sl;
      adcValidOutV   : slv(2 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (
      adcValidOut       => '0',
      adcValidOutV      => "000");

   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;

begin


 ------------------------------------
   -- Logic sequence
   ------------------------------------

   comb : process (adcValidOutV, jesdRst, r) is
      variable v      : RegType;
   begin

      -- Keep at 0 unless detected
      v := r;

      -- reset
      if (r.adcValidOut= '1')  then
          v.adcValidOutV  := (others => '0');
      else
         v.adcValidOutV := r.adcValidOutV or adcValidOutV;
      end if;

      if (r.adcValidOut= '1')  then
          v.adcValidOut  := '0';
      elsif (r.adcValidOutV = "111") then
         v.adcValidOut  := '1';
      end if;

      if (jesdRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
   end process comb;

   adcValidOut   <= r.adcValidOut;

   seq : process (jesdClk) is
   begin
      if (rising_edge(jesdClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
