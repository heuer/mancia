version = "0.2.0"
author = "Lars Heuer"
description = "scdoc to man page and reStructuredText converter"
license = "MIT"
srcDir = "src"
binDir = "bin"
bin = @["mancia"]

requires "nim >= 2.0.0"

import std/[os, strutils]


func resolve_cpu(target: string): string =
  case target
  of "aarch64": "arm64"
  of "x86_64": "amd64"
  of "arm": "arm"
  else: raise new_exception(ValueError, "Unknown target: " & target)


task musl, "Build a static, musl-linked release binary":
  let
    target = get_env("ZIG_TARGET", "x86_64")
    cpu = resolve_cpu(target)
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


proc make_archive(bin_path, arch, suffix, man_dir: string) =
  let
    name = "mancia-" & version & "-linux-" & arch & suffix
    dir = "dist" / name
  rm_dir(dir)
  mk_dir(dir)
  cp_file(bin_path, dir / "mancia")
  exec "chmod +x " & (dir / "mancia")
  for f in ["README.rst", "LICENSE", "CHANGES.rst"]:
    if file_exists(f):
      cp_file(f, dir / f)
  if dir_exists(man_dir):
    cp_dir(man_dir, dir / "man")
  with_dir "dist":
    exec "tar czf " & name & ".tar.gz " & name
  rm_dir(dir)


proc gen_man_pages(bin_path, out_dir: string) =
  rm_dir(out_dir)
  mk_dir(out_dir)
  for f in list_files("man"):
    if not f.ends_with(".scd"):
      continue
    let
      page_name = extract_filename(f)[0..^5]
      parts = page_name.rsplit(".", 1)
    if parts.len != 2:
      raise new_exception(ValueError, "Cannot determine man section for " & f)
    let section_dir = out_dir / ("man" & parts[1])
    if not dir_exists(section_dir):
      mk_dir(section_dir)
    exec bin_path & " < " & f & " > " & (section_dir / page_name)


task dist, "Build and package standard (glibc) and static musl release archives":
  let
    bin_path = bin_dir / bin[0]
    man_out = "dist" / "man-generated"
  mk_dir("dist")

  exec "nimble build -y"
  exec "file " & bin_path

  gen_man_pages(bin_path, man_out)

  make_archive(bin_path, "amd64", "", man_out)

  exec "nimble musl -y"
  exec "file " & bin_path
  let cpu = resolve_cpu(get_env("ZIG_TARGET", "x86_64"))
  make_archive(bin_path, cpu, "-musl", man_out)

  rm_dir(man_out)

