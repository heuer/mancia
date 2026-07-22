version = "0.1.0"
author = "Lars Heuer"
description = "scdoc to man page and reStructuredText converter"
license = "MIT"
srcDir = "src"
binDir = "bin"
bin = @["mancia"]

requires "nim >= 2.0.0"

import std/[os, strutils]

task musl, "Build a static, musl-linked release binary":
  let
    target = get_env("ZIG_TARGET", "x86_64")
    cpu = case target
          of "aarch64": "arm64"
          of "x86_64": "amd64"
          of "arm": "arm"
          else: raise new_exception(ValueError, "Unknown target: " & target)
    zig_target = target & "-linux-musl"
    zigcc  = "tools" / "zigcc"
  exec "nim c" &
       " -d:release " &
       " --opt:speed " &
       " --panics:on" &
       " -d:danger " &
       " -d:NimblePkgVersion=" & version &
       " --os:linux --cpu:" & cpu &
       " --cc:clang" &
       " --clang.exe:" & zigcc &
       " --clang.linkerexe:" & zigcc &
       " --passL:-s" &
       " --passC:-flto=auto" &
       " --passL:-flto=auto" &
       " --passC:-flto" &
       " --passL:-flto" &
       " --passC:\"-target " & zig_target & "\"" &
       " --passL:\"-target " & zig_target & " -static\"" &
       " -o:" & bin_dir / bin[0] &
       " src/mancia.nim"
