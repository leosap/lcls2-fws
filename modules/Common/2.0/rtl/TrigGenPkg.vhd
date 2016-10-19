-------------------------------------------------------------------------------
-- Title      :
-------------------------------------------------------------------------------
-- File       : TrigGenPkg.vhd
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

package TrigGenPkg is


  constant STD_TRIG_WIDTH : integer := 8; -- assuming the most delay tacken by programmable delay at timing

  type TrigSpecType is record

      SelectSource   : slv(1 downto 0);
      SelectField    : slv(2 downto 0);
      fixedRate      : slv(9 downto 0);
      beamRequest    : slv(31 downto 0);
      trigDelay      : slv(STD_TRIG_WIDTH-1 downto 0);
      trigStretch    : slv(STD_TRIG_WIDTH-1 downto 0);
      outPolarity    : sl;
      SoftTrigP      : sl;
  end record TrigSpecType;

   constant TRIGSPEC_INIT_C : TrigSpecType := (
      SelectSource   => (others=>'0'),
      SelectField   => (others=>'0'),
      fixedRate   => (others=>'0'),
      beamRequest     => (others=>'0'),
      trigDelay       => (others=>'0'),
      trigStretch     => (others=>'0'),
      outPolarity     => '0',
      SoftTrigP       => '0');

  type TrigSpecMrType is record

      SelectSource   : slv(1 downto 0);
      eventCodes     : slv(255 downto 0);
      trigDelay      : slv(STD_TRIG_WIDTH-1 downto 0);
      trigStretch    : slv(STD_TRIG_WIDTH-1 downto 0);
      outPolarity    : sl;
      SoftTrigP      : sl;
  end record TrigSpecMrType;

   constant TRIGSPEC_MR_INIT_C : TrigSpecMrType := (
      SelectSource   => (others=>'0'),
      eventCodes     => (others=>'0'),
      trigDelay       => (others=>'0'),
      trigStretch     => (others=>'0'),
      outPolarity     => '0',
      SoftTrigP       => '0');

  type TriggerConfigType is record
    enabled  : sl;
    polarity : sl;
    delay    : slv(STD_TRIG_WIDTH-1 downto 0);
    width    : slv(STD_TRIG_WIDTH-1 downto 0);
    channel  : slv( 3 downto 0);
  end record;

end package TrigGenPkg;

package body TrigGenPkg is

end package body TrigGenPkg;
