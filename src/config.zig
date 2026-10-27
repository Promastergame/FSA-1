const std = @import("std");
const w = @import("win32.zig");
const L = w.L;

pub const Format = enum(u32) {
    png = 0,
    jpeg = 1,
    bmp = 2,
    tiff = 3,

    pub fn ext(self: Format) []const u8 {
        return switch (self) {
            .png => ".png",
            .jpeg => ".jpg",
            .bmp => ".bmp",
            .tiff => ".tiff",
        };
    }
};

pub const Lang = enum(u32) {
    auto = 0,
    en = 1,
    ru = 2,
};

pub const Strings = struct {
    paste_title: [*:0]const u16,
    name_label: [*:0]const u16,
    format_label: [*:0]const u16,
    save_btn: [*:0]const u16,
    settings_title: [*:0]const u16,
    autosave_check: [*:0]const u16,
    template_label: [*:0]const u16,
    lang_label: [*:0]const u16,
};

pub const STR_EN = Strings{
    .paste_title = L("FSA 1 - Paste Image"),
    .name_label = L("Filename:"),
    .format_label = L("Format:"),
    .save_btn = L("Save"),
    .settings_title = L("FSA 1 - Settings"),
    .autosave_check = L("Auto-save without prompt"),
    .template_label = L("Template:"),
    .lang_label = L("Language:"),
};

pub const STR_RU = Strings{
    .paste_title = L("FSA 1 - Вставка картинки"),
    .name_label = L("Имя файла:"),
    .format_label = L("Формат:"),
    .save_btn = L("Сохранить"),
    .settings_title = L("FSA 1 - Настройки"),
    .autosave_check = L("Автосохранение без меню"),
    .template_label = L("Шаблон:"),
    .lang_label = L("Язык:"),
};

pub const Config = struct {
    auto_save: bool = false,
    default_format: Format = .png,
    lang: Lang = .auto,
    template: [64]u16 = @splat(0),
    template_len: usize = 0,

    const SUBKEY = L("Software\\FSA\\FSA1");

    pub fn load() Config {
        var cfg = Config{};
        const def_tpl = L("picture_");
        @memcpy(cfg.template[0..def_tpl.len], def_tpl);
        cfg.template_len = def_tpl.len;

        var val: w.DWORD = 0;
        var size: w.DWORD = @sizeOf(w.DWORD);

        if (w.RegGetValueW(w.HKEY_CURRENT_USER, SUBKEY, L("AutoSave"), w.RRF_RT_REG_DWORD, null, &val, &size) == 0) {
            cfg.auto_save = (val != 0);
        }
        size = @sizeOf(w.DWORD);
        if (w.RegGetValueW(w.HKEY_CURRENT_USER, SUBKEY, L("DefaultFormat"), w.RRF_RT_REG_DWORD, null, &val, &size) == 0) {
            if (val <= 3) cfg.default_format = @enumFromInt(val);
        }
        size = @sizeOf(w.DWORD);
        if (w.RegGetValueW(w.HKEY_CURRENT_USER, SUBKEY, L("Language"), w.RRF_RT_REG_DWORD, null, &val, &size) == 0) {
            if (val <= 2) cfg.lang = @enumFromInt(val);
        }

        var buf: [64]u16 = @splat(0);
        size = @sizeOf(@TypeOf(buf));
        if (w.RegGetValueW(w.HKEY_CURRENT_USER, SUBKEY, L("NameTemplate"), w.RRF_RT_REG_SZ, null, &buf, &size) == 0) {
            const len = std.mem.indexOfScalar(u16, &buf, 0) orelse 0;
            if (len > 0 and len < 63) {
                cfg.template = @splat(0);
                @memcpy(cfg.template[0..len], buf[0..len]);
                cfg.template_len = len;
            }
        }
        return cfg;
    }

    pub fn save(self: *const Config) void {
        var hkey: w.HKEY = undefined;
        if (w.RegCreateKeyExW(w.HKEY_CURRENT_USER, SUBKEY, 0, null, 0, w.KEY_WRITE, null, &hkey, null) != 0) return;
        defer _ = w.RegCloseKey(hkey);

        const auto_v: w.DWORD = if (self.auto_save) 1 else 0;
        const fmt_v: w.DWORD = @intFromEnum(self.default_format);
        const lang_v: w.DWORD = @intFromEnum(self.lang);

        _ = w.RegSetValueExW(hkey, L("AutoSave"), 0, w.REG_DWORD, @ptrCast(&auto_v), @sizeOf(w.DWORD));
        _ = w.RegSetValueExW(hkey, L("DefaultFormat"), 0, w.REG_DWORD, @ptrCast(&fmt_v), @sizeOf(w.DWORD));
        _ = w.RegSetValueExW(hkey, L("Language"), 0, w.REG_DWORD, @ptrCast(&lang_v), @sizeOf(w.DWORD));
        _ = w.RegSetValueExW(
            hkey,
            L("NameTemplate"),
            0,
            w.REG_SZ,
            @ptrCast(&self.template),
            @intCast((self.template_len + 1) * 2),
        );
    }

    pub fn strings(self: *const Config) *const Strings {
        const use_ru = switch (self.lang) {
            .ru => true,
            .en => false,
            .auto => (w.GetUserDefaultUILanguage() & 0x3FF) == 0x19, // LANG_RUSSIAN
        };
        return if (use_ru) &STR_RU else &STR_EN;
    }
};