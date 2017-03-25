-------------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : AdcIntProcPkg.vhd
-- Author     : Leonid Sapozhnikov  <leosap@slac.stanford.edu>
-- Company    : SLAC National Accelerator Laboratory
-- Created    : 2016-03-09
-- Last update: 2014-03-09
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description:
-------------------------------------------------------------------------------
-- This file is part of 'SLAC Firmware Standard Library'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'SLAC Firmware Standard Library', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.StdRtlPkg.all;
use work.Jesd204bPkg.all;
use work.AmcCarrierPkg.all;
use work.TimingPkg.all;


package AdcIntProcPkg is

   constant NUM_BCM_APP_C : natural := 2;
   constant DIAGNOSTIC_OUTPUTS_G  : integer := 14;
   constant DATA_FRAME_LEN_C  : integer := 32 * DIAGNOSTIC_OUTPUTS_G;
   constant BCM_BERGOZ_C     : slv(1 downto 0) := "00";
   constant BCM_FARADAYCUP_C : slv(1 downto 0) := "01";
   constant BCM_APP_TYPE_C : Slv2Array(NUM_BCM_APP_C-1 downto 0) := (BCM_BERGOZ_C, BCM_FARADAYCUP_C);
   constant HDR_SIZE_C        : positive := 1;
   constant DATA_SIZE_C       : positive := 6;

  type sampleDataArray3Array is array (natural range <>) of sampleDataArray(2 downto 0);
  type sampleDataArray5Array is array (natural range <>) of sampleDataArray(5 downto 0);


  type ConfigSpaceLclType is record
      NumberSamples   : Slv8Array(2 downto 0);
      TrigDelay       : Slv8Array(2 downto 0);
      DacSrs          : slv(1 downto 0);
  end record ConfigSpaceLclType;

   constant CONF_SPACE_LCL_C : ConfigSpaceLclType := (
      NumberSamples   => ((others=>'0'),(others=>'0'),(others=>'0')),
      TrigDelay       => ((others=>'0'),(others=>'0'),(others=>'0')),
      DacSrs          => (others=>'0'));

  type ConfigSpaceType is record
      SimAdcSumData   : Slv32Array(2 downto 0);
      SimTmit         : slv(31 downto 0);
      TestMode        : slv(2 downto 0);

  end record ConfigSpaceType;

   constant CONF_SPACE_C : ConfigSpaceType := (
      SimAdcSumData   => ((others=>'0'),(others=>'0'),(others=>'0')),
      SimTmit         => (others=>'0'),
      TestMode        => (others=>'0'));

 type ConfigSpaceArrayType is array (natural range <>) of ConfigSpaceType;

  type Bcm2DspRcrdType is record
      TimingValid     : sl;
      AdcValid       : sl;
      AdcSumDataOut   : Slv32Array(2 downto 0);
      TimingMessageOut : TimingMessageType;
   end record;

  type Bcm2DspRcrdMRType is record
      AdcValid       : sl;
      AdcSumDataOut   : Slv32Array(2 downto 0);
      TimingStreamOut : TimingStreamType;
   end record;


     constant BCM_2_DSP_RCRD_INIT_C : Bcm2DspRcrdType := (
	  TimingValid    => '0';
      AdcValid       => '0',
      AdcSumDataOut   => (others => (others => '1')),
      TimingMessageOut         => TIMING_MESSAGE_INIT_C );

     constant BCM_2_DSP_RCRD_INIT_MR_C : Bcm2DspRcrdMRType := (
      AdcValid       => '0',
      AdcSumDataOut   => (others => (others => '1')),
      TimingStreamOut         => TIMING_STREAM_INIT_C );

  type Bcm2DspRcrdArrType is array (natural range<>) of Bcm2DspRcrdType;
  type Bcm2DspRcrdMRArrType is array (natural range<>) of Bcm2DspRcrdMRType;

     type tmitMessageType is record
      strobe : sl;
      header : Slv32Array(HDR_SIZE_C-1 downto 0);
      timeStamp  : slv(63 downto 0);
      data : Slv32Array(DATA_SIZE_C-1 downto 0);
   end record tmitMessageType;
   constant TMITINIT_C : tmitMessageType := (
      strobe => '0';
      header => (others => (others => '0')),
      timeStamp  => (others => '0'),
      data => (others => (others => '0')));

   type tmitMessageArrType is array (natural range <>) of tmitMessageType;

   type commonConfigType is record
      enableCalib : sl;
   end record commonConfigType;
   constant COMMONCONFIG_C : commonConfigType := (
      enableCalib => '0');


end package AdcIntProcPkg;

package body AdcIntProcPkg is


   -------------------------------------------------------------------------------------------------
   -- Convert a data message record into a big long SLV
   -------------------------------------------------------------------------------------------------
   function toSlv (DataBus : Slv32Array(DIAGNOSTIC_OUTPUTS_G-1 downto 0)) return slv
   is
      variable vector : slv(DATA_FRAME_LEN_C-1 downto 0) := (others => '0');
      variable i      : integer                               := 0;
   begin
      for j in 0 to (DIAGNOSTIC_OUTPUTS_G-1) loop
         assignSlv(i, vector, DataBus(j));
      end loop;
      return vector;
   end function;


   -------------------------------------------------------------------------------------------------
   -- Convert an SLV into a data record
   -------------------------------------------------------------------------------------------------
   function toDataBus (vector : slv) return Slv32Array(DIAGNOSTIC_OUTPUTS_G-1 downto 0)
   is
      variable DataBus : Slv32Array(DIAGNOSTIC_OUTPUTS_G-1 downto 0);
      variable i       : integer := 0;
   begin
      for j in 0 to (DIAGNOSTIC_OUTPUTS_G-1) loop
         assignRecord(i, vector, DataBus(j));
      end loop;
      return DataBus;
   end function;


end package body AdcIntProcPkg;
