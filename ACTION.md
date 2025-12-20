# Action - Cleanup Orphaned Artifacts

## 2025-12-20
- Created PLAN.md and DEFINE.md.
- Identified orphaned artifacts in `.build`, `.xcode-build`, and `.release`.
- Removed `.build`, `.xcode-build`, and `.release` directories.
- Verified that no "aerospace" named build artifacts remain.
- Confirmed the project builds successfully with `swift build`.
- Updated `docs/index.html` to redirect to `guide.html` instead of the project repository.
- Modified `build-docs.sh` to copy `guide.html` to `index.html` during the build process for a direct landing page.
- Updated `docs/config-examples/default-config.toml` to use `cmd-alt-ctrl` as the default modifier and `dfs-prev/next` for navigation, aligning with a "dwm-like" experience.
- **Architectural Simplification:** Flattened the window management model to a DWM-style Master-Stack layout.
    - Removed `TilingContainer` and recursive tree logic.
    - Removed `SplitCommand`.
    - Refactored `Workspace` to directly manage a list of windows.
    - Simplified `FocusCommand`, `MoveCommand`, `SwapCommand`, `ResizeCommand`, `MfactCommand`, and `LayoutCommand` to work with the flat model.
    - Rewrote `layoutRecursive` to implement a single-pass Master-Stack layout engine.
    - Updated state persistence (`FrozenWorld`) to support the new flat structure.
    - Verified build success.