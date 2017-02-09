##############################################################################
## This file is part of 'LCLS2 AMC Carrier Firmware'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LCLS2 AMC Carrier Firmware', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################
#######################
## Application Ports ##
#######################

set_property PACKAGE_PIN B6 [get_ports {rtmPgpTxP}]
set_property PACKAGE_PIN B5 [get_ports {rtmPgpTxN}]
set_property PACKAGE_PIN A4 [get_ports {rtmPgpRxP}]
set_property PACKAGE_PIN A3 [get_ports {rtmPgpRxN}]

set_property PACKAGE_PIN V6 [get_ports {rtmPgpClkP}]
set_property PACKAGE_PIN V5 [get_ports {rtmPgpClkN}]

####################################
## Application Timing Constraints ##
####################################

create_clock -period 5.385 -name jesdRefClk0 [get_ports {jesdClkP[0]}]
create_clock -period 5.385 -name jesdRefClk1 [get_ports {jesdClkP[1]}]

create_clock -period 6.400 -name pgpRefClk   [get_ports {rtmPgpClkP}]

create_generated_clock -name jesd0_185MHz   [get_pins {U_App/U_DualAmc/GEN_AMC[0].U_AMC/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
#create_generated_clock -name jesd0_371MHz   [get_pins {U_App/U_DualAmc/GEN_AMC[0].U_AMC/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]
create_generated_clock -name jesd1_185MHz   [get_pins {U_App/U_DualAmc/GEN_AMC[1].U_AMC/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT0}]
#create_generated_clock -name jesd1_371MHz   [get_pins {U_App/U_DualAmc/GEN_AMC[1].U_AMC/U_ClockManager/MmcmGen.U_Mmcm/CLKOUT1}]

set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesdRefClk0}]
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesdRefClk1}]
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesd0_185MHz}]
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {jesd1_185MHz}]
set_clock_groups -asynchronous -group [get_clocks {axilClk}] -group [get_clocks {pgpRefClk}]

set_clock_groups -asynchronous -group [get_clocks {ddrIntClk0}] -group [get_clocks {pgpRefClk}]
set_clock_groups -asynchronous -group [get_clocks {ddrIntClk0}] -group [get_clocks {jesd0_185MHz}]
set_clock_groups -asynchronous -group [get_clocks {ddrIntClk0}] -group [get_clocks {jesd1_185MHz}]
## add lines due to changed domains
set_clock_groups -asynchronous -group [get_clocks {recTimingClk}] -group [get_clocks {jesd0_185MHz}]
set_clock_groups -asynchronous -group [get_clocks {recTimingClk}] -group [get_clocks {jesd1_185MHz}]
set_clock_groups -asynchronous -group [get_clocks {jesd0_185MHz}] -group [get_clocks {jesd1_185MHz}]
set_clock_groups -asynchronous -group [get_clocks {rxoutclk_out[0]}] -group [get_clocks {jesd0_185MHz}]
set_clock_groups -asynchronous -group [get_clocks {rxoutclk_out[0]}] -group [get_clocks {jesd1_185MHz}]


##########################
## Misc. Configurations ##
##########################
