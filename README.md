# ReorderPalettes for Glyphs 4

A plug-in for changing the order of palettes in the Glyphs 4 sidebar. This unofficial fork of Morisawa Inc.'s ReorderPalettes adds Glyphs 4 compatibility and is maintained by Tanukifont. [Original repository](https://github.com/morisawa-inc/ReorderPalettes)

![Palette reordering dialog in Glyphs 4](ReorderPalettes.png)

## Installation

1. Download `ReorderPalettes-0.1.4.zip` from [Releases](https://github.com/tanukifont/ReorderPalettes/releases) and extract it.
2. Double-click `ReorderPalettes.glyphsPlugin` and confirm installation in Glyphs 4. Replace the existing ReorderPalettes installation if prompted.
3. Restart Glyphs 4.

## Usage

1. Open a font window.
2. Choose **Glyphs → Reorder Palettes…**.
3. Drag rows to change the palette order.
4. Click **Close** to apply the order to the open font windows.

Click **Reset**, then **Close**, to restore the default order. Your custom order is also used in new windows and after restarting Glyphs.

## Glyphs 4 changes

- Uses palette instances already loaded in the Glyphs 4 sidebar.
- Applies reordering to existing font windows.
- Opens as a modeless settings window.
- Keeps the table display synchronized with the underlying order after dragging.
- Displays bundle identifiers for Python palettes and plug-ins containing multiple principal classes.

## Requirements and verification

- Glyphs 4
- macOS 12 or later
- Universal binary containing Apple Silicon and Intel code

Native verification covers Glyphs 4.2 (4202) on macOS 27.2.1 with Apple Silicon. Other Glyphs builds, Intel Mac execution, and multiple-row mouse dragging have not been verified. See [TESTING.md](TESTING.md) for details.

## Building from source

Use Xcode Command Line Tools on macOS.

```sh
make
make archive
```

The plug-in is built in the repository root. The distribution ZIP is created in `build/`. To build in Xcode, use the `ReorderPalettes4` target.

## License

Apache License 2.0. Original copyright and attribution belong to Morisawa Inc. Glyphs 4 compatibility modifications are maintained by Tanukifont. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
