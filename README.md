# Chris Titus Tech's MacOS Utility

[![Version](https://img.shields.io/github/v/release/ChrisTitusTech/macutil?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/ChrisTitusTech/macutil/releases/latest)
![GitHub Downloads (specific asset, all releases)](https://img.shields.io/github/downloads/ChrisTitusTech/macutil/macutil?label=Total%20Downloads&style=for-the-badge)


> [!NOTE]
> I'm discontinuing Macutil due to Apples Limited access to changing system options. They restricted it down too much these past couple releases and is currently on HOLD for any future releases while I assess future development. 

# HEAVY DEVELOPMENT

- Look at creating or installing a package into /Applications or other methods like copying to ~/.local/bin - _Update: Waiting on Apple Developer License Approval_

# Installation

Currently, macutil is download only and doesn't have a developer license. You can download the latest release from the [Releases page](https://github.com/ChrisTitusTech/macutil/releases/latest).

## 🍎 Building your own .app (fork friendly)

The release ships a ready to use `MacUtil-Universal.app`. If you forked this
repository, you can build the same bundle locally — no Apple Developer account
required — and hand the resulting `.app` to anyone.

Requirements: macOS 12+, [.NET 9 SDK](https://dotnet.microsoft.com/download) and
Xcode Command Line Tools (`xcode-select --install`).

```bash
git clone https://github.com/<your-user>/macutil.git
cd macutil/MacUtilGUI

./packaging/build_app.sh --out ~/Applications   # app for the current architecture
./packaging/build_app.sh --universal            # x64 + arm64 in a single .app
```

Result: `dist/MacUtil-Universal.app` plus `dist/MacUtil-Universal.zip` (the zip
keeps the executable bit and symlinks, so prefer it when sharing).

Bundles are ad-hoc signed by default. If you have a Developer ID you can sign and
notarize in the same run:

```bash
./packaging/build_app.sh --universal \
  --sign "Developer ID Application: Your Name (TEAMID)" \
  --notarize macutil-notary-profile
```

### First launch (unsigned builds)

macOS blocks apps that are not notarized. Either right click the app and choose
**Open**, or remove the quarantine flag once:

```bash
xattr -dr com.apple.quarantine /Applications/MacUtil.app
open /Applications/MacUtil.app
```

### Why not a single-file publish?

`PublishSingleFile` + `IncludeNativeLibrariesForSelfExtract` makes the app unpack
its native libraries into `~/.net/<app>/<hash>/` at startup. On Apple Silicon
macOS refuses to load those copies because they are ad-hoc signed while the host
process is Developer ID signed, and the app dies with:

```
DllNotFoundException: Unable to load shared library 'libSkiaSharp'
... mapping process and mapped file (non-platform) have different Team IDs
```

That is why single-file and trimming are opt-in (`-p:MacUtilSingleFile=true`,
`-p:MacUtilTrim=true`) and the packaging script does not use them.

### Full Disk Access

Some maintenance scripts touch protected locations. Add the app (not Terminal)
in **System Settings → Privacy & Security → Full Disk Access** if you see the
permission warning.

## 💖 Support

If you find macutil helpful, please consider giving it a ⭐️ to show your support!

## 🛠 Contributing

We welcome contributions from the community! Before you start, please review our [Contributing Guidelines](.github/CONTRIBUTING.md) to understand how to make the most effective and efficient contributions.

## 🏅 Thanks to All Contributors

Thank you to everyone who has contributed to the development of macutil. Your efforts are greatly appreciated, and you're helping make this tool better for everyone!

[![Contributors](https://contrib.rocks/image?repo=ChrisTitusTech/macutil)](https://github.com/ChrisTitusTech/macutil/graphs/contributors)

## 📜 Contributor Milestones

- 2025/07/21: Claude Sonnet 4 makes boilerplate code for the project.
