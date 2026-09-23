`ifndef DARKRISCV_ASIC_CONFIG_VH
`define DARKRISCV_ASIC_CONFIG_VH
`define __3STAGE__
`define __RESETPC__ 32'h0000_0000

// darkriscv.v declares REGS[0:RLEN-1] unconditionally.
// RV32I has 32 architectural registers; RV32E has 16.
`ifdef __RV32E__
  `define RLEN 16
`else
  `define RLEN 32
`endif
`endif
