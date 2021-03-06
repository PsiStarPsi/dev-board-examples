# Load RUCKUS library
source -quiet $::env(RUCKUS_DIR)/vivado_proc.tcl

# Load the Core
loadRuckusTcl "$::DIR_PATH/core"
loadRuckusTcl "$::DIR_PATH/VivadoHls"

# Get the family type
set family [getFpgaFamily]

if { ${family} == "artix7" } {
   loadRuckusTcl "$::DIR_PATH/7Series"
}

if { ${family} == "kintex7" } {
   loadRuckusTcl "$::DIR_PATH/7Series"
}

if { ${family} == "virtex7" } {
   loadRuckusTcl "$::DIR_PATH/7Series"
}

if { ${family} == "zynq" } {
   loadRuckusTcl "$::DIR_PATH/7Series"
}

if { ${family} == "kintexu" } {
   loadRuckusTcl "$::DIR_PATH/UltraScale"
}

if { ${family} eq {kintexuplus} } {
   loadRuckusTcl "$::DIR_PATH/UltraScale"
}
