# TODO

## Critical

- [ ] Remove `.plan.md` from root directory (gitignored but exists)
- [ ] Add MIT `LICENSE` file to match README claims
- [ ] Fix CONTRIBUTING.md URL: `.dropfiles/dropfiles` → `nicholaswmin/dropfiles`
- [ ] Remove non-existent brew install instructions from README
- [ ] Remove CLI Usage section (shortcuts don't exist yet)

## Code Quality

- [ ] Standardize import order across all Swift files
- [ ] Extract UserDefaults keys to Constants enum:
  ```swift
  static let watchedFolderKey = "watchedFolderBookmark"
  static let autoSyncKey = "autoSyncEnabled" 
  static let syncIntervalKey = "syncInterval"
  ```
- [ ] Fix Bundle ID fallback: `"com.dropfiles"` → `"com.nicholaswmin.dropfiles"`
- [ ] Make `SyncError.errorDescription` return `String` (not optional)
- [ ] Replace force unwraps with safe alternatives where possible

## Configuration

- [ ] Fix Package.swift naming: product `dropfiles` vs target `Dropfiles`
- [ ] Add Swift package caching to GitHub Actions CI

## Polish

- [ ] Add accessibility labels to UI elements  
- [ ] Standardize logging categories and levels
- [ ] Consistent line length (<80 chars where possible)

## Documentation

- [ ] Clarify app launch instructions in README
- [ ] Add note about macOS permissions needed (iCloud, file access)
- [ ] Update contribution guide with actual repo structure

Target: <600 LOC, zero dependencies, production-ready