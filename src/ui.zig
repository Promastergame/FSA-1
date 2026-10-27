const std = @import("std");
const w = @import("win32.zig");
const config = @import("config.zig");
const clipboard = @import("clipboard.zig");
const explorer = @import("explorer.zig");
const L = w.L;

const Mode = enum {
    none,
    paste,
    settings,
};

pub var g_cfg: config.Config = .{};
var g_hwnd: ?w.HWND = null;
var g_mode: Mode = .none;
var g_open_tick: u64 = 0;

var g_font_reg: ?w.HFONT = null;
var g_font_bold: ?w.HFONT = null;
var g_font_small: ?w.HFONT = null;

var g_target_dir: [260]u16 = @splat(0);
var g_target_dir_len: usize = 0;

var g_input_buf: [64]u16 = @splat(0);
var g_input_len: usize = 0;

var g_preview_buf: [128]u16 = @splat(0);
var g_preview_len: usize = 0;

var g_active_fmt: config.Format = .png;
var g_switch_anim: f32 = 0.0;

const TIMER_ANIM: usize = 1;

// GDI Colors (0x00BBGGRR)
const COL_BG: w.DWORD = 0x00171414;
const COL_CARD: w.DWORD = 0x00241E1E;
const COL_BORDER: w.DWORD = 0x00382E2E;
const COL_ACCENT: w.DWORD = 0x00EB6325;
const COL_ACCENT_LIGHT: w.DWORD = 0x00F78E4F;
const COL_TEXT: w.DWORD = 0x00F6F4F4;
const COL_MUTED: w.DWORD = 0x007A7171;
const COL_SUBTEXT: w.DWORD = 0x00AAA1A1;

const PASTE_W: i32 = 380;
const PASTE_H: i32 = 104;

const SET_W: i32 = 380;
const SET_H: i32 = 212;

pub fn init(hinst: w.HINSTANCE) void {
    g_cfg = config.Config.load();
    g_switch_anim = if (g_cfg.auto_save) 1.0 else 0.0;

    g_font_reg = w.CreateFontW(-15, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, L("Segoe UI"));
    g_font_bold = w.CreateFontW(-14, 0, 0, 0, 600, 0, 0, 0, 1, 0, 0, 5, 0, L("Segoe UI"));
    g_font_small = w.CreateFontW(-13, 0, 0, 0, 400, 0, 0, 0, 1, 0, 0, 5, 0, L("Segoe UI"));

    const wc = w.WNDCLASSEXW{
        .lpfnWndProc = overlayWndProc,
        .hInstance = hinst,
        .hCursor = w.LoadCursorW(null, w.IDC_ARROW),
        .lpszClassName = L("FSA1_HUD"),
    };
    _ = w.RegisterClassExW(&wc);

    g_hwnd = w.CreateWindowExW(
        w.WS_EX_TOPMOST | w.WS_EX_TOOLWINDOW,
        L("FSA1_HUD"),
        L("FSA 1"),
        w.WS_POPUP,
        0,
        0,
        PASTE_W,
        PASTE_H,
        null,
        null,
        hinst,
        null,
    );

    if (g_hwnd) |hwnd| {
        const dark: w.BOOL = 1;
        const round: w.DWORD = w.DWMWCP_ROUND;
        _ = w.DwmSetWindowAttribute(hwnd, w.DWMWA_USE_IMMERSIVE_DARK_MODE, &dark, @sizeOf(w.BOOL));
        _ = w.DwmSetWindowAttribute(hwnd, w.DWMWA_WINDOW_CORNER_PREFERENCE, &round, @sizeOf(w.DWORD));
    }
}

fn showAndFocus(hwnd: w.HWND, width: i32, height: i32) void {
    var pt: w.POINT = .{ .x = 0, .y = 0 };
    _ = w.GetCursorPos(&pt);

    var x = pt.x - @divTrunc(width, 2);
    var y = pt.y - 24;

    if (w.MonitorFromPoint(pt, w.MONITOR_DEFAULTTONEAREST)) |mon| {
        var mi: w.MONITORINFO = .{};
        if (w.GetMonitorInfoW(mon, &mi) != 0) {
            if (x < mi.rcWork.left + 10) x = mi.rcWork.left + 10;
            if (y < mi.rcWork.top + 10) y = mi.rcWork.top + 10;
            if (x + width > mi.rcWork.right - 10) x = mi.rcWork.right - width - 10;
            if (y + height > mi.rcWork.bottom - 10) y = mi.rcWork.bottom - height - 10;
        }
    }

    g_open_tick = w.GetTickCount64();
    const fg = w.GetForegroundWindow();
    const fg_tid = if (fg) |f| w.GetWindowThreadProcessId(f, null) else 0;
    const cur_tid = w.GetCurrentThreadId();

    if (fg_tid != 0 and fg_tid != cur_tid) {
        _ = w.AttachThreadInput(fg_tid, cur_tid, 1);
    }

    _ = w.SetWindowPos(hwnd, null, x, y, width, height, 0);
    _ = w.ShowWindow(hwnd, w.SW_SHOW);
    w.keybd_event(0, 0, 0, 0);
    _ = w.BringWindowToTop(hwnd);
    _ = w.SetForegroundWindow(hwnd);
    _ = w.SetFocus(hwnd);

    if (fg_tid != 0 and fg_tid != cur_tid) {
        _ = w.AttachThreadInput(fg_tid, cur_tid, 0);
    }

    _ = w.InvalidateRect(hwnd, null, 0);
}

fn hideOverlay() void {
    g_mode = .none;
    if (g_hwnd) |hwnd| {
        _ = w.KillTimer(hwnd, TIMER_ANIM);
        _ = w.ShowWindow(hwnd, w.SW_HIDE);
    }
}

pub fn triggerPaste(fg_hwnd: w.HWND) void {
    var path_buf: [260]u16 = @splat(0);
    const dir = explorer.resolveTargetFolder(fg_hwnd, &path_buf) orelse return;

    g_target_dir = @splat(0);
    @memcpy(g_target_dir[0..dir.len], dir);
    g_target_dir_len = dir.len;

    const detected_fmt = clipboard.detectImageFormat(g_cfg.default_format);

    if (g_cfg.auto_save) {
        _ = clipboard.saveClipboardImage(g_target_dir[0..g_target_dir_len], &.{}, &g_cfg, detected_fmt);
        return;
    }

    const hwnd = g_hwnd orelse return;
    g_mode = .paste;
    g_input_buf = @splat(0);
    g_input_len = 0;
    g_active_fmt = detected_fmt;
    updatePreview();

    showAndFocus(hwnd, PASTE_W, PASTE_H);
}

pub fn triggerSettings() void {
    const hwnd = g_hwnd orelse return;
    g_mode = .settings;
    g_input_buf = @splat(0);
    @memcpy(g_input_buf[0..g_cfg.template_len], g_cfg.template[0..g_cfg.template_len]);
    g_input_len = g_cfg.template_len;
    g_active_fmt = g_cfg.default_format;
    g_switch_anim = if (g_cfg.auto_save) 1.0 else 0.0;

    showAndFocus(hwnd, SET_W, SET_H);
}

fn updatePreview() void {
    g_preview_len = clipboard.getAutoStemPreview(
        &g_preview_buf,
        g_target_dir[0..g_target_dir_len],
        &g_cfg,
        g_active_fmt,
    );
}

fn commitAction() void {
    if (g_mode == .paste) {
        const fmt = g_active_fmt;
        const name_slice = g_input_buf[0..g_input_len];
        hideOverlay();
        _ = clipboard.saveClipboardImage(g_target_dir[0..g_target_dir_len], name_slice, &g_cfg, fmt);
    } else if (g_mode == .settings) {
        if (g_input_len > 0) {
            g_cfg.template = @splat(0);
            @memcpy(g_cfg.template[0..g_input_len], g_input_buf[0..g_input_len]);
            g_cfg.template_len = g_input_len;
        }
        g_cfg.default_format = g_active_fmt;
        g_cfg.save();
        hideOverlay();
    }
}

fn drawRoundBox(hdc: w.HDC, rc: w.RECT, radius: i32, fill_col: w.DWORD, border_col: w.DWORD) void {
    const br = w.CreateSolidBrush(fill_col) orelse return;
    defer _ = w.DeleteObject(@ptrCast(br));
    const pen = w.CreatePen(w.PS_SOLID, 1, border_col) orelse return;
    defer _ = w.DeleteObject(@ptrCast(pen));

    const old_br = w.SelectObject(hdc, @ptrCast(br));
    const old_pen = w.SelectObject(hdc, @ptrCast(pen));
    _ = w.RoundRect(hdc, rc.left, rc.top, rc.right, rc.bottom, radius, radius);
    if (old_br) |ob| _ = w.SelectObject(hdc, ob);
    if (old_pen) |op| _ = w.SelectObject(hdc, op);
}

fn lerpChannel(a: u8, b: u8, t: f32) u32 {
    const fa: f32 = @floatFromInt(a);
    const fb: f32 = @floatFromInt(b);
    return @intFromFloat(@round(fa + (fb - fa) * t));
}

fn drawSmoothSwitch(hdc: w.HDC, x: i32, y: i32, t: f32) void {
    var g: ?*w.GpGraphics = null;
    if (w.GdipCreateFromHDC(hdc, &g) != 0 or g == null) return;
    defer _ = w.GdipDeleteGraphics(g.?);

    const r = lerpChannel(0x32, 0x25, t);
    const gr = lerpChannel(0x32, 0x63, t);
    const b = lerpChannel(0x3C, 0xEB, t);
    const track_argb: w.DWORD = 0xFF000000 | (r << 16) | (gr << 8) | b;

    var br_track: ?*w.GpBrush = null;
    if (w.GdipCreateSolidFill(track_argb, &br_track) != 0 or br_track == null) return;
    defer _ = w.GdipDeleteBrush(br_track.?);

    var br_knob: ?*w.GpBrush = null;
    if (w.GdipCreateSolidFill(0xFFF8FAFC, &br_knob) != 0 or br_knob == null) return;
    defer _ = w.GdipDeleteBrush(br_knob.?);

    // Capsule track (40x20): 2 anti-aliased end circles + center rect
    _ = w.GdipSetSmoothingMode(g.?, 4);
    _ = w.GdipFillEllipseI(g.?, br_track.?, x, y, 20, 20);
    _ = w.GdipFillEllipseI(g.?, br_track.?, x + 20, y, 20, 20);
    _ = w.GdipSetSmoothingMode(g.?, 0);
    _ = w.GdipFillRectangleI(g.?, br_track.?, x + 10, y, 20, 21);

    // Smooth circular knob (14x14)
    _ = w.GdipSetSmoothingMode(g.?, 4);
    const offset_x: i32 = @intFromFloat(@round(t * 20.0));
    _ = w.GdipFillEllipseI(g.?, br_knob.?, x + 3 + offset_x, y + 3, 14, 14);
}

fn drawText(hdc: w.HDC, text: []const u16, rc: w.RECT, color: w.DWORD, font: ?w.HFONT, flags: w.UINT) void {
    if (text.len == 0) return;
    if (font) |f| _ = w.SelectObject(hdc, @ptrCast(f));
    _ = w.SetTextColor(hdc, color);
    var r = rc;
    _ = w.DrawTextW(hdc, text.ptr, @intCast(text.len), &r, flags | w.DT_SINGLELINE | w.DT_VCENTER | w.DT_NOPREFIX);
}

fn drawCaret(hdc: w.HDC, text: []const u16, base_x: i32, top_y: i32, bottom_y: i32, max_x: i32) void {
    var cx = base_x;
    if (text.len > 0) {
        if (g_font_reg) |f| _ = w.SelectObject(hdc, @ptrCast(f));
        var calc = w.RECT{ .left = base_x, .top = top_y, .right = max_x, .bottom = bottom_y };
        _ = w.DrawTextW(hdc, text.ptr, @intCast(text.len), &calc, w.DT_CALCRECT | w.DT_SINGLELINE | w.DT_NOPREFIX);
        cx = @min(calc.right + 1, max_x);
    }
    const rc_caret = w.RECT{ .left = cx, .top = top_y + 9, .right = cx + 2, .bottom = bottom_y - 9 };
    drawRoundBox(hdc, rc_caret, 1, COL_ACCENT_LIGHT, COL_ACCENT_LIGHT);
}

fn extLabel(fmt: config.Format) []const u16 {
    return switch (fmt) {
        .png => L(".png"),
        .jpeg => L(".jpg"),
        .bmp => L(".bmp"),
        .tiff => L(".tiff"),
    };
}

fn pillTitle(idx: usize) []const u16 {
    return switch (idx) {
        0 => L("PNG"),
        1 => L("JPEG"),
        2 => L("BMP"),
        else => L("TIFF"),
    };
}

fn paintPaste(hdc: w.HDC) void {
    const s = g_cfg.strings();

    const rc_input = w.RECT{ .left = 12, .top = 12, .right = PASTE_W - 12, .bottom = 50 };
    drawRoundBox(hdc, rc_input, 10, COL_CARD, COL_ACCENT_LIGHT);

    const rc_txt = w.RECT{ .left = 22, .top = 12, .right = PASTE_W - 74, .bottom = 50 };
    if (g_input_len > 0) {
        drawText(hdc, g_input_buf[0..g_input_len], rc_txt, COL_TEXT, g_font_reg, w.DT_LEFT | w.DT_END_ELLIPSIS);
        drawCaret(hdc, g_input_buf[0..g_input_len], 22, 12, 50, PASTE_W - 76);
    } else {
        drawText(hdc, g_preview_buf[0..g_preview_len], rc_txt, COL_MUTED, g_font_reg, w.DT_LEFT | w.DT_END_ELLIPSIS);
        drawCaret(hdc, &.{}, 22, 12, 50, PASTE_W - 76);
    }

    const rc_ext = w.RECT{ .left = PASTE_W - 72, .top = 12, .right = PASTE_W - 22, .bottom = 50 };
    drawText(hdc, extLabel(g_active_fmt), rc_ext, COL_ACCENT_LIGHT, g_font_bold, w.DT_RIGHT);

    var i: usize = 0;
    while (i < 4) : (i += 1) {
        const x1: i32 = 12 + @as(i32, @intCast(i)) * 58;
        const rc_pill = w.RECT{ .left = x1, .top = 60, .right = x1 + 52, .bottom = 90 };
        const is_sel = (@intFromEnum(g_active_fmt) == i);
        const fill = if (is_sel) COL_ACCENT else COL_CARD;
        const bord = if (is_sel) COL_ACCENT_LIGHT else COL_BORDER;
        const tcol = if (is_sel) COL_TEXT else COL_SUBTEXT;

        drawRoundBox(hdc, rc_pill, 8, fill, bord);
        drawText(hdc, pillTitle(i), rc_pill, tcol, g_font_bold, w.DT_CENTER);
    }

    const rc_save = w.RECT{ .left = 248, .top = 60, .right = PASTE_W - 12, .bottom = 90 };
    drawRoundBox(hdc, rc_save, 8, COL_ACCENT, COL_ACCENT_LIGHT);
    drawText(hdc, std.mem.span(s.save_btn), rc_save, COL_TEXT, g_font_bold, w.DT_CENTER);
}

fn paintSettings(hdc: w.HDC) void {
    const s = g_cfg.strings();

    const rc_hdr = w.RECT{ .left = 14, .top = 10, .right = SET_W - 60, .bottom = 32 };
    drawText(hdc, std.mem.span(s.settings_title), rc_hdr, COL_TEXT, g_font_bold, w.DT_LEFT);

    const rc_esc = w.RECT{ .left = SET_W - 60, .top = 10, .right = SET_W - 14, .bottom = 32 };
    drawText(hdc, L("ESC"), rc_esc, COL_MUTED, g_font_small, w.DT_RIGHT);

    const rc_auto = w.RECT{ .left = 12, .top = 38, .right = SET_W - 12, .bottom = 74 };
    drawRoundBox(hdc, rc_auto, 8, COL_CARD, COL_BORDER);

    const rc_auto_txt = w.RECT{ .left = 22, .top = 38, .right = SET_W - 68, .bottom = 74 };
    drawText(hdc, std.mem.span(s.autosave_check), rc_auto_txt, COL_TEXT, g_font_small, w.DT_LEFT);

    drawSmoothSwitch(hdc, SET_W - 62, 46, g_switch_anim);

    const rc_tpl_lbl = w.RECT{ .left = 14, .top = 82, .right = 110, .bottom = 118 };
    drawText(hdc, std.mem.span(s.template_label), rc_tpl_lbl, COL_SUBTEXT, g_font_small, w.DT_LEFT);

    const rc_tpl_box = w.RECT{ .left = 114, .top = 82, .right = SET_W - 12, .bottom = 118 };
    drawRoundBox(hdc, rc_tpl_box, 8, COL_CARD, COL_ACCENT_LIGHT);

    const rc_tpl_txt = w.RECT{ .left = 124, .top = 82, .right = SET_W - 20, .bottom = 118 };
    drawText(hdc, g_input_buf[0..g_input_len], rc_tpl_txt, COL_TEXT, g_font_reg, w.DT_LEFT);
    drawCaret(hdc, g_input_buf[0..g_input_len], 124, 82, 118, SET_W - 22);

    const rc_fmt_lbl = w.RECT{ .left = 14, .top = 126, .right = 110, .bottom = 158 };
    drawText(hdc, std.mem.span(s.format_label), rc_fmt_lbl, COL_SUBTEXT, g_font_small, w.DT_LEFT);

    var i: usize = 0;
    while (i < 4) : (i += 1) {
        const x1: i32 = 114 + @as(i32, @intCast(i)) * 64;
        const rc_pill = w.RECT{ .left = x1, .top = 126, .right = x1 + 58, .bottom = 158 };
        const is_sel = (@intFromEnum(g_active_fmt) == i);
        const fill = if (is_sel) COL_ACCENT else COL_CARD;
        const bord = if (is_sel) COL_ACCENT_LIGHT else COL_BORDER;
        drawRoundBox(hdc, rc_pill, 8, fill, bord);
        drawText(hdc, pillTitle(i), rc_pill, if (is_sel) COL_TEXT else COL_SUBTEXT, g_font_bold, w.DT_CENTER);
    }

    const rc_lng_lbl = w.RECT{ .left = 14, .top = 168, .right = 110, .bottom = 200 };
    drawText(hdc, std.mem.span(s.lang_label), rc_lng_lbl, COL_SUBTEXT, g_font_small, w.DT_LEFT);

    const lang_names = [_][]const u16{ L("Auto"), L("EN"), L("RU") };
    var l: usize = 0;
    while (l < 3) : (l += 1) {
        const x1: i32 = 114 + @as(i32, @intCast(l)) * 52;
        const rc_lp = w.RECT{ .left = x1, .top = 168, .right = x1 + 46, .bottom = 200 };
        const is_sel = (@intFromEnum(g_cfg.lang) == l);
        drawRoundBox(hdc, rc_lp, 8, if (is_sel) COL_ACCENT else COL_CARD, if (is_sel) COL_ACCENT_LIGHT else COL_BORDER);
        drawText(hdc, lang_names[l], rc_lp, if (is_sel) COL_TEXT else COL_SUBTEXT, g_font_bold, w.DT_CENTER);
    }

    const rc_save = w.RECT{ .left = 274, .top = 168, .right = SET_W - 12, .bottom = 200 };
    drawRoundBox(hdc, rc_save, 8, COL_ACCENT, COL_ACCENT_LIGHT);
    drawText(hdc, std.mem.span(s.save_btn), rc_save, COL_TEXT, g_font_bold, w.DT_CENTER);
}

fn ptInRect(x: i32, y: i32, l: i32, t: i32, r: i32, b: i32) bool {
    return x >= l and x < r and y >= t and y < b;
}

fn handleClick(hwnd: w.HWND, x: i32, y: i32) void {
    if (g_mode == .paste) {
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            const x1: i32 = 12 + @as(i32, @intCast(i)) * 58;
            if (ptInRect(x, y, x1, 60, x1 + 52, 90)) {
                g_active_fmt = @enumFromInt(@as(u32, @intCast(i)));
                updatePreview();
                _ = w.InvalidateRect(hwnd, null, 0);
                return;
            }
        }
        if (ptInRect(x, y, 248, 60, PASTE_W - 12, 90)) {
            commitAction();
            return;
        }
    } else if (g_mode == .settings) {
        if (ptInRect(x, y, 12, 38, SET_W - 12, 74)) {
            g_cfg.auto_save = !g_cfg.auto_save;
            _ = w.SetTimer(hwnd, TIMER_ANIM, 10, null);
            _ = w.InvalidateRect(hwnd, null, 0);
            return;
        }
        var i: usize = 0;
        while (i < 4) : (i += 1) {
            const x1: i32 = 114 + @as(i32, @intCast(i)) * 64;
            if (ptInRect(x, y, x1, 126, x1 + 58, 158)) {
                g_active_fmt = @enumFromInt(@as(u32, @intCast(i)));
                _ = w.InvalidateRect(hwnd, null, 0);
                return;
            }
        }
        var l: usize = 0;
        while (l < 3) : (l += 1) {
            const x1: i32 = 114 + @as(i32, @intCast(l)) * 52;
            if (ptInRect(x, y, x1, 168, x1 + 46, 200)) {
                g_cfg.lang = @enumFromInt(@as(u32, @intCast(l)));
                _ = w.InvalidateRect(hwnd, null, 0);
                return;
            }
        }
        if (ptInRect(x, y, 274, 168, SET_W - 12, 200)) {
            commitAction();
            return;
        }
    }
}

fn isValidFilenameChar(ch: u16) bool {
    if (ch < 0x20) return false;
    return switch (ch) {
        '\\', '/', ':', '*', '?', '"', '<', '>', '|' => false,
        else => true,
    };
}

fn overlayWndProc(hwnd: w.HWND, uMsg: w.UINT, wParam: w.WPARAM, lParam: w.LPARAM) callconv(.winapi) w.LRESULT {
    switch (uMsg) {
        w.WM_ERASEBKGND => return 1,
        w.WM_ACTIVATE => {
            if ((wParam & 0xFFFF) == w.WA_INACTIVE) {
                if (w.GetTickCount64() - g_open_tick > 180) {
                    hideOverlay();
                }
            }
            return 0;
        },
        w.WM_TIMER => {
            if (wParam == TIMER_ANIM) {
                const target: f32 = if (g_cfg.auto_save) 1.0 else 0.0;
                const diff = target - g_switch_anim;
                if (@abs(diff) < 0.03) {
                    g_switch_anim = target;
                    _ = w.KillTimer(hwnd, TIMER_ANIM);
                } else {
                    g_switch_anim += diff * 0.35;
                }
                _ = w.InvalidateRect(hwnd, null, 0);
            }
            return 0;
        },
        w.WM_KEYDOWN => {
            if (wParam == w.VK_ESCAPE) {
                hideOverlay();
                return 0;
            }
            if (wParam == w.VK_RETURN) {
                commitAction();
                return 0;
            }
            if (wParam == w.VK_TAB or wParam == w.VK_RIGHT) {
                const next = (@intFromEnum(g_active_fmt) + 1) % 4;
                g_active_fmt = @enumFromInt(next);
                if (g_mode == .paste) updatePreview();
                _ = w.InvalidateRect(hwnd, null, 0);
                return 0;
            }
            if (wParam == w.VK_LEFT) {
                const prev = (@intFromEnum(g_active_fmt) + 3) % 4;
                g_active_fmt = @enumFromInt(prev);
                if (g_mode == .paste) updatePreview();
                _ = w.InvalidateRect(hwnd, null, 0);
                return 0;
            }
            return 0;
        },
        w.WM_CHAR => {
            const ch: u16 = @truncate(wParam);
            if (ch == 0x08) {
                if (g_input_len > 0) {
                    g_input_len -= 1;
                    g_input_buf[g_input_len] = 0;
                    _ = w.InvalidateRect(hwnd, null, 0);
                }
            } else if (isValidFilenameChar(ch) and g_input_len < 60) {
                g_input_buf[g_input_len] = ch;
                g_input_len += 1;
                _ = w.InvalidateRect(hwnd, null, 0);
            }
            return 0;
        },
        w.WM_LBUTTONDOWN => {
            const x: i32 = @as(i16, @truncate(lParam));
            const y: i32 = @as(i16, @truncate(lParam >> 16));
            handleClick(hwnd, x, y);
            return 0;
        },
        w.WM_PAINT => {
            var ps: w.PAINTSTRUCT = undefined;
            const hdc = w.BeginPaint(hwnd, &ps) orelse return 0;
            defer _ = w.EndPaint(hwnd, &ps);

            var rc: w.RECT = undefined;
            _ = w.GetClientRect(hwnd, &rc);
            const width = rc.right - rc.left;
            const height = rc.bottom - rc.top;

            const mem_dc = w.CreateCompatibleDC(hdc) orelse return 0;
            defer _ = w.DeleteDC(mem_dc);
            const mem_bm = w.CreateCompatibleBitmap(hdc, width, height) orelse return 0;
            defer _ = w.DeleteObject(@ptrCast(mem_bm));
            const old_bm = w.SelectObject(mem_dc, @ptrCast(mem_bm));

            _ = w.SetBkMode(mem_dc, w.TRANSPARENT);
            drawRoundBox(mem_dc, rc, 12, COL_BG, COL_BORDER);

            if (g_mode == .paste) {
                paintPaste(mem_dc);
            } else if (g_mode == .settings) {
                paintSettings(mem_dc);
            }

            _ = w.BitBlt(hdc, 0, 0, width, height, mem_dc, 0, 0, w.SRCCOPY);
            if (old_bm) |ob| _ = w.SelectObject(mem_dc, ob);
            return 0;
        },
        else => return w.DefWindowProcW(hwnd, uMsg, wParam, lParam),
    }
}