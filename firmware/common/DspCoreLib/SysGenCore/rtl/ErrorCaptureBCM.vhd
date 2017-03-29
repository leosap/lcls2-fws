-------------------------------------------------------------------------------
-- Title      : Allign data streams from BLEN and BPM
-------------------------------------------------------------------------------
-- File       : errorCaptureBCM.vhd
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
	  
entity errorCaptureBCM is
   generic (
      TPD_G             : time                        := 1 ns
   );
   port (
          -- jesdClk clocks
      jesdClk         : in  sl;
      jesdRst         : in  sl;
         -- AXI clocks
      Clk             : in  sl;
      Rst             : in  sl;
	  
      adcValidOut     : in  slv(3 downto 0);
	  AdcValids       : in  slv(3 downto 0);
	  ethPhyReady     : in  sl;
      timingBus       : in  timingBusType;
	  dsperr          : in  slv(7 downto 0);
	        -- Outputs
      detError        : out  detErrorType
   );

--   attribute dont_touch                 : string;
--   attribute dont_touch  of errorCaptureBCM : architecture is “yes”;
end errorCaptureBCM;

architecture rtl of errorCaptureBCM is

   type RegType is record
      detError        : detErrorType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      detError => DETECTED_ERROR_INIT_C
      );


   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;
   signal InputSignalsSlv       : slv(5 downto 0);
   signal InputSignalOutsSlv       : slv(5 downto 0);
   


begin

   
   detError <= r.detError;

   
  InputSignalsSlv       <= timingBus.v2.linkUp & ethPhyReady & AdcValids;

   SynchronizerFifo_TM : entity work.SynchronizerFifo
      generic map (
         TPD_G        => TPD_G,
         DATA_WIDTH_G => 6)
      port map (
         wr_clk => jesdClk,
         din    => InputSignalsSlv,
         rd_clk => Clk,
         dout   => InputSignalOutsSlv);

  ------------------------------------
   -- Logic sequence
   ------------------------------------

   comb : process (InputSignalOutsSlv, adcValidOut, dsperr, Rst , r) is
      variable v      : RegType;
   begin

      -- Keep at 0 unless detected
      v := r;
      v.detError.Err := '0';

-- Otput status generation	  
	  if (adcValidOut = '1') then -- collect data between processing pulses
        v.detError.status(5 downto 0) := InputSignalOutsSlv;
		v.detError.status(9 downto 6) := NOT(adcValidOut);
		v.detError.status(11 downto 10) := dsperr(1 downto 0);
	  else
        v.detError.status(5 downto 0) := r.diagnosticBus.strobe(5 downto 0) OR InputSignalOutsSlv; -- 
		v.detError.status(9 downto 6) := r.diagnosticBus.strobe(9 downto 6) OR NOT(adcValidOut);
		v.detError.status(11 downto 10) := r.diagnosticBus.strobe(11 downto 10) OR dsperr(1 downto 0);
      end if;
	  
 -- Otput err generation	  
	  if (adcValidOut = '1') then -- 
        v.detError.err := '0';
	  elsif (r.detError.status /= x"00000000") then -- 
        v.detError.err := '1';
      end if;
	  
      if (Rst = '1') then
         v := REG_INIT_C;
      end if;

      rin <= v;
   end process comb;

   seq : process (Clk) is
   begin
      if (rising_edge(Clk)) then
         r <= rin after TPD_G;
      end if;
   end process seq;


end rtl;
