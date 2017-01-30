-------------------------------------------------------------------------------
-- Title      : Generate Integer sum of required number of words
-------------------------------------------------------------------------------
-- File       : ConfigCompl4Health.vhd
-- Author     : Leonid Sapozhnikov  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2015-04-14
-- Last update: 2015-04-14
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Verifying that trigger
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

entity ConfigCompl4Health is
   generic (
      TPD_G             : time                    := 1 ns;
      TRIG_RATE_G       : real                    := 120.0E+0;              -- units of Hz
      REF_CLK_FREQ_G    : real                    := 156.25E+6            -- units of Hz
   );
   port (

      -- Clocks and Resets
      axiClk         : in   sl;
      axiRst         : in   sl;
      AqEnabled      : in   sl;
      TrigIn         : in   sl;
      AMCconfigured  : out  sl
   );
end ConfigCompl4Health;

architecture rtl of ConfigCompl4Health is

   constant REFRESH_MAX_CNT_C     : natural                     := getTimeRatio(REF_CLK_FREQ_G, TRIG_RATE_G);
   constant REFRESH_SLV_MAX_CNT_C : slv(31 downto 0) := toSlv((REFRESH_MAX_CNT_C-1), 32);
   constant REFRESH_TIMEOUT_CNT_C : slv(31 downto 0) := REFRESH_SLV_MAX_CNT_C + 1000;



   type RegType is record
      Count          : slv(31 downto 0);
      Ready          : sl;
   end record RegType;

   constant REG_INIT_C : RegType := (
      Count      => REFRESH_TIMEOUT_CNT_C,
      Ready      => '0');

   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;

begin


 ------------------------------------
   -- Logic sequence
   ------------------------------------

   comb : process (AqEnabled, TrigIn,axiRst, r) is
      variable v      : RegType;
   begin

      v := REG_INIT_C;

      -- reset
      if (TrigIn = '1' and AqEnabled = '1')  then
          v.Count  := (others => '0');
      elsif (r.Count < REFRESH_TIMEOUT_CNT_C)  then
         v.Count  :=  r.Count + 1 ;
      end if;
      if (r.Count < REFRESH_TIMEOUT_CNT_C)  then
          v.Ready  := '1';
      end if;


      if (axiRst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
   end process comb;

   AMCconfigured   <= r.Ready;

   seq : process (axiClk) is
   begin
      if (rising_edge(axiClk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;

end rtl;
