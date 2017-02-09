-------------------------------------------------------------------------------
-- Title      : Trigger Delay generation
-------------------------------------------------------------------------------
-- File       : TrigDelay.vhd
-- Author     : Leonid Sapozhnikov  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Trigger delay pulse by up to 256 clocks
--              Minimum delay 1 clock, or 1 clock plus TrigDelay

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




entity TrigDelay is
   generic (
      TPD_G             : time                        := 1 ns
   );
   port (

      -- Clocks and Resets
      devClk          : in   sl;
      devRst          : in   sl;
      TrigDelay       : in   slv(7 downto 0);
      IntTrigIn       : in   sl;
      IntTrigOut      : out  sl
   );
end TrigDelay;

architecture rtl of TrigDelay is

   type RegType is record
      pulseDel       : sl;
      cnt            : slv(7 downto 0);
   end record RegType;

   constant REG_INIT_C : RegType := (

      pulseDel       => '0',
      cnt            => (others=>'0'));

   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;

begin



  ------------------------------------
   -- Logic sequence
   ------------------------------------

   comb : process (IntTrigIn, devRst, TrigDelay, r) is
      variable v      : RegType;
   begin

      -- Keep at 0 unless detected
      v := r;
      v.pulseDel := '0';

      -- delay
      if (IntTrigIn = '1' and (TrigDelay = "00000000"))  then
          v.pulseDel := '1';
          v.cnt  := (others => '0');
      elsif (IntTrigIn = '1')  then
            v.cnt  := X"01";
      elsif (r.cnt = "00000000") then
         v.cnt  := (others => '0');
      elsif (r.cnt = TrigDelay) then
         v.pulseDel := '1';
         v.cnt  := (others => '0');
      else
         v.cnt := r.cnt + 1;
      end if;


      if (devRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;

-- Outputs
      IntTrigOut   <= r.pulseDel;
   end process comb;

   seq : process (devClk) is
   begin
      if (rising_edge(devClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;



end rtl;
