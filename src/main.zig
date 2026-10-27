const std = @import("std");
const w = @import("win32.zig");
const explorer = @import("explorer.zig");
const clipboard = @import("clipboard.zig");
const ui = @import("ui.zig");
const L = w.L;

var g_hook: ?w.HHOOK = null;
var g_msg_hwnd: ?w.HWND = null;
var g_tab_held: bool = false;

fn keyboardHookProc(code: i32, wParam: w.WPARAM, lParam: w.LPARAM) callconv(.winapi) w.LRESULT {
    if (code == w.HC_ACTION) {
        const kbd: *const w.KBDLLHOOKSTRUCT = @ptrFromInt(@as(usize, @bitCast(lParam)));
        const is_down = (wParam == w.WM_KEYDOWN or wParam == w.WM_SYSKEYDOWN);
        const is_up = (wParam == w.WM_KEYUP or wParam == w.WM_SYSKEYUP);

        if (kbd.vkCode == w.VK_TAB) {
            if (is_down) g_tab_held = true;
            if (is_up) g_tab_held = false;
        }

        if (is_down) {
            const tab_phys = (w.GetAsyncKeyState(w.VK_TAB) < 0);
            if (!tab_phys) g_tab_held = false;
            const ctrl = (w.GetAsyncKeyState(w.VK_CONTROL) < 0);
            const alt = (w.GetAsyncKeyState(w.VK_MENU) < 0);
            const shift = (w.GetAsyncKeyState(w.VK_SHIFT) < 0);

            if (kbd.vkCode == '1' and tab_phys and !ctrl and !alt and !shift) {
                if (g_msg_hwnd) |hwnd| {
                    _ = w.PostMessageW(hwnd, w.WM_APP_SETTINGS, 0, 0);
                    return 1;
                }
            }

            if (kbd.vkCode == 'V') {
                if (ctrl and !shift and !alt and clipboard.hasImage()) {
                    if (w.GetForegroundWindow()) |fg| {
                        if (explorer.classifyWindow(fg) != .none) {
                            if (g_msg_hwnd) |hwnd| {
                                _ = w.PostMessageW(hwnd, w.WM_APP_PASTE, @intFromPtr(fg), 0);
                                return 1;
                            }
                        }
                    }
                }
            }
        }
    }
    return w.CallNextHookEx(g_hook, code, wParam, lParam);
}

fn msgWndProc(hwnd: w.HWND, uMsg: w.UINT, wParam: w.WPARAM, lParam: w.LPARAM) callconv(.winapi) w.LRESULT {
    switch (uMsg) {
        w.WM_APP_PASTE => {
            if (wParam != 0) {
                const fg: w.HWND = @ptrFromInt(wParam);
                ui.triggerPaste(fg);
            }
            return 0;
        },
        w.WM_APP_SETTINGS => {
            ui.triggerSettings();
            return 0;
        },
        else => return w.DefWindowProcW(hwnd, uMsg, wParam, lParam),
    }
}

pub fn main() void {
    const mutex = w.CreateMutexW(null, 1, L("Local\\FSA1_Instance"));
    if (mutex == null or w.GetLastError() == w.ERROR_ALREADY_EXISTS) return;

    _ = w.CoInitializeEx(null, w.COINIT_APARTMENTTHREADED);
    defer w.CoUninitialize();

    var gdi_token: usize = 0;
    const gdi_in = w.GdiplusStartupInput{};
    if (w.GdiplusStartup(&gdi_token, &gdi_in, null) != 0) return;
    defer w.GdiplusShutdown(gdi_token);

    const hinst = w.GetModuleHandleW(null) orelse return;

    const wc = w.WNDCLASSEXW{
        .lpfnWndProc = msgWndProc,
        .hInstance = hinst,
        .lpszClassName = L("FSA1_MsgHost"),
    };
    _ = w.RegisterClassExW(&wc);

    g_msg_hwnd = w.CreateWindowExW(0, L("FSA1_MsgHost"), L(""), 0, 0, 0, 0, 0, null, null, hinst, null);
    if (g_msg_hwnd == null) return;

    ui.init(hinst);

    g_hook = w.SetWindowsHookExW(w.WH_KEYBOARD_LL, keyboardHookProc, hinst, 0);
    if (g_hook == null) return;
    defer _ = w.UnhookWindowsHookEx(g_hook.?);

    var msg: w.MSG = undefined;
    while (w.GetMessageW(&msg, null, 0, 0) > 0) {
        _ = w.TranslateMessage(&msg);
        _ = w.DispatchMessageW(&msg);
    }
}