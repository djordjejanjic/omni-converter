# omni-converter

A lightweight open source macOS image converter. Drop files in, pick a format, done.

## Features

- Convert between PNG, JPEG, GIF, TIFF, HEIC, BMP, WebP, and PDF
- RAW file support — Nikon (NEF, NRW), Canon (CR2, CR3), Sony (ARW), Fujifilm (RAF), and more
- Batch conversion with progress tracking
- Resize with aspect ratio lock
- Merge multiple images into a single PDF
- Animated GIF preservation
- JPEG and WebP quality control
<br/>

<img width="609" height="377" alt="image" src="https://github.com/user-attachments/assets/b27901f2-2666-4077-a17f-9d31957bb303" />

## Install

### Homebrew

```
brew install --cask omni-converter
xattr -cr /Applications/omni-converter.app
```

The `xattr` command removes the macOS quarantine flag. This is needed because the app is not notarized with Apple — without it, Gatekeeper will block the app from opening.

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

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

If you find a bug or have a feature request, [open an issue](https://github.com/djordjejanjic/omni-converter/issues).

Claude is used for part of this app, so LLMs are welcome, as long as it is human reviewed.

## Third-party libraries

WebP encoding uses [libwebp](https://chromium.googlesource.com/webm/libwebp) (v1.5.0) by Google, vendored directly in the repository.

> Copyright (c) 2010, Google Inc. All rights reserved.
>
> Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
>
> - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
> - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
> - Neither the name of Google nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
>
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

## License

[MIT](LICENSE)
