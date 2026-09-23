PROJECT_ROOT := $(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))
PDK_ROOT ?= $(HOME)/.ciel
PDK ?= ihp-sg13g2
RUN_TAG ?= darkriscv_$(shell date +%Y%m%d_%H%M%S)

.DEFAULT_GOAL := help
help:
	@echo "make doctor | sim | lint | flow | flow-nodrc | openroad | klayout"

doctor:
	@command -v librelane
	@command -v yosys
	@test -d "$(PDK_ROOT)/$(PDK)"
	@librelane --version

lint:
	yosys -p 'read_verilog -sv -Irtl rtl/darkriscv.v rtl/darkriscv_soc.sv; hierarchy -check -top darkriscv_soc; proc; check'

sim:
	iverilog -g2012 -Wall -Irtl -o sim/soc.vvp sim/tb_soc.sv rtl/darkriscv_soc.sv rtl/darkriscv.v
	vvp sim/soc.vvp

flow:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk --run-tag $(RUN_TAG) --save-views-to final librelane/config.yaml

flow-nodrc:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk --run-tag $(RUN_TAG) --save-views-to final librelane/config.yaml --skip KLayout.DRC --skip Magic.DRC

openroad:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk --last-run --flow OpenInOpenROAD librelane/config.yaml

klayout:
	librelane --pdk $(PDK) --pdk-root $(PDK_ROOT) --manual-pdk --last-run --flow OpenInKLayout librelane/config.yaml

.PHONY: help doctor lint sim flow flow-nodrc openroad klayout
