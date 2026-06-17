#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2026 -- Lars Heuer
#
## Converters from scdoc to roff and rst
import std/streams
import nimpy
import mancia


proc parse(scdoc: string, handler: proc(stream: Stream): ScdocHandler): string =
  let output = new_string_stream()
  parse_scdoc(new_string_stream(scdoc), handler(output))
  return output.data


proc to_roff*(scdoc: string): string  {.exportpy.} =
  ## Converts the provided input string to a roff string
  return parse(scdoc, roff_handler)


proc to_rst*(scdoc: string): string {.exportpy.} =
  ## Converts the provided input string to a rST string
  return parse(scdoc, rst_handler)

