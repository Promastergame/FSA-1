const std = @import("std");
const w = @import("win32.zig");
const config = @import("config.zig");
const L = w.L;

const CLSID_PNG = w.GUID{ .Data1 = 0x557CF406, .Data2 = 0x1A04, .Data3 = 0x11D3, .Data4 = .{ 0x9A, 0x73, 0x00, 0x00, 0xF8, 0x1E, 0xF3, 0x2E } };
const CLSID_JPEG = w.GUID{ .Data1 = 0x557CF401, .Data2 = 0x1A04, .Data3 = 0x11D3, .Data4 = .{ 0x9A, 0x73, 0x00, 0x00, 0xF8, 0x1E, 0xF3, 0x2E } };
const CLSID_BMP = w.GUID{ .Data1 = 0x557CF400, .Data2 = 0x1A04, .Data3 = 0x11D3, .Data4 = .{ 0x9A, 0x73, 0x00, 0x00, 0xF8, 0x1E, 0xF3, 0x2E } };
const CLSID_TIFF = w.GUID{ .Data1 = 0x557CF405, .Data2 = 0x1A04, .Data3 = 0x11D3, .Data4 = .{ 0x9A, 0x73, 0x00, 0x00, 0xF8, 0x1E, 0xF3, 0x2E } };

const EncoderParameter = extern struct {
    Guid: w.GUID,
    NumberOfValues: w.DWORD,
    Type: w.DWORD,
    Value: *const anyopaque,
};

const EncoderParameters = extern struct {
    Count: w.UINT,
    Parameter: [1]EncoderParameter,
};

const ENC_QUALITY_GUID = w.GUID{
    .Data1 = 0x1D5BE4B5,
    .Data2 = 0xFA4A,
    .Data3 = 0x452D,
    .Data4 = .{ 0x9C, 0xDD, 0x5D, 0xB3, 0x51, 0x05, 0xE7, 0xEB },
};

pub fn hasImage() bool {
    return w.IsClipboardFormatAvailable(w.CF_BITMAP) != 0 or w.IsClipboardFormatAvailable(w.CF_DIB) != 0;
}

pub fn detectImageFormat(fallback: config.Format) config.Format {
    const cf_html = w.RegisterClipboardFormatW(L("HTML Format"));
    const cf_jfif = w.RegisterClipboardFormatW(L("JFIF"));
    const cf_mime_jpg = w.RegisterClipboardFormatW(L("image/jpeg"));

    if (w.OpenClipboard(null) == 0) return fallback;
    defer _ = w.CloseClipboard();

    if (cf_html != 0 and w.IsClipboardFormatAvailable(cf_html) != 0) {
        if (w.GetClipboardData(cf_html)) |hdata| {
            const sz = w.GlobalSize(hdata);
            if (sz > 0 and sz < 1024 * 1024) {
                if (w.GlobalLock(hdata)) |ptr| {
                    defer _ = w.GlobalUnlock(hdata);
                    const bytes: [*]const u8 = @ptrCast(ptr);
                    const len = std.mem.indexOfScalar(u8, bytes[0..sz], 0) orelse sz;
                    if (parseFormatFromHtml(bytes[0..len])) |fmt| {
                        return fmt;
                    }
                }
            }
        }
    }

    if ((cf_jfif != 0 and w.IsClipboardFormatAvailable(cf_jfif) != 0) or
        (cf_mime_jpg != 0 and w.IsClipboardFormatAvailable(cf_mime_jpg) != 0))
    {
        return .jpeg;
    }

    return fallback;
}

fn detectFormatFromText(text: []const u8) ?config.Format {
    if (std.mem.indexOf(u8, text, "image/jpeg") != null or
        std.mem.indexOf(u8, text, "image/jpg") != null or
        std.mem.indexOf(u8, text, "format=jpg") != null or
        std.mem.indexOf(u8, text, "format=jpeg") != null or
        std.mem.indexOf(u8, text, "fm=jpg") != null or
        std.mem.indexOf(u8, text, "fm=jpeg") != null)
    {
        return .jpeg;
    }

    if (std.mem.indexOf(u8, text, "image/png") != null or
        std.mem.indexOf(u8, text, "format=png") != null or
        std.mem.indexOf(u8, text, "fm=png") != null)
    {
        return .png;
    }

    var i: usize = 0;
    while (i < text.len) : (i += 1) {
        const sub = text[i..];
        if (std.ascii.startsWithIgnoreCase(sub, ".jpg") or
            std.ascii.startsWithIgnoreCase(sub, ".jpeg") or
            std.ascii.startsWithIgnoreCase(sub, ".jfif") or
            std.ascii.startsWithIgnoreCase(sub, "%2ejpg") or
            std.ascii.startsWithIgnoreCase(sub, "%2ejpeg"))
        {
            const is_jpeg = std.ascii.startsWithIgnoreCase(sub, ".jpeg") or std.ascii.startsWithIgnoreCase(sub, "%2ejpeg");
            const is_pct = std.ascii.startsWithIgnoreCase(sub, "%2e");
            const ext_len: usize = if (is_jpeg) 5 else 4;
            const skip: usize = if (is_pct) ext_len + 2 else ext_len;
            if (sub.len == skip or !std.ascii.isAlphanumeric(sub[skip])) {
                return .jpeg;
            }
        }

        if (std.ascii.startsWithIgnoreCase(sub, ".png") or
            std.ascii.startsWithIgnoreCase(sub, "%2epng"))
        {
            const is_pct = std.ascii.startsWithIgnoreCase(sub, "%2e");
            const skip: usize = if (is_pct) 6 else 4;
            if (sub.len == skip or !std.ascii.isAlphanumeric(sub[skip])) {
                return .png;
            }
        }

        if (std.ascii.startsWithIgnoreCase(sub, ".bmp") or
            std.ascii.startsWithIgnoreCase(sub, "%2ebmp"))
        {
            return .bmp;
        }

        if (std.ascii.startsWithIgnoreCase(sub, ".tif") or
            std.ascii.startsWithIgnoreCase(sub, ".tiff"))
        {
            return .tiff;
        }
    }

    return null;
}

fn extractImgSrc(html: []const u8) ?[]const u8 {
    var search_slice = html;
    if (std.mem.indexOf(u8, html, "<img") orelse std.mem.indexOf(u8, html, "<IMG")) |img_pos| {
        search_slice = html[img_pos..];
    }
    if (std.mem.indexOf(u8, search_slice, "src=\"") orelse std.mem.indexOf(u8, search_slice, "SRC=\"")) |src_pos| {
        const rest = search_slice[src_pos + 5 ..];
        const end = std.mem.indexOfScalar(u8, rest, '"') orelse rest.len;
        return rest[0..end];
    } else if (std.mem.indexOf(u8, search_slice, "src='") orelse std.mem.indexOf(u8, search_slice, "SRC='")) |src_pos| {
        const rest = search_slice[src_pos + 5 ..];
        const end = std.mem.indexOfScalar(u8, rest, '\'') orelse rest.len;
        return rest[0..end];
    }
    return null;
}

fn parseFormatFromHtml(html: []const u8) ?config.Format {
    if (std.mem.indexOf(u8, html, "SourceURL:")) |url_pos| {
        const rest = html[url_pos + 10 ..];
        const end = std.mem.indexOfAny(u8, rest, "\r\n") orelse rest.len;
        if (detectFormatFromText(rest[0..end])) |fmt| return fmt;
    }

    if (extractImgSrc(html)) |src| {
        if (detectFormatFromText(src)) |fmt| return fmt;
    }

    var search_slice = html;
    if (std.mem.indexOf(u8, html, "<img") orelse std.mem.indexOf(u8, html, "<IMG")) |img_pos| {
        search_slice = html[img_pos..];
    }

    if (std.mem.indexOf(u8, search_slice, "alt=\"") orelse std.mem.indexOf(u8, search_slice, "ALT=\"")) |alt_pos| {
        const rest = search_slice[alt_pos + 5 ..];
        const end = std.mem.indexOfScalar(u8, rest, '"') orelse rest.len;
        if (detectFormatFromText(rest[0..end])) |fmt| return fmt;
    }

    return detectFormatFromText(html);
}

fn writeBufferToFile(path: [*:0]const u16, buf: []const u8) bool {
    const hfile = w.CreateFileW(
        path,
        w.GENERIC_WRITE,
        0,
        null,
        w.CREATE_ALWAYS,
        w.FILE_ATTRIBUTE_NORMAL,
        null,
    ) orelse return false;
    if (hfile == w.INVALID_HANDLE_VALUE) return false;
    defer _ = w.CloseHandle(hfile);

    var written: w.DWORD = 0;
    const ok = w.WriteFile(hfile, buf.ptr, @intCast(buf.len), &written, null);
    return (ok != 0 and written == buf.len);
}

pub fn saveClipboardImage(
    dir_utf16: []const u16,
    custom_name_utf16: []const u16,
    cfg: *const config.Config,
    fmt: config.Format,
) bool {
    var full_path: [520]u16 = @splat(0);
    if (!buildTargetPath(&full_path, null, dir_utf16, custom_name_utf16, cfg, fmt)) return false;

    if (w.OpenClipboard(null) == 0) return false;
    defer _ = w.CloseClipboard();

    const cf_png = w.RegisterClipboardFormatW(L("PNG"));
    if (fmt == .png and cf_png != 0 and w.IsClipboardFormatAvailable(cf_png) != 0) {
        if (w.GetClipboardData(cf_png)) |hdata| {
            const sz = w.GlobalSize(hdata);
            if (sz > 8) {
                if (w.GlobalLock(hdata)) |ptr| {
                    defer _ = w.GlobalUnlock(hdata);
                    const bytes: [*]const u8 = @ptrCast(ptr);
                    if (std.mem.startsWith(u8, bytes[0..8], "\x89PNG\r\n\x1a\n")) {
                        if (writeBufferToFile(@ptrCast(&full_path), bytes[0..sz])) {
                            w.SHChangeNotify(w.SHCNE_CREATE, w.SHCNF_PATHW, &full_path, null);
                            return true;
                        }
                    }
                }
            }
        }
    }

    const hbm_raw = w.GetClipboardData(w.CF_BITMAP) orelse return false;
    const hbm: w.HBITMAP = @ptrCast(hbm_raw);

    var gp_bmp: ?*w.GpBitmap = null;
    if (w.GdipCreateBitmapFromHBITMAP(hbm, null, &gp_bmp) != 0 or gp_bmp == null) return false;
    defer _ = w.GdipDisposeImage(@ptrCast(gp_bmp.?));

    const clsid = switch (fmt) {
        .png => &CLSID_PNG,
        .jpeg => &CLSID_JPEG,
        .bmp => &CLSID_BMP,
        .tiff => &CLSID_TIFF,
    };

    var quality: w.DWORD = 95;
    const enc_params = EncoderParameters{
        .Count = 1,
        .Parameter = .{
            EncoderParameter{
                .Guid = ENC_QUALITY_GUID,
                .NumberOfValues = 1,
                .Type = 4,
                .Value = &quality,
            },
        },
    };
    const p_params: ?*const anyopaque = if (fmt == .jpeg) @ptrCast(&enc_params) else null;

    const status = w.GdipSaveImageToFile(@ptrCast(gp_bmp.?), @ptrCast(&full_path), clsid, p_params);
    if (status == 0) {
        w.SHChangeNotify(w.SHCNE_CREATE, w.SHCNF_PATHW, &full_path, null);
        return true;
    }
    return false;
}

pub fn getAutoStemPreview(
    out_stem: *[128]u16,
    dir: []const u16,
    cfg: *const config.Config,
    fmt: config.Format,
) usize {
    var dummy_path: [520]u16 = @splat(0);
    var stem_len: usize = 0;
    _ = buildTargetPath(&dummy_path, &stem_len, dir, &.{}, cfg, fmt);
    if (stem_len > 0 and stem_len < 128) {
        var slash_pos: usize = 0;
        for (dummy_path[0..], 0..) |ch, i| {
            if (ch == 0) break;
            if (ch == '\\') slash_pos = i + 1;
        }
        out_stem.* = @splat(0);
        @memcpy(out_stem[0..stem_len], dummy_path[slash_pos .. slash_pos + stem_len]);
        return stem_len;
    }
    return 0;
}

fn buildTargetPath(
    out: *[520]u16,
    out_stem_len: ?*usize,
    dir: []const u16,
    custom_name: []const u16,
    cfg: *const config.Config,
    fmt: config.Format,
) bool {
    if (dir.len == 0 or dir.len > 400) return false;
    const ext_ascii = fmt.ext();

    if (custom_name.len > 0) {
        var pos: usize = 0;
        @memcpy(out[pos .. pos + dir.len], dir);
        pos += dir.len;
        if (out[pos - 1] != '\\') {
            out[pos] = '\\';
            pos += 1;
        }
        @memcpy(out[pos .. pos + custom_name.len], custom_name);
        pos += custom_name.len;
        if (out_stem_len) |sl| sl.* = custom_name.len;
        for (ext_ascii) |c| {
            out[pos] = c;
            pos += 1;
        }
        out[pos] = 0;
        return true;
    }

    const tpl = cfg.template[0..cfg.template_len];
    var idx: u32 = 1;
    while (idx < 100000) : (idx += 1) {
        out.* = @splat(0);
        var pos: usize = 0;
        @memcpy(out[pos .. pos + dir.len], dir);
        pos += dir.len;
        if (out[pos - 1] != '\\') {
            out[pos] = '\\';
            pos += 1;
        }
        @memcpy(out[pos .. pos + tpl.len], tpl);
        pos += tpl.len;

        var num_buf: [16]u8 = undefined;
        const num_str = std.fmt.bufPrint(&num_buf, "{d}", .{idx}) catch return false;
        for (num_str) |c| {
            out[pos] = c;
            pos += 1;
        }
        if (out_stem_len) |sl| sl.* = tpl.len + num_str.len;
        for (ext_ascii) |c| {
            out[pos] = c;
            pos += 1;
        }
        out[pos] = 0;

        if (w.GetFileAttributesW(@ptrCast(out)) == w.INVALID_FILE_ATTRIBUTES) {
            return true;
        }
    }
    return false;
}
