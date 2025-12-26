# Action Log

## 2025-12-21 - Lean Refactoring

## Sun 21 Dec 2025 11:02:17 HKT - Optimization & Cleanup
- Analyzed codebase and identified `adaptiveWeight` as dead code.
- Removed `adaptiveWeight` property and methods from `TreeNode` and subclasses.
- Refactored `ResizeCommand` to use `mfact` for Master-Stack layout resizing.
- Verified with unit tests and build.

# Action Log (2025-12-22)
## Refactoring "Tree" to "Node/Model"
- Started refactoring process.
- Renamed `Sources/AppBundle/tree` to `Sources/AppBundle/dwmodel`.
- Renamed `Sources/AppBundleTests/tree` to `Sources/AppBundleTests/dwmodel`.
- Renamed `TreeNode.swift` to `DwNode.swift`, and other related files.
- Performed global replacement of `TreeNode`, `NilTreeNode`, `NonLeafTreeNodeObject`, and `NonLeafTreeNodeKind`.
- Verified build and tests pass.

## Added "i3 style ordered with icons" Menu Bar Style
- Updated `TrayMenuModel.swift` to include `appBundleIds` in `WorkspaceViewModel`.
- Implemented `i3OrderedWithIcons` in `MenuBarLabel.swift`.
- Added `appIcon` helper to fetch icons via `NSWorkspace`.
- Added `AnyViewEx.swift` for `anyView` helper.
- Adjusted icon size and spacing for better visibility on Retina displays.
- Verified build and tests pass.
- Updated `changelog.md`.

## Added "Smart Floating Windows" Heuristics
- Added `safari`, `safariTechnologyPreview`, `systemSettings`, `systemPreferences` to `KnownBundleId.swift`.
- Fixed bug in `MacWindow.swift` where `isFloating` was not set for new windows.
- Reverted specific heuristics for Settings windows, relying on the generic "no fullscreen button" heuristic which now works due to the bug fix.
- Verified build and tests pass.
- Updated `changelog.md`.
