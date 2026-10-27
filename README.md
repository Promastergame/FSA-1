# FSA 1 (Fast System App 1)

<img src="assets/badge.svg" alt="Zig 0.18.0 | Win32 / GDI+ | Zero Deps" height="24">

Windows system overlay for pasting clipboard images (`Ctrl + V`) directly into File Explorer folders and the Desktop as files.

Built with Zig (`std` only) on top of raw Win32 API, COM (`IShellWindows` / `IFolderView`), DWM, and GDI+. No tray icons, no background webviews, no external dependencies.

[Русская версия](README_RU.md)

## Problem & Solution

Windows ignores `Ctrl + V` in File Explorer when the clipboard holds raw bitmap data (`CF_BITMAP` / `CF_DIB`) from a screenshot or browser copy instead of a file handle (`CF_HDROP`).

`fsa1.exe` hooks `Ctrl + V` at the system level, checks if the active window is File Explorer or the Desktop while an image is in the clipboard, resolves the active tab's directory via COM, and writes the encoded image directly to that folder. Text and file pasting remain untouched.

## Controls

- **`Ctrl + V` (in File Explorer or Desktop):** Opens the paste HUD at the cursor (or saves immediately if auto-save is enabled).
  - Type a custom filename or leave empty to use the next available template name (`picture_1`, `picture_2`, ...).
  - Switch output format (`PNG`, `JPEG`, `BMP`, `TIFF`) with `Tab`, `Left`/`Right` arrows, or mouse click.
  - Press `Enter` to save, `Esc` (or click outside) to cancel.
- **`Tab + 1` (Global):** Opens the settings overlay. Configures auto-save mode, filename prefix template, default format, and UI language (`Auto`, `EN`, `RU`). Settings are stored in `HKCU\Software\FSA\FSA1`.

## Build

Requires Zig `0.18.0` (or `0.17.0`).

```sh
zig build -Doptimize=ReleaseSmall
```

Binary output: zig-out/bin/fsa1.exe.

## License
Dual-licensed under [MIT](LICENSE) OR [LGPL-3.0](COPYING).