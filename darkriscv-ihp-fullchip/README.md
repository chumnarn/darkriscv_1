# DarkRISCV Full-Chip Implementation with LibreLane 3.x and IHP SG13G2

This repository is a ready-to-run ASIC adaptation of
[chumnarn/darkriscv_1](https://github.com/chumnarn/darkriscv_1), based on the
[IHP LibreLane full-chip template](https://github.com/IHP-GmbH/ihp-sg13g2-librelane-template).
It targets the LibreLane `Chip` flow, uses `config.yaml`, instantiates IHP IO
pads and bond pads, and provides a minimal bootable DarkRISCV SoC.

## 1. Scope and architecture

The upstream `darksocv.v` is intentionally not used as the ASIC top. It contains
FPGA-oriented clock, inferred BRAM, and board-dependent compile-time features.
The ASIC boundary is instead:

`chip_top` (IHP pads) → `darkriscv_soc` (ROM/RAM/GPIO) → `darkriscv` (CPU).

The delivered baseline has:

- DarkRISCV RV32I CPU, three-stage configuration, reset vector `0x00000000`;
- 1 KiB combinational boot-ROM address window at `0x00000000`;
- 256-byte byte-writeable data RAM at `0x10000000`;
- GPIO output register at `0x40000000`;
- status/UART input register at `0x40000004`;
- 50 MHz target clock (`CLOCK_PERIOD: 20.0` ns);
- 26 IHP SG13G2 IO/power pads, four corner cells inserted by Chip flow;
- 1600 µm × 1600 µm die and 870 µm × 870 µm core.

The tiny default ROM increments `gpio_out` forever. This proves reset, fetch,
decode, execute, store, address decode, and pad output without relying on SRAM
initialization. The small standard-cell RAM is deliberate: a foundry SRAM is not
a ROM and cannot contain firmware at power-up without a boot-loading mechanism.

## 2. Directory map

| Path | Purpose |
| --- | --- |
| `rtl/darkriscv.v` | pinned upstream CPU source |
| `rtl/config.vh` | ASIC-safe DarkRISCV compile configuration |
| `rtl/darkriscv_soc.sv` | boot ROM, RAM, MMIO, CPU integration |
| `rtl/chip_top.sv` | IHP signal and supply pad ring wrapper |
| `librelane/config.yaml` | LibreLane 3.x Chip-flow configuration |
| `librelane/chip_top.sdc` | clock and IO timing constraints |
| `librelane/pdn_cfg.tcl` | standard-cell power grid |
| `sim/tb_soc.sv` | self-checking RTL smoke test |
| `tools/bin2rom.py` | little-endian binary-to-ROM-case converter |

## 3. Prerequisites

Recommended host: Ubuntu 24.04 or the Nix environment from the IHP template.
Required commands are `librelane`, `yosys`, `iverilog`, `vvp`, and `ciel`.

Install/activate LibreLane 3.x, then enable the IHP PDK. If the installed PDK is
already under `~/.ciel/ihp-sg13g2`, no download is needed. Confirm:

```bash
librelane --version
ciel list --pdk-family ihp-sg13g2
make doctor PDK_ROOT="$HOME/.ciel"
```

Some Ciel installations create a versioned layout rather than the direct
`$PDK_ROOT/ihp-sg13g2` link. Point `PDK_ROOT` to the directory that directly
contains the enabled `ihp-sg13g2` PDK.

## 4. Obtain and verify the project

```bash
cd darkriscv-ihp-fullchip
python3 -m py_compile tools/bin2rom.py
make lint
make sim
```

Expected simulation ending:

```text
PASS gpio_out=...
```

`make lint` elaborates `darkriscv_soc`, converts processes, and runs Yosys
structural checks. Run it before the full flow whenever RTL changes.

## 5. Run LibreLane

Full signoff-oriented run:

```bash
make flow PDK_ROOT="$HOME/.ciel"
```

Fast bring-up run that skips only KLayout and Magic DRC:

```bash
make flow-nodrc PDK_ROOT="$HOME/.ciel"
```

The `--skip` spelling is compatible with LibreLane 3.x. Do not use legacy
OpenLane variables such as `FP_PDN_CFG`, `RUN_KLAYOUT_DRC`, or JSON config.
Do not use `--override` or `--interactive` with LibreLane 3.0.9.

Open the most recent run:

```bash
make openroad PDK_ROOT="$HOME/.ciel"
make klayout  PDK_ROOT="$HOME/.ciel"
```

Final views are copied to `final/`; step logs and intermediate states remain in
`librelane/runs/<tag>/`.

## 6. Flow checkpoints

1. **Yosys synthesis** — confirm top is `chip_top`, no unmapped DarkRISCV cells,
   and every listed pad instance exists.
2. **Floorplan/pad ring** — inspect all four pad sides and corner cells. Pad
   names in YAML are escaped because generated-instance names contain brackets.
3. **Placement** — target density is 35%. Reduce it if global placement reports
   persistent overflow; do not hide real routing failure with
   `GRT_ALLOW_CONGESTION` in a tapeout candidate.
4. **CTS** — clock starts at `clk_pad/p2c`, not the package-level pad port.
5. **PDN** — verify VDD/VSS core rings connect to all four pairs of core supply
   pads and that Metal1/2/3 rails are continuous.
6. **Routing** — require zero detailed-routing violations for release.
7. **Signoff** — require LVS clean, antenna clean, DRC clean, and non-negative
   setup/hold slack at every configured corner.

Useful report search:

```bash
rg -n "ERROR|VIOLATED|unmapped|floating|disconnected|slack" librelane/runs
find final -maxdepth 2 -type f | sort
```

## 7. Timing intent

The SDC constrains a 50 MHz pad-to-core clock, 0.25 ns uncertainty, 0.15 ns
transition, 2 ns maximum input delay, 4 ns maximum output delay, and 0.033442 pF
output load. Reset is asynchronous at the external interface and false-pathed.
If board timing differs, edit the SDC and `CLOCK_PERIOD` together.

## 8. Firmware replacement

Build a flat little-endian RV32I binary linked at address zero. Convert it:

```bash
python3 tools/bin2rom.py firmware.bin -o rtl/boot_rom_case.vh
```

Then replace the explicit entries inside `boot_word()` with:

```verilog
`include "boot_rom_case.vh"
```

Keep the image within 256 words unless the address decode and function input
width are enlarged. Re-run `make lint` and `make sim`. For production firmware,
use a mask ROM, SPI/QSPI boot, or a verified ROM macro rather than a large
standard-cell case statement.

## 9. Address map and software rules

| Address | Access | Function |
| --- | --- | --- |
| `0x0000_0000–0x0000_03ff` | RX | boot ROM |
| `0x1000_0000–0x1000_00ff` | RW | 64 × 32-bit data RAM |
| `0x4000_0000` | RW | GPIO output register; low 8 bits drive pads |
| `0x4000_0004` | R/W | inputs on read; UART staging byte on write |

DarkRISCV produces byte enables; the SoC honors them for RAM and GPIO writes.
Unmapped instruction or data accesses assert the corresponding bus-error input.

## 10. Known limitations and production upgrades

- `uart_tx` currently exposes bit 0 of a staging register; it is not a baud-rate
  UART. Integrate and verify `darkuart.v` before calling it a serial interface.
- The baseline has no interrupt controller, cache, debug module, scan, MBIST,
  ESD signoff model, package model, or power intent.
- The behavioral RAM resets every word, which is convenient for deterministic
  simulation but expensive in standard cells. Replace it with a wrapper around
  `RM_IHPSG13_1P_1024x32_c2_bm_bist` for a density-oriented implementation.
- Before adding that macro, confirm its exact byte-mask polarity and read
  latency from the enabled PDK model, add `MACROS`, instance placement,
  `PDN_MACRO_CONNECTIONS`, and macro PDN straps. Never guess macro pins.
- `GRT_ALLOW_CONGESTION: true` is for early convergence only. A final run must
  demonstrate clean detailed routing.

## 11. Failure diagnosis

| Symptom | Likely cause | Corrective action |
| --- | --- | --- |
| pad instance not found | YAML name does not match elaborated generate name | inspect synthesized hierarchy and retain bracket escaping |
| clock pin not found | using `clk_PAD` as internal clock object | keep `CLOCK_PORT: clk_PAD`, `CLOCK_NET: clk_pad/p2c` |
| VDD/GND configuration error | only one supply list was set | define both `VDD_NETS` and `GND_NETS` |
| `met5` not found | copied routing/PDN settings from another PDK | use SG13G2 layer names from this project |
| RSZ-0060 max buffers | impossible timing/fanout or excessive reset load | inspect fanout and relax target only with evidence |
| LVS disconnected pads | power pins omitted or inconsistent define | retain `USE_POWER_PINS` and the four explicit supply nets |
| simulation GPIO stays zero | boot encoding, reset, or bus handshake changed | inspect `iaddr`, `idata`, `dwr`, `daddr`, `datao`, `gpio_reg` |

## 12. Release checklist

- RTL smoke test passes and no X values reach architectural buses after reset.
- Synthesis reports no latch, undriven critical net, unresolved module, or
  unexpected inferred memory.
- Pad order is reviewed against the intended package/bond diagram.
- Clock, reset, IO delays, loads, and all timing exceptions are reviewed.
- Setup and hold pass at all PDK corners used by the project.
- PDN connectivity and IR-drop reports are reviewed.
- Detailed routing, antenna, KLayout/Magic DRC, LVS, and GDS XOR are clean.
- Final GDS, LEF, netlist, SDF, SPEF, reports, config, PDK revision, LibreLane
  version, and source commit are archived together.

## 13. Provenance

The CPU file was taken from `chumnarn/darkriscv_1` branch `master`, inspected at
commit `974034aa8079039a36b89c14dcdfed575de183b7`. The full-chip structure,
bond-pad data, pad types, and starting configuration were derived from the IHP
template branch `main`, inspected at commit
`0418301723d86133de686ef743cfd668bb3d11d4`. Preserve the upstream DarkRISCV
license notice in `rtl/darkriscv.v` and the IHP template/bond-pad licenses.

## 14. Revision history

- **2026-09-22:** Added the required `RLEN` derived macro to ASIC `config.vh`.
  The default RV32I build uses 32 registers; an RV32E build uses 16.
- **2026-09-22 (rev. 2):** Removed `USE_POWER_PINS` from `VERILOG_DEFINES`.
  IHP IO supply terminals are Liberty `pg_pin` objects and are not part of the
  functional module interface created by Yosys. Keeping the define caused
  hierarchy failures such as `sg13g2_IOPadIOVss ... no port named vss`.
  Physical supply connectivity remains the responsibility of the Chip-flow
  pad-ring/global-connect/PDN stages.
- **2026-09-23 (rev. 3):** Added `(* keep *)` to all six supply-pad instances.
  With explicit power ports disabled, these cells otherwise have no functional
  ports and Yosys removes them. The preserved instances are required by the
  `PAD_*` lists and the physical power-connect/PDN stages.
- **2026-09-23 (rev. 4):** Replaced the preliminary hard-coded PDN script with
  the LibreLane 3.x/IHP-template API. It now sources the global-connection
  helper, calls zero-argument `set_global_connections`, uses the singular
  `-voltage_domain` option, derives layers and dimensions from LibreLane's PDN
  environment, and omits the template's unused SRAM grids.
