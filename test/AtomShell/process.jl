using Blink
using Test

import Blink.AtomShell: electron_flags

@testset "electron_flags" begin
    wayland = ["--enable-features=UseOzonePlatform", "--ozone-platform=wayland"]

    @testset "display backend" begin
        # Electron defaults to X11 and dies on a Wayland-only session, so Blink
        # has to select Wayland for it. Only when there is genuinely no X
        # server: everywhere else the flags are left alone.
        withenv("DISPLAY" => nothing, "WAYLAND_DISPLAY" => "wayland-0") do
            @test electron_flags() == (Sys.islinux() ? wayland : [])
        end
        withenv("DISPLAY" => ":0", "WAYLAND_DISPLAY" => "wayland-0") do
            @test isempty(electron_flags())
        end
        withenv("DISPLAY" => nothing, "WAYLAND_DISPLAY" => nothing) do
            @test isempty(electron_flags())
        end
    end

    @testset "BLINK_ELECTRON_ARGS" begin
        withenv("DISPLAY" => ":0", "WAYLAND_DISPLAY" => nothing,
                "BLINK_ELECTRON_ARGS" => "--foo --bar=baz") do
            @test electron_flags() == ["--foo", "--bar=baz"]
        end
        # Appended to, rather than replacing, whatever was detected.
        withenv("DISPLAY" => nothing, "WAYLAND_DISPLAY" => "wayland-0",
                "BLINK_ELECTRON_ARGS" => "--foo") do
            @test electron_flags() == (Sys.islinux() ? [wayland; "--foo"] : ["--foo"])
        end
        withenv("DISPLAY" => ":0", "BLINK_ELECTRON_ARGS" => "  ") do
            @test isempty(electron_flags())
        end
    end
end
