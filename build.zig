const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const root_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .strip = optimize != .debug,
    });

    const libs = [_][]const u8{
        "user32",
        "gdi32",
        "gdiplus",
        "dwmapi",
        "shell32",
        "ole32",
        "advapi32",
        "kernel32",
    };
    for (libs) |lib| {
        root_mod.linkSystemLibrary(lib, .{});
    }

    const exe = b.addExecutable(.{
        .name = "fsa1",
        .root_module = root_mod,
    });

    if (optimize != .debug) {
        exe.subsystem = .windows;
    }

    b.installArtifact(exe);
}