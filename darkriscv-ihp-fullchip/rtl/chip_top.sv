`default_nettype none
module chip_top (
`ifdef USE_POWER_PINS
    inout wire IOVDD, IOVSS, VDD, VSS,
`endif
    inout wire clk_PAD,
    inout wire rst_n_PAD,
    inout wire uart_rx_PAD,
    inout wire uart_tx_PAD,
    inout wire [3:0] gpio_in_PAD,
    inout wire [7:0] gpio_out_PAD,
    inout wire [3:0] debug_PAD
);
    wire clk, rst_n, uart_rx, uart_tx;
    wire [3:0] gpio_in, debug;
    wire [7:0] gpio_out;

`define PWR .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS),
    sg13g2_IOPadIn clk_pad (
`ifdef USE_POWER_PINS
        `PWR
`endif
        .p2c(clk), .pad(clk_PAD));
    sg13g2_IOPadIn rst_n_pad (
`ifdef USE_POWER_PINS
        `PWR
`endif
        .p2c(rst_n), .pad(rst_n_PAD));
    sg13g2_IOPadIn uart_rx_pad (
`ifdef USE_POWER_PINS
        `PWR
`endif
        .p2c(uart_rx), .pad(uart_rx_PAD));
    sg13g2_IOPadOut30mA uart_tx_pad (
`ifdef USE_POWER_PINS
        `PWR
`endif
        .c2p(uart_tx), .pad(uart_tx_PAD));
    generate
        for (genvar i=0; i<4; i++) begin : gpio_inputs
            sg13g2_IOPadIn pad (
`ifdef USE_POWER_PINS
                `PWR
`endif
                .p2c(gpio_in[i]), .pad(gpio_in_PAD[i]));
        end
        for (genvar i=0; i<8; i++) begin : gpio_outputs
            sg13g2_IOPadOut30mA pad (
`ifdef USE_POWER_PINS
                `PWR
`endif
                .c2p(gpio_out[i]), .pad(gpio_out_PAD[i]));
        end
        for (genvar i=0; i<4; i++) begin : debug_outputs
            sg13g2_IOPadOut30mA pad (
`ifdef USE_POWER_PINS
                `PWR
`endif
                .c2p(debug[i]), .pad(debug_PAD[i]));
        end
        for (genvar i=0; i<2; i++) begin : vdd_pads
                (* keep *)
            sg13g2_IOPadVdd pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
            );
        end
        for (genvar i=0; i<2; i++) begin : vss_pads
            (* keep *)
            sg13g2_IOPadVss pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
            );
        end
        for (genvar i=0; i<1; i++) begin : iovdd_pads
                (* keep *)
            sg13g2_IOPadIOVdd pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
            );
        end
        for (genvar i=0; i<1; i++) begin : iovss_pads
                (* keep *)
            sg13g2_IOPadIOVss pad (
`ifdef USE_POWER_PINS
                .iovdd(IOVDD), .iovss(IOVSS), .vdd(VDD), .vss(VSS)
`endif
            );
        end
    endgenerate
`undef PWR

    darkriscv_soc u_soc (.*);
endmodule
`default_nettype wire
