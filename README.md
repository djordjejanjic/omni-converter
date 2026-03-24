# omni-converter

A lightweight open source macOS image converter. Drop files in, pick a format, done.

## Features

- Convert between PNG, JPEG, GIF, TIFF, HEIC, BMP, and PDF
- RAW file support — Nikon (NEF, NRW), Canon (CR2, CR3), Sony (ARW), Fujifilm (RAF), and more
- Batch conversion with progress tracking
- Resize with aspect ratio lock
- Merge multiple images into a single PDF
- Animated GIF preservation
- JPEG quality control

## Install

### Homebrew

```
brew install --cask --no-quarantine omni-converter
```

The `--no-quarantine` flag is needed because the app is not notarized with Apple. Without it, macOS Gatekeeper will block the app from opening.

If you already installed without the flag, run:

```
xattr -cr /Applications/omni-converter.app
```

### Build from source

Requires Xcode 15+ and macOS 14+.

```
git clone https://github.com/djordjejanjic/omni-converter.git
cd omni-converter
xcodebuild -project omni-converter.xcodeproj -scheme omni-converter -configuration Release build
```

The built app will be in `build/Release/omni-converter.app`. Drag it to `/Applications`.

## Usage

1. Drop images or RAW files onto the window (or click to browse)
2. Pick an output format
3. Optionally adjust quality or resize dimensions
4. Click **Convert**

## License

MIT
