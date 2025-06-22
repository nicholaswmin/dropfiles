[![Tests][tests-badge]][tests-url]
[![Swift 6.0][swift-badge]][swift-url]
[![macOS 15.0+][macos-badge]][macos-url]

# dropfiles

WIP - native macOS app for syncing `.dotfiles` to iCloud ☁️

- [Install](#install)
- [UI Usage](#ui-usage)
- [CLI Usage](#cli-usage)
- [Development](#development)
- [Contributions](#contributions)
  - [Setup](#setup)
  - [Run](#run)
  - [Test](#test)
- [License](#license)

## Install

Download the [latest release][latest]

## UI Usage

1. Launch dropfiles from Applications
2. Click the ☁️ icon in the menu bar
3. Select **Preferences...**
4. Click **Choose Folder...** to select watched folder
5. Adjust **Sync Interval** slider (1-60 minutes)
6. Toggle **Auto Sync** to enable automatic syncing

matching files should be copied in folder `dropfiles` in `iCloud`  
& any subsequent changes autosynced to the `dropfiles` iCloud  
folder.

Relaunches on startup.

## CLI Usage

Uses [shortcuts app][shortcuts]

```sh
shortcuts run "Sync dropfiles"
shortcuts run "Toggle Auto Sync"
shortcuts run "Get Sync Status"
```

## Development

See [TODO.md](TODO.md) for cleanup tasks and development roadmap.

## Contributions

Read the [Contribution Guide][contrib]

### Setup 

Install [Apple Developer Tools][adtools]

```sh
xcode-select --install
```

then clone & run:

```sh
git clone https://github.com/nicholaswmin/dropfiles.git
cd dropfiles
swift build -c release
open .build/release/dropfiles
```

### Run

```sh
swift build -c release
open .build/release/dropfiles
```

### Test

```sh
swift test
```

## License

> (c) 2025, [nicholaswmin][author]
>
> The [MIT License][license]
>
> Permission is hereby granted, free of charge, to any person obtaining  
> a copy of this software and associated documentation files (the  
> "Software"), to deal in the Software without restriction, including  
> without limitation the rights to use, copy, modify, merge, publish,  
> distribute, sublicense, and/or sell copies of the Software, and to  
> permit persons to whom the Software is furnished to do so, subject to  
> the following conditions:
>
> The above copyright notice and this permission notice shall be  
> included in all copies or substantial portions of the Software.

[tests-badge]: https://github.com/nicholaswmin/dropfiles/actions/workflows/test.yml/badge.svg
[tests-url]: https://github.com/nicholaswmin/dropfiles/actions
[swift-badge]: https://img.shields.io/badge/Swift-6.0-orange.svg
[swift-url]: https://swift.org
[macos-badge]: https://img.shields.io/badge/macOS-15.0+-blue.svg
[macos-url]: https://developer.apple.com/macos/

[latest]: https://github.com/nicholaswmin/dropfiles/releases/latest
[shortcuts]: https://support.apple.com/guide/shortcuts-mac/
[contrib]: .github/CONTRIBUTING.md
[adtools]: https://developer.apple.com/xcode/resources/
[author]: https://github.com/nicholaswmin
[license]: https://choosealicense.com/licenses/mit/