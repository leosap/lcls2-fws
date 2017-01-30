------------------------------------------------------------------------------
-- This file is part of 'LCLS2 BCM Firmware'.
-- It is subject to the license terms in the LICENSE.txt file found in the
-- top-level directory of this distribution and at:
--    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
-- No part of 'LCLS2 BCM Firmware', including this file,
-- may be copied, modified, propagated, or distributed except according to
-- the terms contained in the LICENSE.txt file.
------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

package Version is

constant FPGA_VERSION_C : std_logic_vector(31 downto 0) := x"00000018"; -- MAKE_VERSION

constant BUILD_STAMP_C : string := "AmcCarrierBcm: Vivado v2016.2 (x86_64) Built Tue Jan 10 17:26:51 PST 2017 by leosap";

end Version;

-------------------------------------------------------------------------------
-- Revision History:
--
-- 07/10/2015 (0x00000001): Initial Build
-- 02/04/2016 (0x00000002): Added ring buffers to Generic ADC/DAC AMC modules
-- 02/05/2016 (0x00000003): Modified AmcGenericAdcDacCtrl registers
-- 02/05/2016 (0x00000004): Fixed bug in AxiLiteRingBuffer Length register
-- 02/19/2016 (0x00000005): Added your synchronous external trigger suppor, added VCO DAC firmware driver , LLRF style DAC sequencer
-- 02/26/2016 (0x00000006): Fix Addressing from absolute to relative for DAC sequencer
-- 02/26/2016 (0x00000007): Fix error in Sync Trig SM (Larry)^M
-- 03/04/2016 (0x00000008): To pick the latest updates
-- 03/09/2016 (0x00000009): To add trigger selection logic for future use in different sequencing tasks
-- 03/31/2016 (0x0000000A): Unused (internal testing )
-- 03/31/2016 (0x0000000B): First working in new 7 slot crate with new IP addressing mechanism
-- 03/31/2016 (0x0000000C): Using Timing message latching update in timing core and initial data processing
-- 04/11/2016 (0x0000000D): Update all cores, add timing clk as ADC clock, plus initial BSA data generation
-- 06/20/2016 (0x00000012): To test BP communication for BLEN enables BP communication
-- 08/04/2016 (0x00000013): To add DSP core processing 
-- 08/04/2016 (0x00000014): Switch to tagged version
-- 08/19/2016 (0x00000015): Switch to head to try new features.
-- 09/21/2016 (0x00000016): Test one shot for DaqMuxV2 hwtrig interface
-- 11/16/2016 (0x00000017): Update to the latest interfaces
-- 01/10/2017 (0x00000018): Added trigger rate counter
-------------------------------------------------------------------------------

