#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2026 -- Lars Heuer
#
## Tests with rst output
##
## Does not contain tests which should be rejected at the parser level.
import std/[unittest, streams, strutils]
import mancia

proc rst(s: string): string =
  let
    input = new_string_stream(s)
    output = new_string_stream()
  defer:
    input.close()
    output.close()
  parse_scdoc(input, rst_handler(output))
  output.data


suite "rst tests":

  test "preamble":
    let res = rst("""test(1)
""")
    check "test(1)" in res
    check "*******" in res
    check 2 == res.count("*******") 


  test "main section":
    let res = rst("""test(1)

# Section
""")
    check "Section" in res
    check "=======" in res

  test "subsection":
    let res = rst("""test(1)

## Subsection
""")
    check "Subsection" in res
    check "~~~~~~~~~~" in res

  test "bold":
    let res = rst("""test(1)

This is *bold*.
""")
    check "This is **\\ bold**\\ ." in res

  test "italic":
    let res = rst("""test(1)

This is _italic_.
""")
    check "This is *\\ italic*\\ ." in res

  test "escape |":
    let res = rst("""test(1)
a|b
	is c
""")
    check "a\\|\\ b" in res
    check "    is c" in res

  test "escape _":
    let res = rst("""test(1)
a_b
	is c
""")
    check "a\\_b" in res


  test "line break":
    let res = rst("""test(1)

First line++
second line
""")
    check "| First line" in res
    check "| second line" in res
    check "++" notin res

  test "unordered list":
    let res = rst("""test(1)

- First item
- Second item
	- Subitem 2.1
	- Subitem 2.2
- Third item
""")
    check "* First item" in res
    check "* Second item" in res
    check "  * Subitem 2.1" in res
    check "  * Subitem 2.2" in res
    check "* Third item" in res

  test "ordered list":
    let res = rst("""test(1)

. First item
. Second item
	. Subitem 2.1
	. Subitem 2.2
. Third item
""")
    check "#. First item" in res
    check "#. Second item" in res
    check "   #. Subitem 2.1" in res
    check "   #. Subitem 2.2" in res
    check "#. Third item" in res

  test "unordered list line break":
    let res = rst("""test(1)

- First item++
  Second line++
  Third line
- Second item
""")
    check "* | First item" in res
    check "  | Second line" in res
    check "  | Third line" in res
    check "* Second item" in res

  test "ordered list line break":
    let res = rst("""test(1)

. First item++
  Second line  
. Second item
""")
    check "#. | First item" in res
    check "   | Second line" in res
    check "#. Second item" in res


  test "parse literal block":
    let res = rst("""test(1)

```
code here
  indented
```
""")
    check ".. code-block::" in res
    check "    code here" in res
    check "      indented" in res

  test "parse literal block tabs":
    let res = rst("""test(1)

```
code here
		indented
	third line
```
""")
    check ".. code-block::" in res
    check "    code here" in res
    check "    \t\tindented" in res
    check "    \tthird line" in res


  test "table":
    let res = rst("""test(1)

[[ *Col1*
:[ *Col2*
|  Row 1 col1
   more row1 col1 
:  Row 1 col2

""")
    check ".. list-table" in res
    check "   * - **\\ Col1**\\ " in res
    check "     - **\\ Col2**\\ " in res
    check "   * - Row 1 col1 more row1 col1" in res
    check "     - Row 1 col2" in res


