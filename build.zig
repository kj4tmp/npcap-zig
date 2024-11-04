const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // const upstream_sdk = b.dependency("npcap_sdk", .{});
    // const lib = b.addStaticLibrary(.{
    //     .name = "npcap",
    //     .target = target,
    //     .optimize = optimize,
    // });
    // lib.addObjectFile(upstream_sdk.path("Lib/wpcap.lib"));
    // lib.addObjectFile(upstream_sdk.path("Lib/Packet.lib"));
    // lib.installHeadersDirectory(upstream_sdk.path("Include"), "", .{});
    // b.installArtifact(lib);

    const upstream = b.dependency("npcap", .{});
    const packet = b.addStaticLibrary(.{
        .name = "Packet",
        .target = target,
        .optimize = optimize,
    });
    packet.linkLibCpp(); // needs #include <string>
    packet.linkLibC(); // needs assert.h
    // work-around _Post_invalid_ being missing? something about sal.h headers.
    // https://github.com/xmake-io/xmake-repo/pull/5390

    packet.root_module.addCMacro("_Post_invalid_", "");

    // missing identifier GAA_FLAG_SKIP_DNS_INFO, yeet
    packet.root_module.addCMacro("GAA_FLAG_SKIP_DNS_INFO", "0x800");
    packet.addIncludePath(upstream.path("Common"));
    packet.addIncludePath(upstream.path("packetWin7/Dll"));
    packet.addIncludePath(upstream.path(""));
    packet.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            // "Common/Packet32.h",
            // "Common/WpcapNames.h",
            "packetWin7/Dll/AdInfo.cpp",
            // "Packet.def", tf is a def file?
            "packetWin7/Dll/Packet32-Int.h",
            "packetWin7/Dll/Packet32.cpp",
            "packetWin7/Dll/debug.h",
            // "version.rc", and WTF are these?
            // "version.rc2",
        },
        .flags = &.{"-Wno-comment"},
    });
    b.installArtifact(packet);
}
