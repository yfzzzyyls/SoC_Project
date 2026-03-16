# AGENTS.md

Project: ECE9433-SoC-Design-Project (pose estimation accelerator SoC)

## Purpose
- Keep the SoC flow reproducible (DC synthesis -> Innovus PNR -> DRC/LVS connectivity).
- Provide one clear, current known-good status for newcomers.

## Key docs
- README.md

## Build / Run / Test
- Fetch third-party core:
  `./setup.sh`
- Synthesis (SRAM macro enabled in `rtl/sram.sv` under `SYNTHESIS`):
  `/eda/synopsys/syn/W-2024.09-SP5-5/bin/dc_shell -f syn_complete_with_tech.tcl 2>&1 | tee synthesis_complete.log`
  Outputs: `mapped_with_tech/soc_top.v`, `mapped_with_tech/soc_top.sdc`, `mapped_with_tech/soc_top.ddc`
- Innovus PNR with SRAM gate checks (recommended flow):
  `/eda/cadence/INNOVUS211/bin/innovus -no_gui -overwrite -files tcl_scripts/complete_flow_with_qrc_with_sram.tcl 2>&1 | tee with_sram_complete_flow.log`
  Outputs:
  - DRC loop reports: `pd/innovus/drc_with_sram_iter*.rpt`
  - Connectivity: `pd/innovus/lvs_connectivity_regular.rpt`, `pd/innovus/lvs_connectivity_special.rpt`
  - Antenna: `pd/innovus/lvs_process_antenna.rpt`
  - Final checkpoint: `pd/innovus/with_sram_final.enc`
- Optional recheck from final checkpoint:
  - DRC: `pd/innovus/drc_recheck_20260315.rpt`
  - Connectivity: `pd/innovus/lvs_connectivity_regular_recheck_20260315.rpt`, `pd/innovus/lvs_connectivity_special_recheck_20260315.rpt`
  - Antenna: `pd/innovus/lvs_process_antenna_recheck_20260315.rpt`

## Current Known-Good Status (Mar 15, 2026, America/New_York)
- Synthesis completed and wrote mapped netlist (`mapped_with_tech/soc_top.v`).
- SRAM macro preservation checks passed:
  - Instance: `u_sram/u_sram_macro`
  - Reference: `TS1N16ADFPCLLLVTA512X45M4SWSHOD`
- Innovus with-SRAM flow result: PASS.
  - DRC ECO loop: `iter0=9`, `iter1=5`, `iter2=0`
  - `verifyConnectivity` regular: `0` problems
  - `verifyConnectivity` special (`-noAntenna`): `0` problems
  - `verifyProcessAntenna`: `0` violations
- Recheck from final checkpoint also clean:
  - DRC: `0` (`No DRC violations were found`)
  - Connectivity regular: `0`
  - Connectivity special: `0`
  - Antenna: `0` (`No Violations Found`)

## Notes
- IO pin assignment warnings during `verifyConnectivity` for `clk`, `rst_n`, and `trap` are expected unless pins are assigned.
- This is Innovus in-design connectivity/antenna validation, not full signoff LVS/DRC with PVS/Calibre.

## Repo conventions
- RTL in `rtl/`, scripts in `tcl_scripts/`, Innovus checkpoints/reports in `pd/innovus/`.
- Keep large logs/generated outputs out of git; commit RTL/scripts/docs.
