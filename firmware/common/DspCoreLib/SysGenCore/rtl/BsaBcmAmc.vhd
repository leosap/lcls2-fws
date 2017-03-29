-------------------------------------------------------------------------------
-- Title      : Allign data streams from BLEN and BPM
-------------------------------------------------------------------------------
-- File       : bsaBcmAmc.vhd
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

	  
entity bsaBcmAmc is
   generic (
      TPD_G             : time                        := 1 ns;
	  DIAGNOSTIC_OUTPUTS_G  : integer range 1 to 32     := DIAGNOSTIC_OUTPUTS_G
   );
   port (
         -- AXI clocks
      Clk             : in  sl;
      Rst             : in  sl;
      ADCenabled      : in  slv(3 downto 0);
	  commonConfig    : in  commonConfigType;
	  resultValuesOut : in  sampleDataArray3Array(3 downto 0) := (Others => (Others => (Others => '0')));
      floatRes        : in  Slv32Array(1 downto 0) := (Others => (Others => '0'));
	  detError        : in  detErrorType;
      resultValidOut  : in  slv(3 downto 0);
	  Bcm2DspRcrdArr  : in   Bcm2DspRcrdArrType(3 downto 0);
	        -- Outputs
	  diagnosticClk   : out  sl;
      diagnosticRst   : out  sl;
      tmitOut         : out  sl;
      diagnosticBus   : out  diagnosticBusType
   );

--   attribute dont_touch                 : string;
--   attribute dont_touch  of bsaBcmAmc : architecture is “yes”;
end bsaBcmAmc;

architecture rtl of bsaBcmAmc is

   type RegType is record
      diagnosticBus        : diagnosticBusType;
   end record RegType;

   constant REG_INIT_C : RegType := (
      diagnosticBus => DIAGNOSTIC_BUS_INIT_C
      );


   signal r         : RegType := REG_INIT_C;
   signal rin       : RegType;


begin

   diagnosticClk <= axiClk;
   diagnosticRst <= axiRst;
   
   diagnosticBus <= r.diagnosticBus;
   tmitOut       <= r.diagnosticBus.strobe;


  ------------------------------------
   -- Logic sequence
   ------------------------------------

   comb : process (ADCenabled, commonConfig, resultValuesOut, detError, resultValidOut, Bcm2DspRcrdArr, floatRes, Rst , r) is
      variable v      : RegType;
   begin

      -- Keep at 0 unless detected
      v := r;
      v.diagnosticBus.strobe := '0';

-- Otput strobe generation	  
	  if (commonConfig.enableCalib = '1' OR ADCenabled(0) = '0') then -- if data slow or disabled, use trigger reporting
        v.diagnosticBus.strobe := cm2DspRcrdArr(0).TimingValid;  -- calibration is slow process at 1Hz with external trigger, all the time triggered by timing pulse with same value until change
      else
        v.diagnosticBus.strobe := resultValidOut(0); -- when normal operation, need to run at full MHz
      end if;
	  
 -- Output data
      v.diagnosticBus.data(0) := resultValuesOut(0)(0);
      v.diagnosticBus.data(1) <= resultValuesOut(0)(1);
      v.diagnosticBus.data(2) <= resultValuesOut(0)(2);
      v.diagnosticBus.data(3) <= floatRes(0);
      v.diagnosticBus.data(4)(31) <= detError.err;
	  v.diagnosticBus.data(4)(30) <= commonConfig.enableCalib;
	  v.diagnosticBus.data(4)(29) <= ADCenabled(0);
	  v.diagnosticBus.data(4)(28 downto 0) <= detError.status(28 downto 0);
	  
 -- Output average
      v.diagnosticBus.fixed(0) := '0';  -- temperature corrected result, field can be averaged
	  v.diagnosticBus.fixed(1) := '0';  -- not temperature corrected result,field can be averaged
	  v.diagnosticBus.fixed(2) := '1';  -- only summing, can be big range, float, not averaged
	  v.diagnosticBus.fixed(3) := '1';  -- float representation of word 0, float, not averaged
	  v.diagnosticBus.fixed(4) := '1';  -- status, not a number, not averaged
	  
 -- Output sevirity
     if (detError.err = '1' commonConfig.enableCalib = '1' and ADCenabled(0) = '0') then
		  v.diagnosticBus.sevr(0) := "11";  -- 
		  v.diagnosticBus.sevr(1) := "11";  -- 
		  v.diagnosticBus.sevr(2) := "11";  -- 
		  v.diagnosticBus.sevr(3) := "11";  -- 
	 else
		  v.diagnosticBus.sevr(0) := "00";  -- 
		  v.diagnosticBus.sevr(1) := "00";  -- 
		  v.diagnosticBus.sevr(2) := "00";  -- 
		  v.diagnosticBus.sevr(3) := "00";  -- 
      end if;
	  v.diagnosticBus.sevr(4) := "00";  -- status, for internal subsystem use, always valid 
	  
	  v.diagnosticBus.timingMessage <= Bcm2DspRcrdArr(0).TimingMessageOut;
	  
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
