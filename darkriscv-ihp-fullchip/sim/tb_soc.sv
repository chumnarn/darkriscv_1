`timescale 1ns/1ps
module tb_soc;
  reg clk=0, rst_n=0, uart_rx=1; reg [3:0] gpio_in=0;
  wire uart_tx; wire [7:0] gpio_out; wire [3:0] debug;
  always #10 clk=~clk;
  darkriscv_soc dut(.*);
  initial begin
    $dumpfile("sim/darkriscv_soc.vcd"); $dumpvars(0,tb_soc);
    repeat(5) @(posedge clk); rst_n<=1;
    repeat(80) @(posedge clk);
    if (gpio_out == 0) $fatal(1,"GPIO did not change");
    $display("PASS gpio_out=%02x",gpio_out); $finish;
  end
endmodule
