#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2026 -- Lars Heuer
#
## Tests aginst the parser
##
## Mainly tests which must be rejected by the parser.
##
## Output specific tests should be implemented in other test files.
##
import std/[unittest, streams]
import mancia


func noop_handler(): ScdocHandler =
  proc noop() = discard
  ScdocHandler(
    doc_start: noop, doc_end: noop,
    text_start: noop, text_end: noop,
    characters: proc(s: string) = discard,
    bold_start: noop, bold_end: noop,
    italic_start: noop, italic_end: noop,
    linebreak: noop, newline: noop,
    indent: noop, dedent: noop,
    preamble: proc (name, section, date, left_footer, center_header: string) = discard,
    section: proc (title: string, level: uint) = discard,
    literal_block_start: noop, literal_block_end: noop,
    literal_block_line: proc(s: string) = discard,
    table_start: proc(style: TableStyle) = discard, table_end: noop,
    table_row_start: noop, table_row_end: noop,
    table_cell_start: proc(align: CellAlign) = discard, table_cell_end: noop,
    list_start: proc (ordered: bool) = discard, list_end: noop,
    list_item_start: noop, list_item_end: noop,
  )


proc parse(s: string, handler: ScdocHandler) =
  parse_scdoc(new_string_stream(s), handler)

proc parse(s: string) = parse_scdoc(new_string_stream(s), noop_handler())


suite "parser tests":

  test "valid preamble":
    let s = """test(1)
"""
    parse(s)

  test "missing preamble":
    let s = """

# SECTION
"""
    expect(ScdocError):
      parse(s)

  test "invalid name":
    let s = """!!(1)
    """
    expect(ScdocError):
      parse(s)

  test "no name":
    let s = """(1)
    """
    expect(ScdocError):
      parse(s)

  test "no section":
    let s = """test
    """
    expect(ScdocError):
      parse(s)

  test "section with spaces":
    let s = """test(1 a)
    """
    expect(ScdocError):
      parse(s)

  test "invalid section number":
    let s = """test(abc)
    """
    expect(ScdocError):
      parse(s)

  test "invalid section number":
    let s = """test(p1)
    """
    expect(ScdocError):
      parse(s)

  test "no section number":
    let s = """test()
    """
    expect(ScdocError):
      parse(s)

  test "section number too large":
    let s = """test(100)
    """
    expect(ScdocError):
      parse(s)


  var seen_linebreak = false

  var h = noop_handler()
  h.linebreak = proc() = seen_linebreak = true

  test "valid line break":
    let s = """test(1)

Line one++
line two
"""
    seen_linebreak = false
    parse(s, h)
    check seen_linebreak

  test "line break with no content":
    let s = """test(1)

Line one++

"""
    expect(ScdocError):
      parse(s)


  test "no line break":
    let s = """test(1)
Line one++  
not line two
"""
    seen_linebreak = false
    parse(s)
    check not seen_linebreak


  test "Comment":
    let s = """test(1)
; This is a comment
"""
    parse(s)

  test "illegal comment":
    let s = """test(1)
;This is not a comment
"""
    expect(ScdocError):
      parse(s)


  test "valid section header":
    let s = """test(1)

# SECTION

## Subsection
"""
    parse(s)

  test "Illegal level":
    let s = """test(1)

### Illegal section
"""
    expect(ScdocError):
      parse(s)

  test "No space after #":
    let s = """test(1)

#SECTION
"""
    expect(ScdocError):
      parse(s)


  test "valid enumerated list":
    let s = """test(1)

. One
. Two
	. Two first sub
"""
    parse(s)

  test "illegal mixing of unordered with ordered":
    let s = """test(1)

. One
. Two
	- Illegal

"""
    expect(ScdocError):
      parse(s)

  test "illegal mixing of unordered with ordered same level":
    let s = """test(1)

. One
. Two
- Illegal
"""
    expect(ScdocError):
      parse(s)

  test "valid bullet list":
    let s = """test(1)

- One
- Two
	- Two first sub
"""
    parse(s)

  test "illegal mixing of unordered with ordered":
    let s = """test(1)

- One
- Two
	. Illegal
"""
    expect(ScdocError):
      parse(s)

  test "illegal mixing of unordered with ordered same level":
    let s = """test(1)

- One
- Two
. Illegal
"""
    expect(ScdocError):
      parse(s)

  test "valid bold formatting":
    let s = """test(1)
This is *bold* text.
"""
    parse(s)

  test "valid italic formatting":
    let s = """test(1)
This is _italic_ text.
"""
    parse(s)

  test "illegal nested formatting":
    let s = """test(1)

This is *bold and _italic_ text*.
"""
    expect(ScdocError):
      parse(s)

  test "illegal nested formatting 2":
    let s = """test(1)

This is _italic and *bold* text_.
"""
    expect(ScdocError):
      parse(s)


  test "valid table":
    let s = """test(1)

[-
:-
"""
    parse(s)

  test "unequal columns":
    let s = """test(1)

[-
:-
:-
|-
:-
|-
:-
"""
    expect(ScdocError):
      parse(s)


  test "valid indentation":
    let s = """test(1)

	This is an indented block.
	It has multiple lines.
"""
    parse(s)

  test "valid indentation":
    let s = """test(1)

	This is an indented block.

		This must be accepted, the empty line above does not count as a dedent!
"""
    parse(s)

  test "invalid indentation":
    let s = """test(1)

   This line has only 3 spaces.
"""
    expect(ScdocError):
      parse(s)

  test "invalid indentation: space directly after a leading tab":
    let s = "test(1)\n\n\tIndent level 1.\n\t Space right after the tab.\n"
    expect(ScdocError):
      parse(s)

  test "invalid indentation: spaces used for a paragraph continuation line":
    let s = "test(1)\n\nFirst line of the paragraph.\n Second line indented with a stray space.\n"
    expect(ScdocError):
      parse(s)

  test "valid indentation: list continuation allows two spaces":
    let s = "test(1)\n\n- Item one\n  continuation of item one.\n"
    parse(s)

  test "valid indentation: literal block content may contain spaces":
    let s = "test(1)\n```\ndef main():\n    print(\"Hello world\")\n\n```\n"
    parse(s)

  test "invalid indentation (more than one level)":
    let s = """test(1)

	Indent level 1
			Indent level 3  
"""
    expect(ScdocError):
      parse(s)

  test "valid literal block":
    let s = """test(1)
```
This is a literal block.
It has multiple lines.
```
"""
    parse(s)

  test "illgal dedent in literal block":
    let s = """test(1)
	```
	This is a literal block.
This line has illegal indentation.
	```
"""
    expect(ScdocError):
      parse(s)

