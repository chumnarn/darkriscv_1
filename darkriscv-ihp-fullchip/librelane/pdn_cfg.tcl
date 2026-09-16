set_global_connections \
  -net VDD -inst_pattern {.*} -pin_pattern {^VDD$} -power
set_global_connections \
  -net VSS -inst_pattern {.*} -pin_pattern {^VSS$} -ground

set_voltage_domain -name CORE -power VDD -ground VSS
define_pdn_grid -name stdcell_grid -voltage_domains CORE -starts_with POWER
add_pdn_stripe -grid stdcell_grid -layer Metal1 -width 0.44 -followpins
add_pdn_stripe -grid stdcell_grid -layer Metal2 -width 3.0 -pitch 40.0 -offset 20.0
add_pdn_stripe -grid stdcell_grid -layer Metal3 -width 3.0 -pitch 40.0 -offset 20.0
add_pdn_connect -grid stdcell_grid -layers {Metal1 Metal2}
add_pdn_connect -grid stdcell_grid -layers {Metal2 Metal3}
