current_design $::env(DESIGN_NAME)
set_units -time ns
create_clock -name core_clk -period 20.0 [get_pins clk_pad/p2c]
set_clock_uncertainty 0.25 [get_clocks core_clk]
set_clock_transition 0.15 [get_clocks core_clk]
set in_ports [get_ports {rst_n_PAD uart_rx_PAD gpio_in_PAD[*]}]
set out_ports [get_ports {uart_tx_PAD gpio_out_PAD[*] debug_PAD[*]}]
set_input_delay -min 0.0 -clock core_clk $in_ports
set_input_delay -max 2.0 -clock core_clk $in_ports
set_output_delay -min 0.0 -clock core_clk $out_ports
set_output_delay -max 4.0 -clock core_clk $out_ports
set_load 0.033442 $out_ports
set_false_path -from [get_ports rst_n_PAD]
