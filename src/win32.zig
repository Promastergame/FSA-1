const std = @import("std");

pub fn L(comptime s: []const u8) *const [blk: {
    @setEvalBranchQuota(100_000);
    break :blk std.unicode.calcUtf16LeLen(s) catch unreachable;
}:0]u16 {
    @setEvalBranchQuota(100_000);
    return std.unicode.utf8ToUtf16LeStringLiteral(s);
}

pub const BOOL = i32;
pub const UINT = u32;
pub const DWORD = u32;
pub const WORD = u16;
pub const LONG = i32;
pub const WPARAM = usize;
pub const LPARAM = isize;
pub const LRESULT = isize;
pub const HRESULT = i32;

pub const HANDLE = *anyopaque;
pub const HWND = *opaque {};
pub const HINSTANCE = *opaque {};
pub const HMENU = *opaque {};
pub const HICON = *opaque {};
pub const HCURSOR = *opaque {};
pub const HBRUSH = *opaque {};
pub const HPEN = *opaque {};
pub const HFONT = *opaque {};
pub const HGDIOBJ = *opaque {};
pub const HDC = *opaque {};
pub const HBITMAP = *opaque {};
pub const HMONITOR = *opaque {};
pub const HHOOK = *opaque {};
pub const HKEY = *opaque {};
pub const GpBitmap = opaque {};
pub const GpImage = opaque {};
pub const GpGraphics = opaque {};
pub const GpBrush = opaque {};

pub const HKEY_CURRENT_USER: HKEY = @ptrFromInt(@as(usize, @bitCast(@as(isize, @as(i32, @bitCast(@as(u32, 0x80000001)))))));

pub const GUID = extern struct {
    Data1: u32,
    Data2: u16,
    Data3: u16,
    Data4: [8]u8,
};

pub const POINT = extern struct {
    x: LONG,
    y: LONG,
};

pub const RECT = extern struct {
    left: LONG,
    top: LONG,
    right: LONG,
    bottom: LONG,
};

pub const PAINTSTRUCT = extern struct {
    hdc: ?HDC,
    fErase: BOOL,
    rcPaint: RECT,
    fRestore: BOOL,
    fIncUpdate: BOOL,
    rgbReserved: [32]u8,
};

pub const MONITORINFO = extern struct {
    cbSize: DWORD = @sizeOf(MONITORINFO),
    rcMonitor: RECT = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    rcWork: RECT = .{ .left = 0, .top = 0, .right = 0, .bottom = 0 },
    dwFlags: DWORD = 0,
};

pub const MSG = extern struct {
    hwnd: ?HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
    lPrivate: DWORD,
};

pub const KBDLLHOOKSTRUCT = extern struct {
    vkCode: DWORD,
    scanCode: DWORD,
    flags: DWORD,
    time: DWORD,
    dwExtraInfo: usize,
};

pub const WNDPROC = *const fn (hwnd: HWND, uMsg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
pub const HOOKPROC = *const fn (code: i32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;

pub const WNDCLASSEXW = extern struct {
    cbSize: UINT = @sizeOf(WNDCLASSEXW),
    style: UINT = 0,
    lpfnWndProc: WNDPROC,
    cbClsExtra: i32 = 0,
    cbWndExtra: i32 = 0,
    hInstance: ?HINSTANCE,
    hIcon: ?HICON = null,
    hCursor: ?HCURSOR = null,
    hbrBackground: ?HBRUSH = null,
    lpszMenuName: ?[*:0]const u16 = null,
    lpszClassName: [*:0]const u16,
    hIconSm: ?HICON = null,
};

pub const GdiplusStartupInput = extern struct {
    GdiplusVersion: u32 = 1,
    DebugEventCallback: ?*anyopaque = null,
    SuppressBackgroundThread: BOOL = 0,
    SuppressExternalCodecs: BOOL = 0,
};

pub const ERROR_ALREADY_EXISTS: DWORD = 183;
pub const WH_KEYBOARD_LL: i32 = 13;
pub const HC_ACTION: i32 = 0;

pub const WM_ACTIVATE: UINT = 0x0006;
pub const WM_PAINT: UINT = 0x000F;
pub const WM_ERASEBKGND: UINT = 0x0014;
pub const WM_KEYDOWN: UINT = 0x0100;
pub const WM_KEYUP: UINT = 0x0101;
pub const WM_CHAR: UINT = 0x0102;
pub const WM_SYSKEYDOWN: UINT = 0x0104;
pub const WM_SYSKEYUP: UINT = 0x0105;
pub const WM_TIMER: UINT = 0x0113;
pub const WM_MOUSEMOVE: UINT = 0x0200;
pub const WM_LBUTTONDOWN: UINT = 0x0201;
pub const WM_APP: UINT = 0x8000;

pub const WM_APP_PASTE: UINT = WM_APP + 1;
pub const WM_APP_SETTINGS: UINT = WM_APP + 2;

pub const WA_INACTIVE: WPARAM = 0;

pub const VK_BACK: i32 = 0x08;
pub const VK_TAB: i32 = 0x09;
pub const VK_RETURN: i32 = 0x0D;
pub const VK_SHIFT: i32 = 0x10;
pub const VK_CONTROL: i32 = 0x11;
pub const VK_MENU: i32 = 0x12;
pub const VK_ESCAPE: i32 = 0x1B;
pub const VK_LEFT: i32 = 0x25;
pub const VK_RIGHT: i32 = 0x27;

pub const WS_POPUP: DWORD = 0x80000000;
pub const WS_EX_TOPMOST: DWORD = 0x00000008;
pub const WS_EX_TOOLWINDOW: DWORD = 0x00000080;

pub const SW_HIDE: i32 = 0;
pub const SW_SHOW: i32 = 5;

pub const CF_BITMAP: UINT = 2;
pub const CF_DIB: UINT = 8;

pub const IDC_ARROW: [*:0]const u16 = @ptrFromInt(32512);
pub const MONITOR_DEFAULTTONEAREST: DWORD = 2;
pub const TRANSPARENT: i32 = 1;
pub const PS_SOLID: i32 = 0;
pub const SRCCOPY: DWORD = 0x00CC0020;

pub const DT_LEFT: UINT = 0x00000000;
pub const DT_CENTER: UINT = 0x00000001;
pub const DT_RIGHT: UINT = 0x00000002;
pub const DT_VCENTER: UINT = 0x00000004;
pub const DT_SINGLELINE: UINT = 0x00000020;
pub const DT_NOPREFIX: UINT = 0x00000800;
pub const DT_END_ELLIPSIS: UINT = 0x00008000;
pub const DT_CALCRECT: UINT = 0x00000400;

pub const DWMWA_USE_IMMERSIVE_DARK_MODE: DWORD = 20;
pub const DWMWA_WINDOW_CORNER_PREFERENCE: DWORD = 33;
pub const DWMWCP_ROUND: DWORD = 2;

pub const COINIT_APARTMENTTHREADED: DWORD = 0x2;
pub const CLSCTX_ALL: DWORD = 23;

pub const REG_SZ: DWORD = 1;
pub const REG_DWORD: DWORD = 4;
pub const RRF_RT_REG_SZ: DWORD = 0x00000002;
pub const RRF_RT_REG_DWORD: DWORD = 0x00000010;
pub const KEY_WRITE: DWORD = 0x20006;

pub const SHCNE_CREATE: LONG = 0x00000002;
pub const SHCNF_PATHW: UINT = 0x0005;
pub const INVALID_FILE_ATTRIBUTES: DWORD = 0xFFFFFFFF;
pub const GENERIC_WRITE: DWORD = 0x40000000;
pub const CREATE_ALWAYS: DWORD = 2;
pub const FILE_ATTRIBUTE_NORMAL: DWORD = 0x80;
pub const INVALID_HANDLE_VALUE: HANDLE = @ptrFromInt(@as(usize, @bitCast(@as(isize, -1))));

// Kernel32
pub extern "kernel32" fn GetModuleHandleW(lpModuleName: ?[*:0]const u16) callconv(.winapi) ?HINSTANCE;
pub extern "kernel32" fn CreateMutexW(lpMutexAttributes: ?*anyopaque, bInitialOwner: BOOL, lpName: [*:0]const u16) callconv(.winapi) ?HANDLE;
pub extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
pub extern "kernel32" fn GetUserDefaultUILanguage() callconv(.winapi) WORD;
pub extern "kernel32" fn GetFileAttributesW(lpFileName: [*:0]const u16) callconv(.winapi) DWORD;
pub extern "kernel32" fn GetCurrentThreadId() callconv(.winapi) DWORD;
pub extern "kernel32" fn GetTickCount64() callconv(.winapi) u64;
pub extern "kernel32" fn GlobalLock(hMem: HANDLE) callconv(.winapi) ?*anyopaque;
pub extern "kernel32" fn GlobalUnlock(hMem: HANDLE) callconv(.winapi) BOOL;
pub extern "kernel32" fn GlobalSize(hMem: HANDLE) callconv(.winapi) usize;
pub extern "kernel32" fn CreateFileW(
    lpFileName: [*:0]const u16,
    dwDesiredAccess: DWORD,
    dwShareMode: DWORD,
    lpSecurityAttributes: ?*anyopaque,
    dwCreationDisposition: DWORD,
    dwFlagsAndAttributes: DWORD,
    hTemplateFile: ?HANDLE,
) callconv(.winapi) ?HANDLE;
pub extern "kernel32" fn WriteFile(
    hFile: HANDLE,
    lpBuffer: [*]const u8,
    nNumberOfBytesToWrite: DWORD,
    lpNumberOfBytesWritten: ?*DWORD,
    lpOverlapped: ?*anyopaque,
) callconv(.winapi) BOOL;
pub extern "kernel32" fn CloseHandle(hObject: HANDLE) callconv(.winapi) BOOL;

// User32
pub extern "user32" fn RegisterClassExW(lpWndClass: *const WNDCLASSEXW) callconv(.winapi) WORD;
pub extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: [*:0]const u16,
    lpWindowName: [*:0]const u16,
    dwStyle: DWORD,
    X: i32,
    Y: i32,
    nWidth: i32,
    nHeight: i32,
    hWndParent: ?HWND,
    hMenu: ?HMENU,
    hInstance: ?HINSTANCE,
    lpParam: ?*anyopaque,
) callconv(.winapi) ?HWND;
pub extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(.winapi) BOOL;
pub extern "user32" fn IsWindowVisible(hWnd: HWND) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowPos(hWnd: HWND, hWndInsertAfter: ?HWND, X: i32, Y: i32, cx: i32, cy: i32, uFlags: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn DefWindowProcW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
pub extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: ?HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) BOOL;
pub extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) LRESULT;
pub extern "user32" fn PostMessageW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) BOOL;
pub extern "user32" fn SetWindowsHookExW(idHook: i32, lpfn: HOOKPROC, hmod: ?HINSTANCE, dwThreadId: DWORD) callconv(.winapi) ?HHOOK;
pub extern "user32" fn UnhookWindowsHookEx(hhk: HHOOK) callconv(.winapi) BOOL;
pub extern "user32" fn CallNextHookEx(hhk: ?HHOOK, nCode: i32, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
pub extern "user32" fn GetAsyncKeyState(vKey: i32) callconv(.winapi) i16;
pub extern "user32" fn GetForegroundWindow() callconv(.winapi) ?HWND;
pub extern "user32" fn SetForegroundWindow(hWnd: HWND) callconv(.winapi) BOOL;
pub extern "user32" fn BringWindowToTop(hWnd: HWND) callconv(.winapi) BOOL;
pub extern "user32" fn SetFocus(hWnd: ?HWND) callconv(.winapi) ?HWND;
pub extern "user32" fn GetWindowThreadProcessId(hWnd: HWND, lpdwProcessId: ?*DWORD) callconv(.winapi) DWORD;
pub extern "user32" fn AttachThreadInput(idAttach: DWORD, idAttachTo: DWORD, fAttach: BOOL) callconv(.winapi) BOOL;
pub extern "user32" fn keybd_event(bVk: u8, bScan: u8, dwFlags: DWORD, dwExtraInfo: usize) callconv(.winapi) void;
pub extern "user32" fn GetParent(hWnd: HWND) callconv(.winapi) ?HWND;
pub extern "user32" fn GetClassNameW(hWnd: HWND, lpClassName: [*]u16, nMaxCount: i32) callconv(.winapi) i32;
pub extern "user32" fn FindWindowExW(hWndParent: ?HWND, hWndChildAfter: ?HWND, lpszClass: ?[*:0]const u16, lpszWindow: ?[*:0]const u16) callconv(.winapi) ?HWND;
pub extern "user32" fn GetCursorPos(lpPoint: *POINT) callconv(.winapi) BOOL;
pub extern "user32" fn MonitorFromPoint(pt: POINT, dwFlags: DWORD) callconv(.winapi) ?HMONITOR;
pub extern "user32" fn GetMonitorInfoW(hMonitor: HMONITOR, lpmi: *MONITORINFO) callconv(.winapi) BOOL;
pub extern "user32" fn LoadCursorW(hInstance: ?HINSTANCE, lpCursorName: [*:0]const u16) callconv(.winapi) ?HCURSOR;
pub extern "user32" fn IsClipboardFormatAvailable(format: UINT) callconv(.winapi) BOOL;
pub extern "user32" fn OpenClipboard(hWndNewOwner: ?HWND) callconv(.winapi) BOOL;
pub extern "user32" fn CloseClipboard() callconv(.winapi) BOOL;
pub extern "user32" fn GetClipboardData(uFormat: UINT) callconv(.winapi) ?HANDLE;
pub extern "user32" fn BeginPaint(hWnd: HWND, lpPaint: *PAINTSTRUCT) callconv(.winapi) ?HDC;
pub extern "user32" fn EndPaint(hWnd: HWND, lpPaint: *const PAINTSTRUCT) callconv(.winapi) BOOL;
pub extern "user32" fn InvalidateRect(hWnd: HWND, lpRect: ?*const RECT, bErase: BOOL) callconv(.winapi) BOOL;
pub extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) BOOL;
pub extern "user32" fn FillRect(hDC: HDC, lprc: *const RECT, hbr: HBRUSH) callconv(.winapi) i32;
pub extern "user32" fn DrawTextW(hdc: HDC, lpchText: [*]const u16, cchText: i32, lprc: *RECT, format: UINT) callconv(.winapi) i32;
pub extern "user32" fn RegisterClipboardFormatW(lpszFormat: [*:0]const u16) callconv(.winapi) UINT;
pub extern "user32" fn SetTimer(hWnd: ?HWND, nIDEvent: usize, uElapse: UINT, lpTimerFunc: ?*const anyopaque) callconv(.winapi) usize;
pub extern "user32" fn KillTimer(hWnd: ?HWND, uIDEvent: usize) callconv(.winapi) BOOL;

// Gdi32
pub extern "gdi32" fn CreateSolidBrush(color: DWORD) callconv(.winapi) ?HBRUSH;
pub extern "gdi32" fn CreatePen(iStyle: i32, cWidth: i32, color: DWORD) callconv(.winapi) ?HPEN;
pub extern "gdi32" fn CreateFontW(
    cHeight: i32,
    cWidth: i32,
    cEscapement: i32,
    cOrientation: i32,
    cWeight: i32,
    bItalic: DWORD,
    bUnderline: DWORD,
    bStrikeOut: DWORD,
    iCharSet: DWORD,
    iOutPrecision: DWORD,
    iClipPrecision: DWORD,
    iQuality: DWORD,
    iPitchAndFamily: DWORD,
    pszFaceName: [*:0]const u16,
) callconv(.winapi) ?HFONT;
pub extern "gdi32" fn CreateCompatibleDC(hdc: ?HDC) callconv(.winapi) ?HDC;
pub extern "gdi32" fn DeleteDC(hdc: HDC) callconv(.winapi) BOOL;
pub extern "gdi32" fn CreateCompatibleBitmap(hdc: HDC, cx: i32, cy: i32) callconv(.winapi) ?HBITMAP;
pub extern "gdi32" fn SelectObject(hdc: HDC, h: HGDIOBJ) callconv(.winapi) ?HGDIOBJ;
pub extern "gdi32" fn DeleteObject(ho: HGDIOBJ) callconv(.winapi) BOOL;
pub extern "gdi32" fn BitBlt(hdc: HDC, x: i32, y: i32, cx: i32, cy: i32, hdcSrc: ?HDC, x1: i32, y1: i32, rop: DWORD) callconv(.winapi) BOOL;
pub extern "gdi32" fn RoundRect(hdc: HDC, left: i32, top: i32, right: i32, bottom: i32, width: i32, height: i32) callconv(.winapi) BOOL;
pub extern "gdi32" fn SetTextColor(hdc: HDC, color: DWORD) callconv(.winapi) DWORD;
pub extern "gdi32" fn SetBkMode(hdc: HDC, mode: i32) callconv(.winapi) i32;

// Gdiplus
pub extern "gdiplus" fn GdiplusStartup(token: *usize, input: *const GdiplusStartupInput, output: ?*anyopaque) callconv(.winapi) i32;
pub extern "gdiplus" fn GdiplusShutdown(token: usize) callconv(.winapi) void;
pub extern "gdiplus" fn GdipCreateBitmapFromHBITMAP(hbm: HBITMAP, hpal: ?HANDLE, bitmap: *?*GpBitmap) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipSaveImageToFile(image: *GpImage, filename: [*:0]const u16, clsidEncoder: *const GUID, encoderParams: ?*const anyopaque) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipDisposeImage(image: *GpImage) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipCreateFromHDC(hdc: HDC, graphics: *?*GpGraphics) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipDeleteGraphics(graphics: *GpGraphics) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipSetSmoothingMode(graphics: *GpGraphics, smoothingMode: i32) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipCreateSolidFill(color: DWORD, brush: *?*GpBrush) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipDeleteBrush(brush: *GpBrush) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipFillEllipseI(graphics: *GpGraphics, brush: *GpBrush, x: i32, y: i32, width: i32, height: i32) callconv(.winapi) i32;
pub extern "gdiplus" fn GdipFillRectangleI(graphics: *GpGraphics, brush: *GpBrush, x: i32, y: i32, width: i32, height: i32) callconv(.winapi) i32;

// Dwmapi
pub extern "dwmapi" fn DwmSetWindowAttribute(hwnd: HWND, dwAttribute: DWORD, pvAttribute: *const anyopaque, cbAttribute: DWORD) callconv(.winapi) HRESULT;

// Shell32 & Ole32
pub extern "ole32" fn CoInitializeEx(pvReserved: ?*anyopaque, dwCoInit: DWORD) callconv(.winapi) HRESULT;
pub extern "ole32" fn CoUninitialize() callconv(.winapi) void;
pub extern "ole32" fn CoCreateInstance(rclsid: *const GUID, pUnkOuter: ?*anyopaque, dwClsContext: DWORD, riid: *const GUID, ppv: *?*anyopaque) callconv(.winapi) HRESULT;
pub extern "ole32" fn CoTaskMemFree(pv: ?*anyopaque) callconv(.winapi) void;
pub extern "shell32" fn SHGetKnownFolderPath(rfid: *const GUID, dwFlags: DWORD, hToken: ?HANDLE, ppszPath: *?[*:0]u16) callconv(.winapi) HRESULT;
pub extern "shell32" fn SHGetPathFromIDListW(pidl: *const anyopaque, pszPath: [*]u16) callconv(.winapi) BOOL;
pub extern "shell32" fn SHChangeNotify(wEventId: LONG, uFlags: UINT, dwItem1: ?*const anyopaque, dwItem2: ?*const anyopaque) callconv(.winapi) void;

// Advapi32
pub extern "advapi32" fn RegCreateKeyExW(
    hKey: HKEY,
    lpSubKey: [*:0]const u16,
    Reserved: DWORD,
    lpClass: ?[*:0]const u16,
    dwOptions: DWORD,
    samDesired: DWORD,
    lpSecurityAttributes: ?*anyopaque,
    phkResult: *HKEY,
    lpdwDisposition: ?*DWORD,
) callconv(.winapi) LONG;
pub extern "advapi32" fn RegSetValueExW(
    hKey: HKEY,
    lpValueName: [*:0]const u16,
    Reserved: DWORD,
    dwType: DWORD,
    lpData: [*]const u8,
    cbData: DWORD,
) callconv(.winapi) LONG;
pub extern "advapi32" fn RegGetValueW(
    hkey: HKEY,
    lpSubKey: ?[*:0]const u16,
    lpValue: ?[*:0]const u16,
    dwFlags: DWORD,
    pdwType: ?*DWORD,
    pvData: ?*anyopaque,
    pcbData: ?*DWORD,
) callconv(.winapi) LONG;
pub extern "advapi32" fn RegCloseKey(hKey: HKEY) callconv(.winapi) LONG;