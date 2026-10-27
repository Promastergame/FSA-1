const std = @import("std");
const w = @import("win32.zig");
const L = w.L;

const FOLDERID_Desktop = w.GUID{
    .Data1 = 0xB4BFCC3A,
    .Data2 = 0xDB2C,
    .Data3 = 0x424C,
    .Data4 = .{ 0xB0, 0x29, 0x7F, 0xE9, 0x9A, 0x87, 0xC6, 0x41 },
};

const CLSID_ShellWindows = w.GUID{
    .Data1 = 0x9BA05972,
    .Data2 = 0xF6A8,
    .Data3 = 0x11CF,
    .Data4 = .{ 0xA4, 0x42, 0x00, 0xA0, 0xC9, 0x0A, 0x8F, 0x39 },
};

const IID_IShellWindows = w.GUID{
    .Data1 = 0x85CB6900,
    .Data2 = 0x4D95,
    .Data3 = 0x11CF,
    .Data4 = .{ 0x96, 0x0C, 0x00, 0x80, 0xC7, 0xF4, 0xEE, 0x85 },
};

const IID_IServiceProvider = w.GUID{
    .Data1 = 0x6D5140C1,
    .Data2 = 0x7436,
    .Data3 = 0x11CE,
    .Data4 = .{ 0x80, 0x34, 0x00, 0xAA, 0x00, 0x60, 0x09, 0xFA },
};

const SID_STopLevelBrowser = w.GUID{
    .Data1 = 0x4C96BE40,
    .Data2 = 0x915C,
    .Data3 = 0x11CF,
    .Data4 = .{ 0x99, 0xD3, 0x00, 0xAA, 0x00, 0x4A, 0xE8, 0x37 },
};

const IID_IShellBrowser = w.GUID{
    .Data1 = 0x000214E2,
    .Data2 = 0x0000,
    .Data3 = 0x0000,
    .Data4 = .{ 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x46 },
};

const IID_IFolderView = w.GUID{
    .Data1 = 0xCDE725B0,
    .Data2 = 0xCCC9,
    .Data3 = 0x4519,
    .Data4 = .{ 0x91, 0x7E, 0x32, 0x5D, 0x72, 0xFA, 0xB4, 0xCE },
};

const IID_IPersistFolder2 = w.GUID{
    .Data1 = 0x1AC3D9F0,
    .Data2 = 0x175C,
    .Data3 = 0x11D1,
    .Data4 = .{ 0x95, 0xBE, 0x00, 0x60, 0x97, 0x97, 0xEA, 0x4F },
};

const VARIANT = extern struct {
    vt: u16 = 3, // VT_I4
    wReserved1: u16 = 0,
    wReserved2: u16 = 0,
    wReserved3: u16 = 0,
    lVal: i32 = 0,
    pad1: i32 = 0,
    pad2: u64 = 0,
};

const IUnknown = extern struct {
    lpVtbl: *const extern struct {
        QueryInterface: *const fn (self: *anyopaque, riid: *const w.GUID, ppv: *?*anyopaque) callconv(.winapi) w.HRESULT,
        AddRef: *const fn (self: *anyopaque) callconv(.winapi) u32,
        Release: *const fn (self: *anyopaque) callconv(.winapi) u32,
    },
};

const IShellWindows = extern struct {
    lpVtbl: *const extern struct {
        QueryInterface: *const anyopaque,
        AddRef: *const anyopaque,
        Release: *const fn (self: *IShellWindows) callconv(.winapi) u32,
        GetTypeInfoCount: *const anyopaque,
        GetTypeInfo: *const anyopaque,
        GetIDsOfNames: *const anyopaque,
        Invoke: *const anyopaque,
        get_Count: *const fn (self: *IShellWindows, count: *i32) callconv(.winapi) w.HRESULT,
        Item: *const fn (self: *IShellWindows, index: VARIANT, folder: *?*IUnknown) callconv(.winapi) w.HRESULT,
    },
};

const IServiceProvider = extern struct {
    lpVtbl: *const extern struct {
        QueryInterface: *const anyopaque,
        AddRef: *const anyopaque,
        Release: *const fn (self: *IServiceProvider) callconv(.winapi) u32,
        QueryService: *const fn (self: *IServiceProvider, guidService: *const w.GUID, riid: *const w.GUID, ppv: *?*anyopaque) callconv(.winapi) w.HRESULT,
    },
};

const IShellBrowser = extern struct {
    lpVtbl: *const extern struct {
        QueryInterface: *const anyopaque,
        AddRef: *const anyopaque,
        Release: *const fn (self: *IShellBrowser) callconv(.winapi) u32,
        GetWindow: *const fn (self: *IShellBrowser, phwnd: *?w.HWND) callconv(.winapi) w.HRESULT,
        ContextSensitiveHelp: *const anyopaque,
        InsertMenusSB: *const anyopaque,
        SetMenuSB: *const anyopaque,
        RemoveMenusSB: *const anyopaque,
        SetStatusTextSB: *const anyopaque,
        EnableModelessSB: *const anyopaque,
        TranslateAcceleratorSB: *const anyopaque,
        BrowseObject: *const anyopaque,
        GetViewStateStream: *const anyopaque,
        GetControlWindow: *const anyopaque,
        SendControlMsg: *const anyopaque,
        QueryActiveShellView: *const fn (self: *IShellBrowser, ppshv: *?*IUnknown) callconv(.winapi) w.HRESULT,
    },
};

const IFolderView = extern struct {
    lpVtbl: *const extern struct {
        QueryInterface: *const anyopaque,
        AddRef: *const anyopaque,
        Release: *const fn (self: *IFolderView) callconv(.winapi) u32,
        GetCurrentViewMode: *const anyopaque,
        SetCurrentViewMode: *const anyopaque,
        GetFolder: *const fn (self: *IFolderView, riid: *const w.GUID, ppv: *?*anyopaque) callconv(.winapi) w.HRESULT,
    },
};

const IPersistFolder2 = extern struct {
    lpVtbl: *const extern struct {
        QueryInterface: *const anyopaque,
        AddRef: *const anyopaque,
        Release: *const fn (self: *IPersistFolder2) callconv(.winapi) u32,
        GetClassID: *const anyopaque,
        Initialize: *const anyopaque,
        GetCurFolder: *const fn (self: *IPersistFolder2, ppidl: *?*anyopaque) callconv(.winapi) w.HRESULT,
    },
};

pub const TargetKind = enum {
    none,
    desktop,
    explorer,
};

pub fn classifyWindow(hwnd: w.HWND) TargetKind {
    var cls: [64]u16 = @splat(0);
    const len = w.GetClassNameW(hwnd, &cls, 63);
    if (len <= 0) return .none;
    const name = cls[0..@intCast(len)];

    if (std.mem.eql(u16, name, L("Progman")) or std.mem.eql(u16, name, L("WorkerW"))) {
        return .desktop;
    }
    if (std.mem.eql(u16, name, L("CabinetWClass")) or std.mem.eql(u16, name, L("ExploreWClass"))) {
        return .explorer;
    }
    return .none;
}

pub fn resolveTargetFolder(hwnd: w.HWND, out_buf: *[260]u16) ?[]const u16 {
    return switch (classifyWindow(hwnd)) {
        .none => null,
        .desktop => getDesktopPath(out_buf),
        .explorer => getExplorerPath(hwnd, out_buf),
    };
}

fn getDesktopPath(out_buf: *[260]u16) ?[]const u16 {
    var ptr: ?[*:0]u16 = null;
    if (w.SHGetKnownFolderPath(&FOLDERID_Desktop, 0, null, &ptr) != 0) return null;
    defer w.CoTaskMemFree(ptr);

    if (ptr) |p| {
        const slice = std.mem.span(p);
        if (slice.len > 0 and slice.len < 259) {
            out_buf.* = @splat(0);
            @memcpy(out_buf[0..slice.len], slice);
            return out_buf[0..slice.len];
        }
    }
    return null;
}

fn findActiveTab(fg_hwnd: w.HWND) ?w.HWND {
    var child: ?w.HWND = null;
    while (true) {
        child = w.FindWindowExW(fg_hwnd, child, L("ShellTabWindowClass"), null);
        if (child == null) break;
        if (w.IsWindowVisible(child.?) != 0) return child;
    }
    return null;
}

fn getExplorerPath(fg_hwnd: w.HWND, out_buf: *[260]u16) ?[]const u16 {
    const active_tab = findActiveTab(fg_hwnd);

    var psw_raw: ?*anyopaque = null;
    if (w.CoCreateInstance(&CLSID_ShellWindows, null, w.CLSCTX_ALL, &IID_IShellWindows, &psw_raw) != 0 or psw_raw == null) return null;
    const psw: *IShellWindows = @ptrCast(@alignCast(psw_raw.?));
    defer _ = psw.lpVtbl.Release(psw);

    var count: i32 = 0;
    if (psw.lpVtbl.get_Count(psw, &count) != 0 or count <= 0) return null;

    var i: i32 = 0;
    while (i < count) : (i += 1) {
        var disp: ?*IUnknown = null;
        if (psw.lpVtbl.Item(psw, .{ .lVal = i }, &disp) != 0 or disp == null) continue;
        defer _ = disp.?.lpVtbl.Release(disp.?);

        var isp_raw: ?*anyopaque = null;
        if (disp.?.lpVtbl.QueryInterface(disp.?, &IID_IServiceProvider, &isp_raw) != 0 or isp_raw == null) continue;
        const isp: *IServiceProvider = @ptrCast(@alignCast(isp_raw.?));
        defer _ = isp.lpVtbl.Release(isp);

        var isb_raw: ?*anyopaque = null;
        if (isp.lpVtbl.QueryService(isp, &SID_STopLevelBrowser, &IID_IShellBrowser, &isb_raw) != 0 or isb_raw == null) continue;
        const isb: *IShellBrowser = @ptrCast(@alignCast(isb_raw.?));
        defer _ = isb.lpVtbl.Release(isb);

        var browser_hwnd: ?w.HWND = null;
        if (isb.lpVtbl.GetWindow(isb, &browser_hwnd) != 0 or browser_hwnd == null) continue;

        const match = if (active_tab) |tab|
            (browser_hwnd.? == tab or browser_hwnd.? == fg_hwnd)
        else
            (browser_hwnd.? == fg_hwnd or w.GetParent(browser_hwnd.?) == fg_hwnd);
        if (!match) continue;

        var isv: ?*IUnknown = null;
        if (isb.lpVtbl.QueryActiveShellView(isb, &isv) != 0 or isv == null) continue;
        defer _ = isv.?.lpVtbl.Release(isv.?);

        var ifv_raw: ?*anyopaque = null;
        if (isv.?.lpVtbl.QueryInterface(isv.?, &IID_IFolderView, &ifv_raw) != 0 or ifv_raw == null) continue;
        const ifv: *IFolderView = @ptrCast(@alignCast(ifv_raw.?));
        defer _ = ifv.lpVtbl.Release(ifv);

        var ipf_raw: ?*anyopaque = null;
        if (ifv.lpVtbl.GetFolder(ifv, &IID_IPersistFolder2, &ipf_raw) != 0 or ipf_raw == null) continue;
        const ipf: *IPersistFolder2 = @ptrCast(@alignCast(ipf_raw.?));
        defer _ = ipf.lpVtbl.Release(ipf);

        var pidl: ?*anyopaque = null;
        if (ipf.lpVtbl.GetCurFolder(ipf, &pidl) == 0 and pidl != null) {
            defer w.CoTaskMemFree(pidl);
            out_buf.* = @splat(0);
            if (w.SHGetPathFromIDListW(pidl.?, out_buf) != 0) {
                const len = std.mem.indexOfScalar(u16, out_buf, 0) orelse 0;
                if (len > 0) return out_buf[0..len];
            }
        }
    }
    return null;
}