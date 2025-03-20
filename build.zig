const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const npcap_sdk = b.dependency("npcap_sdk", .{ .target = target, .optimize = optimize });

    const npcap = b.addModule("npcap", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const packet_lib_path = switch (target.result.os.tag) {
        .windows => switch (target.result.cpu.arch) {
            .aarch64 => npcap_sdk.path("Lib/ARM64/Packet.lib"),
            .x86_64 => npcap_sdk.path("Lib/x64/Packet.lib"),
            .x86 => npcap_sdk.path("Lib/Packet.lib"),
            else => unreachable,
        },
        else => unreachable,
    };
    const wpcap_lib_path = switch (target.result.os.tag) {
        .windows => switch (target.result.cpu.arch) {
            .aarch64 => npcap_sdk.path("Lib/ARM64/wpcap.lib"),
            .x86_64 => npcap_sdk.path("Lib/x64/wpcap.lib"),
            .x86 => npcap_sdk.path("Lib/wpcap.lib"),
            else => unreachable,
        },
        else => unreachable,
    };

    npcap.addObjectFile(packet_lib_path);
    npcap.addObjectFile(wpcap_lib_path);
    npcap.addIncludePath(npcap_sdk.path("Include/"));

    const translate_c = b.addTranslateC(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .root_source_file = npcap_sdk.path("Include/pcap/pcap.h"),
    });
    npcap.addImport("npcap_sdk", translate_c.createModule());

    const lib_unit_tests = b.addTest(.{
        .root_module = npcap,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
}
