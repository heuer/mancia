#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2026 -- Lars Heuer
#
## Tests with roff output
##
## Does not contain tests which should be rejected at the parser level.
import std/[unittest, streams, strutils]
import mancia

proc roff(s: string): string =
  let
    input = new_string_stream(s)
    output = new_string_stream()
  defer:
    input.close()
    output.close()
  parse_scdoc(input, roff_handler(output))
  output.data


suite "roff tests":

  test "parse simple preamble":
    let output = roff("test(1)\n")
    check "test" in output
    check ".TH" in output

  test "parse preamble with footer and header":
    let output = roff("test(1) \"Test Footer\" \"Test Header\"\n")
    check "\"Test Footer\"" in output
    check "\"Test Header\"" in output

  test "ignore underscores in middle of words":
    let output = roff("""test(1)
some_variable_name
""")
    check "some_variable_name" in output

  test "preamble":
    let res = roff("""test(1)
""")
    check ".TH" in res
    check "\"test\"" in res
    check "\"1\"" in res
 
  test "main section":
    let res = roff("""test(1)

# Section
""")
    check ".SH Section" in res
 
  test "subsection":
    let res = roff("""test(1)

## Subsection
""")
    check ".SS Subsection" in res
 
  test "bold":
    let res = roff("""test(1)

This is *bold*.
""")
    check "\\fBbold\\fR" in res
 
  test "italic":
    let res = roff("""test(1)

This is _italic_.
""")
    check "\\fIitalic\\fR" in res
 
  test "escape ~":
    let res = roff("""test(1)
a~b
""")
    check "a\\(tib" in res
 
  test "escape ^":
    let res = roff("""test(1)
a^b
""")
    check "a\\(hab" in res
 
  test "escape -":
    let res = roff("""test(1)
a-b
""")
    check "a\\-b" in res


  test "line break":
    let res = roff("""test(1)

First line++
second line
""")
    check ".br" in res
    check "++" notin res
 
  test "unordered list":
    let res = roff("""test(1)

- First item
- Second item
	- Subitem 2.1
	- Subitem 2.2
- Third item
""")
    check ".IP \\(bu 4" in res
    check "First item" in res
    check "Second item" in res
    check "Subitem 2\\&.\\&1" in res
    check "Subitem 2\\&.\\&2" in res
    check "Third item" in res
    check ".RS 4" in res
    check ".RE" in res
 
  test "ordered list":
    let res = roff("""test(1)

. First item
. Second item
	. Subitem 2.1
	. Subitem 2.2
. Third item
""")
    check ".IP 1. 4" in res
    check ".IP 2. 4" in res
    check ".IP 3. 4" in res
    check "First item" in res
    check "Second item" in res
    check "Subitem 2\\&.\\&1" in res
    check "Subitem 2\\&.\\&2" in res
    check "Third item" in res
 
  test "unordered list line break":
    let res = roff("""test(1)

- First item++
  Second line++
  Third line
- Second item
""")
    check "First item\n.br\nSecond line\n.br\nThird line" in res
    check "Second item" in res
 
  test "ordered list line break":
    let res = roff("""test(1)

. First item++
  Second line  
. Second item
""")
    check "First item\n.br\nSecond line" in res
    check "Second item" in res
 
  test "parse literal block":
    let res = roff("""test(1)

```
code here
  indented
```
""")
    check ".nf" in res
    check ".RS 4" in res
    check "code here" in res
    check "  indented" in res
    check ".fi" in res
    check ".RE" in res
 
  test "parse literal block tabs":
    let res = roff("""test(1)

```
code here
		indented
	third line
```
""")
    check ".nf" in res
    check "code here" in res
    check "\t\tindented" in res
    check "\tthird line" in res
 
  test "table":
    let res = roff("""test(1)

[[ *Col1*
:[ *Col2*
|  Row 1 col1
   more row1 col1 
:  Row 1 col2

""")
    check ".TS" in res
    check ".TE" in res
    check "T{" in res
    check "T}" in res
    check "\\fBCol1\\fR" in res
    check "\\fBCol2\\fR" in res
    check "Row 1 col1 more row1 col1" in res
    check "Row 1 col2" in res

