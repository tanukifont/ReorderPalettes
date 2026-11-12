# Native verification

Verified on 2026-11-12 with Glyphs 4.2 (4202), macOS 27.2.1, and Apple Silicon (arm64).

## Version 0.1.4

The actual loaded plug-in reported version 0.1.4. The dialog model and the text of every Bundle Identifier table cell were read in the running Glyphs application.

| Python palette | Verified bundle identifier |
| --- | --- |
| EOD | `com.the3type.EOD` |
| FastScripts | `com.ViktorRubenko.FastScripts` |
| Glyph Note | `com.mekkablue.GlyphNote` |
| Glyphs MCP Bridge | `com.ap.cx.glyphs-mcp.bridge` |

The bridge plug-in declares multiple entries in `Principal Classes`. Its palette resolved to the shared bundle identifier successfully. Built-in native palettes also retained their correct identifiers. A screenshot independently confirmed the displayed values.

The previously saved palette order was retained after updating and restarting Glyphs. The executable rebuilt in this fork matched the natively tested executable byte-for-byte after removing code signatures from temporary copies. Distribution signatures include the updated NOTICE file.

The Makefile build, ZIP extraction and signature verification, and the Xcode ReorderPalettes4 Release build all completed successfully.

Distribution executable SHA-256 is `7a0fd7c90aab80c19ed13bb87db3f92a86e91802dc96c7bb66538e96a264f5d0`.

## Native functional verification in 0.1.3

The following behavior was verified before the identifier-only change in 0.1.4.

- A real mouse drag moved FastScripts above EOD. The user performed this drag because automated mouse dragging was unreliable. Closing the dialog updated both the saved settings and the native sidebar view order. A screenshot confirmed the displayed order.
- Reopening the dialog showed the saved order.
- Reset followed by Close cleared the custom ordering and immediately restored the default sidebar order.
- Dialog model order and table cell text agreed after the row-update fix.
- The existing disclosure views and their expanded/collapsed states were preserved.
- A newly opened font window used the saved order.
- A normal quit and relaunch preserved the saved order in two font windows.
- Closing the modeless dialog left no active modal window, and Glyphs remained responsive.
- The pre-test palette order was restored, the temporary test font was closed, and the existing font remained clean.

## Coverage limits

The package contains arm64 and x86_64 code. Native execution was verified on arm64. Other Glyphs builds, Intel Mac execution, and multiple-row mouse dragging have not been verified.
