# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load Source Code
loadSource -dir "$::DIR_PATH/rtl/"

# Load submodules' code and constraints
loadRuckusTcl "$::DIR_PATH/../DspCoreLib/SysGenCore"
