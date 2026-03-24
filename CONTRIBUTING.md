# Contributing to omni-converter

Thanks for your interest in contributing.

## Getting started

1. Fork and clone the repo
2. Open `omni-converter.xcodeproj` in Xcode 15+
3. Build and run (Cmd+R)

## Making changes

- Create a branch from `master`
- Keep changes focused — one feature or fix per PR
- Test your changes with various image formats before submitting
- Follow the existing code style

## Submitting a PR

1. Push your branch to your fork
2. Open a pull request against `master`
3. Describe what you changed and why

## Reporting bugs

[Open an issue](https://github.com/djordjejanjic/omni-converter/issues) with:

- What you expected to happen
- What actually happened
- macOS version
- Steps to reproduce

## Adding format support

The app uses macOS native ImageIO for encoding/decoding. Output formats must be supported by `CGImageDestination`. Check supported types with:

```swift
CGImageDestinationCopyTypeIdentifiers()
```

Input formats are more flexible — anything `CGImageSource` can read works, including most RAW formats.
