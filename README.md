# Chris Titus Tech's macOS Utility

[![Version](https://img.shields.io/github/v/release/ChrisTitusTech/macutil?color=%230567ff&label=Latest%20Release&style=for-the-badge)](https://github.com/ChrisTitusTech/macutil/releases/latest)
![GitHub Downloads (specific asset, all releases)](https://img.shields.io/github/downloads/ChrisTitusTech/macutil/macutil?label=Total%20Downloads&style=for-the-badge)

<!-- TODO: crates.io package here + <br> -->
[![Crates.io Version](https://img.shields.io/crates/v/macutil_tui?style=for-the-badge&color=%23af3a03)](https://crates.io/crates/macutil_tui) [![macutil AUR Version](https://img.shields.io/aur/version/macutil?style=for-the-badge&label=%5BAUR%5D%20macutil&color=%23230567ff)](https://aur.archlinux.org/packages/macutil) [![macutil-bin AUR Version](https://img.shields.io/aur/version/macutil-bin?style=for-the-badge&label=%5BAUR%5D%20macutil-bin&color=%23230567ff)](https://aur.archlinux.org/packages/macutil-bin)

![Preview](/.github/preview.gif)

**macutil** is a distro-agnostic toolbox designed to simplify everyday Linux tasks. It helps you set up applications and optimize your system for specific use cases. The utility is actively developed in Rust 🦀, providing performance and reliability.

> [!NOTE]
> Since the project is still in active development, you may encounter some issues. Please consider [submitting feedback](https://github.com/ChrisTitusTech/macutil/issues) if you do.

## 💡 Usage
To get started, pick which branch you would like to use, then run the command in your terminal:
### Stable Branch (Recommended)
```bash
curl -fsSL https://christitus.com/mac | sh
```
### Dev branch not setup
```bash

```

### CLI arguments

View available options by running:

```bash
macutil --help
```

For installer options:

```bash
curl -fsSL https://christitus.com/mac | sh -s -- --help
```

## ⬇️ Installation

macutil is also available as a package in various repositories:

<details>
  <summary>Cargo</summary>

macutil can be installed via [Cargo](https://doc.rust-lang.org/cargo) with:

```bash
cargo install macutil_tui
```

Note that crates installed using `cargo install` require manual updating with `cargo install --force` (update functionality is [included in macutil](https://christitustech.github.io/macutil/userguide/#applications-setup))

</details>

## Configuration

macutil supports configuration through a TOML config file. Path to the file can be specified with `--config` (or `-c`).

Available options:
- `auto_execute` - A list of commands to execute automatically (can be combined with `--skip-confirmation`)
- `skip_confirmation` - Boolean ( Equal to `--skip-confirmation`)
- `size_bypass` - Boolean ( Equal to `--size-bypass` )

Example config:
```toml
# example_config.toml

auto_execute = [
    "Fastfetch",
    "Alacritty",
    "Kitty"
]

skip_confirmation = true
size_bypass = true
```

```bash
macutil --config /path/to/example_config.toml
```

## 💖 Support

If you find macutil helpful, please consider giving it a ⭐️ to show your support!

## 🎓 Documentation

For comprehensive information on how to use macutil, visit the [macutil Official Documentation](https://chris-titus-docs.github.io/macutil-docs/).

## 🛠 Contributing

We welcome contributions from the community! Before you start, please review our [Contributing Guidelines](.github/CONTRIBUTING.md) to understand how to make the most effective and efficient contributions.

[Official macutil Roadmap](https://chris-titus-docs.github.io/macutil-docs/roadmap/)

Docs are now [here](https://github.com/Chris-Titus-Docs/macutil-docs)

## 🏅 Thanks to All Contributors

Thank you to everyone who has contributed to the development of macutil. Your efforts are greatly appreciated, and you're helping make this tool better for everyone!

[![Contributors](https://contrib.rocks/image?repo=ChrisTitusTech/macutil)](https://github.com/ChrisTitusTech/macutil/graphs/contributors)

## 📜 Contributor Milestones

- 2024/07 - Original macutil Rust TUI was developed by [@JustLinuxUser](https://github.com/JustLinuxUser).
- 2024/09 - TabList (Left Column) and various Rust Core/TUI Improvements developed by [@lj3954](https://github.com/lj3954)
- 2024/09 - Cargo Publish, AUR, Rust, and Bash additions done by [@adamperkowski](https://github.com/adamperkowski)
- 2024/09 - Rust TUI Min/Max, MultiSelection, and Bash additions done by [@jeevithakannan2](https://github.com/jeevithakannan2)
- 2024/09 - Various bash updates and standardization done by [@nnyyxxxx](https://github.com/nnyyxxxx)
- 2024/09 - Multiple bash script additions done by [@guruswarupa](https://github.com/guruswarupa)
