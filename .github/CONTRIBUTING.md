# Contribution Guide

Follows a minimalist philosophy: no external dependencies,  
native macOS frameworks only, feature-poor and focused.

- [Setup](#setup)
- [Process](#process)
- [Code Style](#code-style)
- [Testing](#testing)
- [Publish](#publish)
- [Todos](#todos)

## Setup

Install [Apple Developer Tools][apl-devtools]:

```bash
xcode-select --install
```

> **Note**: Xcode is *not* required.

Clone and run:

```bash
git clone https://github.com/.dropfiles/dropfiles.git
cd dropfiles
swift build -c release
open .build/release/dropfiles
```

## Process

* Open an [Issue][new-issue] describing bug or feature.
* Follow [GitHub Flow][gh-flow]: Open Pull Request,  
  mention the issue.
* Push small, focused commits.

> **Note**: Include structured [tests][tests], following [guidelines](#testing).

## Code Style

Follow [Swift API Design Guidelines][swift-api]:

* Clarity at call site: `remove(at: index)`
* No abbreviations: `configuration` not `config`
* Early validation: Use `guard` for clean error handling
* Async/await: Prefer over closures for file operations
* Error types: Create specific, actionable error messages
* Side effects: Verb for mutating, noun for non-mutating
* Functional patterns: Chain operations, use KeyPath expressions

```swift
// Side effects naming
mutating func addFile(_ url: URL)     // Verb - modifies state
func addedFile(_ url: URL) -> Self    // Noun - returns new instance

// Functional patterns
let recentFiles = files
    .filter { $0.lastModified > cutoffDate }
    .sorted(by: \.name)
    .prefix(10)

// KeyPath expressions
files.max(by: \.lastModified)
items.sorted(by: \.priority)
```

```swift
// Early validation
func syncFile(_ url: URL) async throws {
    guard url.isFileURL else { throw SyncError.invalidURL }
    guard FileManager.default.fileExists(atPath: url.path) else { 
        throw SyncError.fileNotFound(url.path) 
    }
    // Happy path continues unindented
}

// Specific errors
enum SyncError: Error, LocalizedError {
    case invalidURL
    case fileNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL must be a file URL"
        case .fileNotFound(let path): return "File not found at \(path)"
        }
    }
}
```

## Testing

Run tests:

```bash
swift test
```

Naming: `test_function_condition_result()`

Test async operations and error conditions:

```swift
func test_syncFile_validURL_succeeds() async throws {
    let manager = FileSyncManager()
    let url = createTestFile()
    
    await XCTAssertNoThrow(try await manager.syncFile(url))
}

func test_syncFile_missingFile_throwsFileNotFound() async {
    let manager = FileSyncManager()
    let url = URL(fileURLWithPath: "/nonexistent.txt")
    
    await XCTAssertThrowsError(try await manager.syncFile(url)) { error in
        XCTAssertTrue(error is SyncError)
    }
}
```

## Publish

Requires:

* `<developer-id>`: Apple [Developer ID][apl-devid]

### Build for release

```sh
swift build -c release
```

### Code sign

Use [distribution certificate][codesign] to sign app bundle.

```sh
codesign --force --options runtime --sign "Developer ID Application: Your Name" \
         --entitlements app.entitlements DropFiles.app
```

### Notarisation

Get app [notarized][notarize] by Apple.

```sh
# Create archive
ditto -c -k --keepParent DropFiles.app DropFiles.zip

# Submit for notarization
xcrun notarytool submit DropFiles.zip --keychain-profile "notary" --wait

# Staple notarization
xcrun stapler staple DropFiles.app
```

### Submit via [Transporter][transporter]

Upload signed and notarized app to [App Store Connect][appstore].

```sh
xcrun altool --upload-app --type osx --file DropFiles.pkg \
             --username "your@apple.id" --password "@keychain:AC_PASSWORD"
```

## Todos

- [ ] write a contribution guide
- [ ] create PR template

## authors

[nicholaswmin][author]

⬅️ [Back to README](../README.md)

[author]: https://github.com/nicholaswmin
[apl-devtools]: https://developer.apple.com/xcode/resources/
[apl-devid]: https://developer.apple.com/developer-id/
[swift-api]: https://www.swift.org/documentation/api-design-guidelines/
[new-issue]: https://github.com/.dropfiles/dropfiles/issues/new
[gh-flow]: https://docs.github.com/en/get-started/using-github/  
           github-flow
[tests]: Tests/
[codesign]: https://developer.apple.com/documentation/security/  
            code_signing_services
[notarize]: https://developer.apple.com/documentation/security/  
            notarizing_macos_software_before_distribution
[appstore]: https://appstoreconnect.apple.com
[transporter]: https://apps.apple.com/app/transporter/id1450874784