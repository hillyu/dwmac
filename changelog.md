# Changelog

**Features & Enhancements:**

*   **Master-Stack Layout Support:**
    *   Implemented the `master-stack` tiling layout (`h_master_stack` and `v_master_stack`).
    *   Added `move-node-to-master` command to move the focused window to the master area.
    *   Updated `layout` command to support switching to `master-stack`.
    *   Updated `layoutRecursive.swift` to handle rendering of the master-stack layout.
    *   Updated `TilingContainer` to include `masterStack` layout case and `mfact` property (default 0.5).

*   **`mfact` Command:**
    *   Introduced the `mfact` command to adjust the master area split ratio (similar to dwm/i3).
    *   Supports setting an absolute value (e.g., `mfact 0.6`) or relative adjustments (e.g., `mfact +0.05`, `mfact -0.05`).
    *   Added validation to ensure `mfact` stays within the 0.05 to 0.95 range.

*   **Command Improvements:**
    *   **Focus:** Verified master-stack focus behavior.
    *   **Resize:** Implemented fine-grained resize controls and consolidated logic.
    *   **Consistency:** Enforced consistent command naming for `dfs-next` and `dfs-prev`.

**Bug Fixes:**

*   **Config Overwrite:** Fixed a critical bug where `default-root-container-layout = 'master-stack'` specified in the config was being overwritten and ignored at startup in `initAppBundle.swift`.
*   **Argument Parsing:** Fixed an issue where negative numbers in `mfact` arguments were incorrectly treated as flags.

**Documentation:**

*   Added documentation for the new `mfact` command (`docs/dwmac-mfact.adoc`).
*   Added documentation for `move-node-to-master` command (`docs/dwmac-move-node-to-master.adoc`).
*   Updated `dwmac-layout.adoc` and `guide.adoc` to include the `master-stack` layout option.
*   Updated `default-config.toml` to list `master-stack` as a valid option for `default-root-container-layout`.

**Tests:**

*   Added unit tests for `MfactCommand`, `MoveNodeToMasterCommand`, and `LayoutCommand`.
*   Added `FocusCommandMasterStackTest` to verify focus navigation in master-stack layouts.
*   Added `DefaultLayoutTest` to verify the configuration of the default layout.

**Build & Maintenance:**

*   Updated `build-release.sh` (details not fully visible in summary, but likely related to build process adjustments).
*   Updated generated files (git hash, command help, subcommand descriptions).
*   Started rebranding efforts to "Dwmac" (referenced in commit `9f0c446c`).
