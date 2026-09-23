# SPDX-FileCopyrightText: 2025 LibreLane Contributors
# SPDX-License-Identifier: Apache-2.0
# Adapted from the IHP SG13 LibreLane full-chip template.

source $::env(SCRIPTS_DIR)/openroad/common/io.tcl
source $::env(SCRIPTS_DIR)/openroad/common/set_global_connections.tcl
set_global_connections

set secondary []
foreach vdd $::env(VDD_NETS) gnd $::env(GND_NETS) {
    if { $vdd != $::env(VDD_NET) } {
        lappend secondary $vdd
        set db_net [[ord::get_db_block] findNet $vdd]
        if { $db_net == "NULL" } {
            set net [odb::dbNet_create [ord::get_db_block] $vdd]
            $net setSpecial
            $net setSigType "POWER"
        }
    }
    if { $gnd != $::env(GND_NET) } {
        lappend secondary $gnd
        set db_net [[ord::get_db_block] findNet $gnd]
        if { $db_net == "NULL" } {
            set net [odb::dbNet_create [ord::get_db_block] $gnd]
            $net setSpecial
            $net setSigType "GROUND"
        }
    }
}

set_voltage_domain -name CORE \
    -power $::env(VDD_NET) -ground $::env(GND_NET) \
    -secondary_power $secondary

if { $::env(PDN_MULTILAYER) != 1 } {
    throw APPLICATION "This full-chip PDN requires PDN_MULTILAYER=true."
}

set grid_args [list]
if { $::env(PDN_ENABLE_PINS) } {
    lappend grid_args -pins \
        "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"
}
define_pdn_grid -name stdcell_grid -starts_with POWER \
    -voltage_domain CORE {*}$grid_args

set vertical_args [list]
append_if_equals vertical_args PDN_EXTEND_TO "core_ring" -extend_to_core_ring
append_if_equals vertical_args PDN_EXTEND_TO "boundary" -extend_to_boundary
add_pdn_stripe -grid stdcell_grid \
    -layer $::env(PDN_VERTICAL_LAYER) \
    -width $::env(PDN_VWIDTH) -pitch $::env(PDN_VPITCH) \
    -offset $::env(PDN_VOFFSET) -spacing $::env(PDN_VSPACING) \
    -starts_with POWER {*}$vertical_args

set horizontal_args [list]
append_if_equals horizontal_args PDN_EXTEND_TO "core_ring" -extend_to_core_ring
append_if_equals horizontal_args PDN_EXTEND_TO "boundary" -extend_to_boundary
add_pdn_stripe -grid stdcell_grid \
    -layer $::env(PDN_HORIZONTAL_LAYER) \
    -width $::env(PDN_HWIDTH) -pitch $::env(PDN_HPITCH) \
    -offset $::env(PDN_HOFFSET) -spacing $::env(PDN_HSPACING) \
    -starts_with POWER {*}$horizontal_args

add_pdn_connect -grid stdcell_grid \
    -layers "$::env(PDN_VERTICAL_LAYER) $::env(PDN_HORIZONTAL_LAYER)"

if { $::env(PDN_ENABLE_RAILS) == 1 } {
    add_pdn_stripe -grid stdcell_grid \
        -layer $::env(PDN_RAIL_LAYER) \
        -width $::env(PDN_RAIL_WIDTH) -followpins
    add_pdn_connect -grid stdcell_grid \
        -layers "$::env(PDN_RAIL_LAYER) $::env(PDN_VERTICAL_LAYER)"
}

if { $::env(PDN_CORE_RING) == 1 } {
    set ring_args [list]
    append_if_flag ring_args PDN_CORE_RING_ALLOW_OUT_OF_DIE -allow_out_of_die
    append_if_flag ring_args PDN_CORE_RING_CONNECT_TO_PADS -connect_to_pads
    append_if_equals ring_args PDN_EXTEND_TO "boundary" -extend_to_boundary

    set ring_vlayer $::env(PDN_VERTICAL_LAYER)
    set ring_hlayer $::env(PDN_HORIZONTAL_LAYER)
    if { [info exists ::env(PDN_CORE_VERTICAL_LAYER)] } {
        set ring_vlayer $::env(PDN_CORE_VERTICAL_LAYER)
    }
    if { [info exists ::env(PDN_CORE_HORIZONTAL_LAYER)] } {
        set ring_hlayer $::env(PDN_CORE_HORIZONTAL_LAYER)
    }

    add_pdn_ring -grid stdcell_grid \
        -layers "$ring_vlayer $ring_hlayer" \
        -widths "$::env(PDN_CORE_RING_VWIDTH) $::env(PDN_CORE_RING_HWIDTH)" \
        -spacings "$::env(PDN_CORE_RING_VSPACING) $::env(PDN_CORE_RING_HSPACING)" \
        -core_offset "$::env(PDN_CORE_RING_VOFFSET) $::env(PDN_CORE_RING_HOFFSET)" \
        {*}$ring_args

    if { $ring_vlayer != $::env(PDN_VERTICAL_LAYER) } {
        add_pdn_connect -grid stdcell_grid \
            -layers "$ring_vlayer $::env(PDN_HORIZONTAL_LAYER)"
    }
    if { $ring_hlayer != $::env(PDN_HORIZONTAL_LAYER) } {
        add_pdn_connect -grid stdcell_grid \
            -layers "$ring_hlayer $::env(PDN_VERTICAL_LAYER)"
    }
    if { $ring_vlayer != $::env(PDN_VERTICAL_LAYER) && \
         $ring_hlayer != $::env(PDN_HORIZONTAL_LAYER) } {
        add_pdn_connect -grid stdcell_grid \
            -layers "$ring_vlayer $ring_hlayer"
    }
}
