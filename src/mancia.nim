#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2026 -- Lars Heuer
#
##
## mancia - scdoc man page generator and converter.
##
## Usage: ``mancia [options] < input.scd > output``
##
## Converts scdoc (scd) input into roff (man page format) or reStructuredText.
##
import std/[os, streams, strutils, unicode, times]


const
  NIMBLE_PKG_VERSION {.strdefine.}: string = "unknown"
  VERSION = NIMBLE_PKG_VERSION


type
  ScdocError* = object of ValueError
    ## This is the standard error in case of parsing errors.
    line*: int  ## Indicates the line number where the error happened


  FontStyle = enum
    fs_regular, fs_bold, fs_italic


  ScdocParser = object
    stream: Stream
    handler: ScdocHandler
    line: int
    indent_level: int
    font_style = fs_regular


  TableStyle* = enum
    ## Indicates the table style.
    ##
    ## Only useful for developing another `ScdocHandler`_
    ts_borders, ## Borders around all cells
    ts_no_border, ## No borders
    ts_one_border  ## Border around the table


  CellAlign* = enum
    ## Cell alignment
    ##
    ## Only useful for developing another `ScdocHandler`_
    ca_left, ca_center, ca_right,
    ca_left_expand, ca_center_expand, ca_right_expand


  ScdocHandler* = object
    ## The handler receives parsing events.
    ##
    ## The handler is responsible for translating the parser events into an
    ## output format. If necessary, the character streams must be escaped into
    ## the specific output format.
    ##
    ## The handler should not assume that all ``end`` events will be triggered.
    ## The parser terminates calls to the handler immediately after a parsing
    ## error occurs.
    ##
    ## The handler is responsible for ensuring that the output is valid after
    ## the ``doc_end`` event.
    ##
    ## If the parser detects an error, the output may be invalid.

    doc_start*: proc ()
    ## This is the very first event, followed by ``preamble``.
    doc_end*: proc ()
    ## Indicates the end of the document. No more events will be emitted after
    ## this. This event may be omitted if a parser error occurs.
    preamble*: proc (name, section, date, left_footer, center_header: string)
    ## The preamble is emitted after doc_start and before any other events.
    section*: proc (title: string, level: uint)
    ## Section
    text_start*: proc ()
    ## Indicates the start of text.
    ##
    ## This event usually corresponds to the start of a line.
    ##
    ## The indentation level is not part of the text, it is reported by
    ## the `indent` and `dedent` events.
    ##
    ## This event may be followed by `characters`, `bold_start`, `bold_end`,
    ## `italic_start`, `italic_end`, `linebreak`, and `characters` events.
    text_end*: proc ()
    ## Indicates the end of a text.
    ##
    ## This event usually corresponds to the end of a line unless a
    ## `linebreak` event was issued previously.
    bold_start*: proc ()
    ## Indicates that the following chars should be bold
    bold_end*: proc ()
    ## Indicates that the following chars are using the regular weight
    italic_start*: proc ()
    ## Indicates that the following chars should be italic
    italic_end*: proc ()
    ## Indicates that the following chars are using regular font
    characters*: proc(chars: string)
    ## Reports a chunk of text.
    ##
    ## The reported characters are plain Unicode and contains no scdoc-specific
    ## markup. The handler is responsible to apply any escaping rules.
    ##
    ## The format (bold or italic) is determined by previous ``bold_start`` and
    ## ``italic_start`` events.
    linebreak*: proc()
    ## Indicates an explicit line break (``++``)
    ##
    ## The next chunk of characters must be placed on the next line with the
    ## same indentation level
    newline*: proc()
    ## Indicates a newline
    list_start*: proc (ordered: bool)
    ## Indicates a list start. The list may be enumerated (ordered) or use
    ## bullet style (not ordered).
    ##
    ## Lists may be nested.
    ##
    ## The parser ensures that nested lists are of the same type.
    list_end*: proc ()
    ## Indicates that the (sub)list is finished
    list_item_start*: proc ()
    ## Starts a list item
    list_item_end*: proc ()
    ## Ends a list item
    table_start*: proc (style: TableStyle)
    ## Indicates that a table with the provided style starts.
    ##
    ## The style should be supported but may be ignored by handlers which
    ## don't serialize to roff.
    table_end*: proc ()
    ## Indicates that the table is finished
    table_row_start*: proc()
    ## Indicates a new table row.
    ##
    ## The parser ensures that all rows have the same number of columns.
    ##
    ## This event is followed by ``table_cell_start`` and ``table_cell_end``
    ## events.
    table_row_end*: proc()
    ## Indicates that no more cells are reported for the current row.
    ##
    ## This event will be followed by either the ``table_end`` or
    ## ``table_row_start`` event.
    table_cell_start*: proc(align: CellAlign)
    ## Indicates a new cell within a row.
    table_cell_end*: proc()
    ## Indicates that no more content for the current cell is reported.
    literal_block_start*: proc()
    ## Indicates a literal block (i.e. an code example)
    ##
    ## This event is followed by a number of ``literal_block_line`` events.
    literal_block_end*: proc()
    ## Indicates the end of a code block.
    literal_block_line*: proc(text: string)
    ## Reports text within a literal block.
    indent*: proc()
    ## Informs the handler that the indentation should be incremented by one
    ## level.
    dedent*: proc()
    ## Informs the handler that the indentation should be decremented by one
    ## level.


func rst_handler*(output: Stream): ScdocHandler =
  ## Returns a `ScdocHandler`_ which serializes reStructuredText.
  ##
  ## The handler ignores the table style and cell alignment.

  var
    in_ordered_list = false
    list_level = -1
    indent_level = 0
    col: int
    in_line_block = false
    use_buffer = false
    buffer: seq[string]

  func escape(s: string): string =
    result = new_string_of_cap(s.len + 8)
    for c in s:
      case c
      of '\\': result.add "\\\\"
      of '*', '_', '-', '<', '>': result.add '\\'; result.add c
      of '|': result.add "\\|\\ "
      else: result.add c

  proc write(s: string) =
    if use_buffer:
      if buffer.len == 0:
        buffer.add s
      else:
        buffer[^1].add s
    else:
      output.write(s)

  proc write_line(s = "") =
    if s.len > 0: write(s)
    write("\n")

  proc write_header(header: string, level: uint) =
    # See <https://devguide.python.org/documentation/markup/#sections>
    let c = case level:
            of 0: "*"
            of 1: "="
            else: "~"
    let line = repeat(c, header.len)
    if level == 0:  # Py dev. guide: * with overline, for chapters
      write_line(line)
    write_line(header)
    write_line(line)


  # Inline formatting adds an extra escaped whitespace to allow **bold**(5)
  # even in cases where it wouldn't be necessary.
  # See rST primer: […] it must be separated from surrounding text by
  # non-word characters. Use a backslash escaped space to work around that:
  # thisis\ *one*\ word. […]
  proc write_bold() = write("**\\ ")

  proc write_italic() = write("*\\ ")

  ScdocHandler(
    doc_start: proc() =
      write_line(".. Generated by mancia " & VERSION & "\n"),

    doc_end: proc() = output.flush(),

    text_start: proc() =
      use_buffer = true,

    text_end: proc() =
      use_buffer = false
      let prefix = "    ".repeat(indent_level)
      if buffer.len > 1:
        write(prefix & "| ")
        write_line(buffer[0])
        for i in 1..<buffer.len:
          write(prefix & "| ")
          write_line(buffer[i])
      elif buffer.len == 1:
        write(prefix)
        write_line(buffer[0])
      else:
        write(prefix & "\n")
      buffer = @[],

    characters: proc(s: string) = write(escape(s)),

    bold_start: write_bold, bold_end: write_bold,

    italic_start: write_italic, italic_end: write_italic,

    linebreak: proc() =
      in_line_block = true
      buffer.add(""),

    newline: proc() = write(" "),

    indent: proc() = inc(indent_level),

    dedent: proc() = dec(indent_level),

    preamble: proc (name, section, date, left_footer, center_header: string) =
      write_header(name & "(" & section & ")", 0),

    section: proc (title: string, level: uint) = write_header(title, level),

    literal_block_start: proc() =
      write_line("    ".repeat(indent_level) & ".. code-block::\n"),

    literal_block_end: proc() = write_line(),

    literal_block_line: proc(s: string) =
      write("    ".repeat(indent_level + 1))  # +1 since we use 4 spaces to indent the block anyway
      write_line(s),

    table_start: proc(style: TableStyle) =
      write_line(".. list-table::")
      write_line("   :align: left")
      write_line(),

    table_end: proc() = write_line(),

    table_row_start: proc() = col = 0,

    table_row_end: proc() = discard,

    table_cell_start: proc(align: CellAlign) =
      use_buffer = true
      inc(col),

    table_cell_end: proc() =
      use_buffer = false
      if col == 1:
        write("   * - ")
      else:
        write("     - ")
      if buffer.len > 1:
        write("| ")
        write(buffer[0])
        for i in 1..<buffer.len:
          write_line()
          write("      | ")
          write(buffer[i])
      else:
        write(buffer[0])
      buffer = @[]
      write_line(),

    list_start: proc (ordered: bool) =
      in_ordered_list = ordered
      if list_level > -1:
        write_line()
      inc(list_level),

    list_end: proc () =
      dec list_level
      write_line(),

    list_item_start: proc () = use_buffer = true; buffer = @[],

    list_item_end: proc () =
      use_buffer = false
      let prefix = if in_ordered_list: "    ".repeat(indent_level) & "   ".repeat(list_level)
                   else: "    ".repeat(indent_level) &  "  ".repeat(list_level)
      if buffer.len > 1:
        write(prefix)
        write(if in_ordered_list: "#. | " else: "* | ")
        write(buffer[0])
        for i in 1..<buffer.len:
          write_line()
          write(prefix)
          if in_ordered_list: write("   | ") else: write("  | ")
          write(buffer[i])
      elif buffer.len == 1:
        write(prefix)
        write(if in_ordered_list: "#. " else: "* ")
        write(buffer[0])
      else:
        write(prefix)
        write(if in_ordered_list: "#. " else: "* ")
      buffer = @[]
      write_line(),
  )


func roff_handler*(output: Stream): ScdocHandler =
  ## Returns a `ScdocHandler`_ which serializes roff.
  ##
  ## This is the standard handler used by the command line utility to
  ## generate man pages.

  type
    Cell = object
      align: CellAlign
      content: string

  var
    in_ordered_list = false
    list_numbering: seq[int]
    in_table = false
    in_cell = false
    table_style: TableStyle
    table_rows: seq[seq[Cell]]
    cell_alignment: CellAlign
    cell_content: string
    needs_pp: bool
    had_content: bool

  template quote(s: string): string = '"' & s & '"'

  func escape(s: string): string =
    result = new_string_of_cap(s.len + 8)
    for c in s:
      case c
      of '\\': result.add "\\e"
      of '~': result.add "\\(ti"
      of '^': result.add "\\(ha"
      of '-': result.add "\\-"
      of '.': result.add "\\&.\\&"
      of '\'': result.add "\\&'\\&"
      of '!', '?': result.add(c); result.add("\\&")
      else:
        if $c == "—":
          result.add "\\(em"
        else:
          result.add c

  func escape_literal(s: string): string =
    result = new_string_of_cap(s.len + 4)
    for i, c in s:
      case c
      of '.', '\'':
        if i == 0: result.add "\\&"
        result.add c
      of '-':  result.add "\\-"
      of '\\': result.add "\\\\"
      else: result.add c

  template write(s) =
    if in_cell:
      cell_content.add s
    else:
      output.write(s)

  proc write_line(s="") =
    if s.len > 0: write(s)
    write('\n')

  template roff_macro(name: string, args: varargs[string]) =
    write_line("." & name & (if args.len > 0: " " & args.join(" ") else: ""))

  proc write_comment(text: string) = write_line(""".\" """ & text)

  proc back_to_regular() = write("\\fR")

  ScdocHandler(
    doc_start: proc () =
      write_comment("Generated by mancia " & VERSION)
      write_comment("Complete documentation for this program is not available as a GNU info page")
      # The code for the following macros was taken from the scdoc project,
      # see <https://git.sr.ht/~sircmpwn/scdoc> (c) Drew DeVault, license: MIT
      output.write_line(""".ie \n(.g .ds Aq \(aq""")
      output.write_line(".el       .ds Aq '")
      roff_macro("nh")  # Disable hyphenation
      roff_macro("ad", "l")  # Disable justification
      write_comment("Begin generated content:"),

    doc_end: proc() = output.flush(),

    text_start: proc() =
      if needs_pp:
        roff_macro("PP")
      needs_pp = false
      had_content = false,

    text_end: proc() =
      if had_content:
        write('\n')
        needs_pp = true
      had_content = false,

    characters: proc(s: string) = had_content = true; write(escape(s)),

    bold_start: proc() = had_content = true; write("\\fB"),

    bold_end: back_to_regular,

    italic_start: proc() = had_content = true; write("\\fI"),

    italic_end: back_to_regular,

    linebreak: proc() = had_content = true; write("\n.br\n"),

    newline: proc() = had_content = true; write('\n'),

    indent: proc() =
      had_content = false
      needs_pp = false
      roff_macro("RS", "4"),

    dedent: proc() =
      had_content = false
      needs_pp = false
      roff_macro("RE"),

    preamble: proc (name, section, date, left_footer, center_header: string) =
      roff_macro("TH", quote(escape(name)), quote(escape(section)), quote(escape(date)),
                 if left_footer.len > 0 or center_header.len > 0: quote(escape(left_footer)) else: "",
                 if center_header.len > 0: quote(escape(center_header)) else: ""),

    section: proc (title: string, level: uint) =
      needs_pp = false
      roff_macro(if level == 1: "SH" else: "SS", title),


    literal_block_start: proc() = roff_macro("nf"); roff_macro("RS", "4"),

    literal_block_end: proc() =
      roff_macro("RE")
      roff_macro("fi")
      roff_macro("PP"),

    literal_block_line: proc(s: string) = output.write_line(escape_literal(s)),

    table_start: proc(style: TableStyle) =
      in_table = true
      table_style = style,

    table_end: proc() =
      in_table = false
      roff_macro("TS")
      case table_style
      of ts_borders: output.write("allbox;")
      of ts_one_border: output.write("box;")
      else: discard
      for i, row in table_rows:
        for j, cell in row:
          output.write(case cell.align
                       of ca_left: "l"
                       of ca_center: "c"
                       of ca_right: "r"
                       of ca_left_expand: "lx"
                       of ca_center_expand: "cx"
                       of ca_right_expand: "rx")
          if j < row.len - 1: output.write(' ')
        write_line(if i < table_rows.len - 1: "" else: ".")
      for row in table_rows:
        output.write("T{\n")
        for j, cell in row:
          output.write(cell.content)
          if j < row.len - 1: output.write("\nT}\tT{\n")
          else: output.write("\nT}")
        write_line()
      table_rows = @[]
      roff_macro("TE")
      roff_macro("sp", "1"),

    table_row_start: proc() = table_rows.add(@[]),

    table_row_end: proc() = discard,

    table_cell_start: proc(align: CellAlign) =
      in_cell = true
      cell_alignment = align,

    table_cell_end: proc() =
      in_cell = false
      table_rows[^1].add Cell(align: cell_alignment, content: cell_content)
      cell_content = "",

    list_start: proc (ordered: bool) =
      in_ordered_list = ordered
      list_numbering.add 0
      if list_numbering.len > 1:
        roff_macro("RS", "4")
      roff_macro("PD", "0"),

    list_end: proc () =
      discard list_numbering.pop()
      if list_numbering.len > 0:
        roff_macro("RE")
        roff_macro("PD", "0")
      else:
        roff_macro("PD")
        roff_macro("PP"),

    list_item_start: proc() =
      inc list_numbering[^1]
      if in_ordered_list: roff_macro("IP", $list_numbering[^1] & ".", "4")
      else: roff_macro("IP", "\\(bu 4"),

    list_item_end: proc () = write('\n'),
  )


const
  ALPHA_NUMERIC = {'a'..'z', 'A'..'Z', '0'..'9'}
  NAME_CHARS = ALPHA_NUMERIC + {'_','-','.'}


func error(msg: string, line: int, col = -1) {.noReturn.} =
  let location = if col >= 0: $line & ":" & $col else: $line
  var ex = new_exception(ScdocError, "Error at " & location & ": " & msg)
  {.cast(noSideEffect).}:
    ex.line = line
  raise ex


proc read_line(p: var ScdocParser, line: var string): bool =
  if p.stream.read_line(line):
    inc p.line
    result = true


proc peek_line(p: var ScdocParser, line: var string): bool =
  let
    line_no = p.line
    pos = p.stream.get_position()
  result = read_line(p, line)
  p.line = line_no
  p.stream.set_position(pos)


func skip_while(s: string, i: var int, chars: set[char]) =
  while i < s.len and s[i] in chars: inc i


func skip_while(s: string, i: var int, c: char) =
  while i < s.len and s[i] == c: inc i


func skip_until(s: string, i: var int, chars: set[char]) =
  while i < s.len and s[i] notin chars: inc i


func skip_until(s: string, i: var int, stop: char) =
  skip_until(s, i, {stop})


func expect(s: string, i: var int, c: char, lineno: int, msg: string) =
  if i >= s.len or s[i] != c:
    error(msg, lineno, i)
  inc i


proc parse_preamble(p: var ScdocParser) =
  var
    line: string
    i: int
    start: int
  if not p.read_line(line):
    return
  skip_while(line, i, {' ', '\t'})
  if i > 0:
    error("Invalid preamble: Found leading whitespaces", p.line, i)
  skip_while(line, i, NAME_CHARS)
  let name = line[0..<i]
  if name.len == 0: error("Invalid preamble: No name found", p.line, i)
  expect(line, i, '(', p.line, "Expected '(' after name")
  start = i
  skip_while(line, i, ALPHA_NUMERIC)
  let section = line[start..<i]
  if section.len == 0:
    error("Invalid preamble: Section number is missing or invalid", p.line, i)
  elif section[0] notin {'1'..'9'}:
    error("Invalid preamble: Expected a section number between 0 and 10, got: " & section, p.line, i)
  expect(line, i, ')', p.line, "Expected ')' after section")
  var footer_header: seq[string]
  while i < line.len:
    skip_while(line, i, {' ', '\t'})
    if i >= line.len: break
    if line[i] == '"':
      inc i
      start = i
      skip_until(line, i, '"')
      if i >= line.len or line[i] != '"':
        error("Invalid preamble: Unclosed quoted field", p.line, i)
      footer_header.add line[start..<i]
    else:
      error("Invalid preamble: Unexpected character: '" & line[i] & "'", p.line, i)
    inc i
  let date = if exists_env("SOURCE_DATE_EPOCH"):
               let epoch = parse_int(get_env("SOURCE_DATE_EPOCH"))
               from_unix(epoch).format("yyyy-MM-dd")
             else:
               now().format("yyyy-MM-dd")
  p.handler.preamble(name, section, date,
                     if footer_header.len > 0: footer_header[0] else: "",
                     if footer_header.len > 1: footer_header[1] else: "")


proc sync_indent(p: var ScdocParser, level: int, check_level=true) =
  if check_level and level > p.indent_level + 1:
    error("Indentation level cannot be increased by more than one tab", p.line)
  while p.indent_level > level:
    p.handler.dedent()
    dec p.indent_level
  while level > p.indent_level:
    p.handler.indent()
    inc p.indent_level


proc parse_literal_block(p: var ScdocParser) =
  var
    line: string
    i: int
  let block_indent = p.indent_level
  p.handler.literal_block_start()
  while read_line(p, line):
    if line.len == 0:
      p.handler.literal_block_line("")
      continue
    i = 0
    skip_while(line, i, '\t')
    if i < block_indent:
      error("Cannot deindent in literal block", p.line, i)
    sync_indent(p, i, check_level=false)
    if line.continues_with("```", i) and i + 3 >= line.len:
      if i != block_indent:
        error("Closing ``` must have the same indentation as the opening ```", p.line, i)
      break
    if i > block_indent:
      i = block_indent
    var txt = new_string_of_cap(line.len)
    while i < line.len:
      if line[i] == '\\':
        inc i
        if i >= line.len: error("Unexpected EOF after escape sequence \\", p.line, i)
      txt.add line[i]
      inc i
    p.handler.literal_block_line(txt)
  p.handler.literal_block_end()


proc parse_text(p: var ScdocParser, line: string, in_list=false) =

  template handle_chars() =
    if txt.len > 0: p.handler.characters(txt); txt = ""

  var
    txt: string
    i = 0
  while i < line.len:
    let c = line[i]
    case c
    of '\\':
      inc i
      if i >= line.len: error("Unexpected EOF after escape sequence \\", p.line, i)
      txt.add line[i]
    of '*':
      handle_chars()
      if p.font_style == fs_bold:
        p.handler.bold_end()
        p.font_style = fs_regular
      else:
        if p.font_style == fs_italic:
          error("Cannot nest bold formatting inside italic formatting", p.line, i)
        p.handler.bold_start()
        p.font_style = fs_bold
    of '_':
      if i > 0 and line[i - 1] in ALPHA_NUMERIC and
        i + 1 < line.len and line[i + 1] in ALPHA_NUMERIC:  # "_" in a_word
        txt.add '_'
      else:
        handle_chars()
        if p.font_style == fs_italic:
          p.handler.italic_end()
          p.font_style = fs_regular
        else:
          if p.font_style == fs_bold:
            error("Cannot nest italic formatting inside bold formatting", p.line, i)
          p.handler.italic_start()
          p.font_style = fs_italic
    of '+':
      if i + 1 < line.len and line[i + 1] == '+' and i + 2 == line.len:
        var next_line: string
        if not read_line(p, next_line):
          error("Unexpected EOF after line break", p.line, i)
        if next_line.strip().len == 0:
          error("Line break cannot be followed by an empty line", p.line, i)
        handle_chars()
        p.handler.linebreak()
        i = 0
        skip_while(next_line, i, '\t')
        if i > p.indent_level:
          i = p.indent_level
        if in_list:
          let tabs = i
          skip_while(next_line, i, ' ')
          if i - tabs > 2:
            i = tabs + 2
          elif i - tabs < 2:
            error("Illegal list item continuation: Expected two spaces", p.line, i)
        parse_text(p, next_line[i..^1], in_list=in_list)
        return
      else:
        txt.add '+'
    else:
      txt.add c
    inc i
  handle_chars()


proc parse_table(p: var ScdocParser, first_line: string) =
  var
    i: int
    col: int
    line = first_line
    num_cols = -1
    prev_row_aligns: seq[CellAlign]
    cell_content = ""
    cell_align = ca_left
    in_row = false
  p.handler.table_start(case line[0]
                        of '|': ts_no_border
                        of ']': ts_one_border
                        else: ts_borders)
  while true:
    i = 0
    if i >= line.len or line[i] notin {'|', ':', '[', ']', ' '}:
      break
    let separator = line[i]
    inc i
    if separator == ' ':
      if not in_row:
        error("Cannot continue cell, no previous cell exists", p.line, i)
      if i >= line.len or line[i] != ' ':
        error("Cell continuation requires two spaces", p.line, i)
      inc i
      cell_content.add " " & line[i..^1].strip()
      if not read_line(p, line): break
      if line.len == 0: break
      continue
    if in_row and cell_content.len > 0:
      p.handler.table_cell_start(cell_align)
      parse_text(p, cell_content)
      p.handler.table_cell_end()
      cell_content = ""
    if separator in {'|', '[', ']'}:
      if in_row:
        if num_cols == -1:
          num_cols = col
        elif num_cols != col:
          error("Each row must have the same number of columns", p.line, i)
        p.handler.table_row_end()
      p.handler.table_row_start()
      col = 0
      in_row = true
    if i >= line.len:
      error("Missing cell alignment", p.line, i)
    cell_align = ca_left
    if line[i] == ' ' and prev_row_aligns.len > 0 and col < prev_row_aligns.len:
      cell_align = prev_row_aligns[col]
      inc i
    elif line[i] in {'[', '-', ']', '<', '=', '>'}:
      cell_align = case line[i]
                   of '-': ca_center
                   of ']': ca_right
                   of '<': ca_left_expand
                   of '=': ca_center_expand
                   of '>': ca_right_expand
                   else:   ca_left
      inc i
    else: error("Expected alignment character, got '" & line[i] & "'", p.line, i)
    if prev_row_aligns.len <= col:
      prev_row_aligns.add(cell_align)
    else:
      prev_row_aligns[col] = cell_align
    if i < line.len and line[i] == ' ': inc i
    cell_content = line[i..^1].strip()
    if "T{" in cell_content or "T}" in cell_content:
      error("Cells cannot contain T{ or T} due to roff limitations", p.line, i)
    inc col
    if not read_line(p, line): break
    if line.len == 0: break
  if in_row and cell_content.len > 0:
    p.handler.table_cell_start(cell_align)
    parse_text(p, cell_content)
    p.handler.table_cell_end()
  if in_row:
    if num_cols == -1:
      num_cols = col
    elif num_cols != col:
      error("Each row must have the same number of columns", p.line, i)
    p.handler.table_row_end()
  p.handler.table_end()


func check_unclosed_formatting(p: var ScdocParser) =
  if p.font_style != fs_regular:
    let expected = if p.font_style == fs_bold: "*" else: "_"
    error("Expected '" & expected & "' before starting a new line" , p.line)


proc parse_list(p: var ScdocParser, first_line: string, ordered: bool) =
  var
    i = 0
    line = first_line
    item_ended = false
  let list_indent = p.indent_level

  template has_next_item(): bool =
    var has_next = false
    if i + 1 < line.len and line[i] in {'-', '.'} and line[i + 1] == ' ':
      if line[i] == '.' and not ordered or line[i] == '-' and ordered:
        error("Cannot mix ordered lists with unordered lists", p.line, i)
      line = line[i + 2..^1]
      has_next = true
    has_next

  p.handler.list_start(ordered)
  while true:
    p.handler.list_item_start()
    parse_text(p, line, in_list=true)
    item_ended = false

    while peek_line(p, line):
      if line.len == 0: break
      i = 0
      skip_while(line, i, '\t')
      let next_tabs = i
      if next_tabs > list_indent:
        if next_tabs > list_indent + 1:
          error("Indented by an amount greater than 1", p.line)
        inc p.indent_level
        discard read_line(p, line)
        i = 0
        skip_while(line, i, '\t')
        if has_next_item():
          p.handler.list_item_end()
          item_ended = true
          parse_list(p, line, ordered)
        else:
          p.handler.linebreak()
          parse_text(p, line[i..^1], in_list=true)
          check_unclosed_formatting(p)
        dec p.indent_level
        break
      elif next_tabs == list_indent:
        let spaces_start = i
        skip_while(line, i, ' ')
        if i - spaces_start == 2:
          discard read_line(p, line)
          p.handler.newline()
          parse_text(p, line[i..^1], in_list=true)
        else:
          break
      else:
        break

    if not item_ended:
      p.handler.list_item_end()

    if not peek_line(p, line): break
    i = 0
    skip_while(line, i, '\t')
    if line.len == 0 or i != list_indent: break
    discard read_line(p, line)
    i = 0
    skip_while(line, i, '\t')
    if not has_next_item(): break

  p.handler.list_end()
  p.indent_level = list_indent


proc parse_document(p: var ScdocParser) =
  var
    line: string
    i: int

  while p.read_line(line):
    i = 0
    if line.len == 0:
      p.handler.text_start()
      p.handler.text_end()
      continue
    skip_while(line, i, '\t')
    sync_indent(p, i)
    if i >= line.len:
      p.handler.text_start()
      p.handler.text_end()
      continue
    if i == 0:
      case line[0]
      of '#':
        skip_while(line, i, '#')
        let level = uint i
        if level > 2:
          error("The sections may be a maximum of 2 levels deep", p.line, i)
        expect(line, i, ' ', p.line, "Expected whitespace after #")
        p.handler.section(line[i..^1].strip(), level)
        continue
      of ';':
        if i + 1 >= line.len or line[i + 1] != ' ':
          error("Invalid start of a comment", p.line, i)
        continue
      of '[', '|', ']':
        parse_table(p, line)
        continue
      else: discard
    if line[i] == ' ':
      error("Tabs are required for indentation", p.line, i)
    if line.strip(trailing=false) == "```":
      parse_literal_block(p)
      continue
    if i + 1 < line.len and line[i] in {'-', '.'} and line[i + 1] == ' ':
      parse_list(p, line[i + 2..^1], ordered=line[i] == '.')
      continue
    p.handler.text_start()
    parse_text(p, line[i..^1])
    while peek_line(p, line):
      if line.len == 0: break
      var tabs = 0
      skip_while(line, tabs, '\t')
      if tabs != i: break
      if tabs < line.len and line[tabs] == ' ':
        error("Tabs are required for indentation", p.line, tabs)
      if line.strip(trailing=false) == "```": break
      if tabs + 1 < line.len and
        line[tabs] in {'-', '.', '#', ';', '[', '|', ']'}:
        break
      discard read_line(p, line)
      p.handler.newline()
      parse_text(p, line[tabs..^1])
    p.handler.text_end()
  sync_indent(p, 0)


proc parse_scdoc*(input: Stream, handler: ScdocHandler) =
  ## Reads scdoc from the provided stream and issues parsing events to
  ## the provided handler.
  var parser = ScdocParser(stream: input, handler: handler)
  parser.handler.doc_start()
  parse_preamble(parser)
  parse_document(parser)
  parser.handler.doc_end()



when is_main_module and not defined(js):
  import std/parseopt


  const USAGE = """Usage: mancia [options] [format] < input.scd > output

  Options:
    -v, --version       Show version information
    -h, --help          Show this help message

  Formats:
    roff   Generate roff format for man pages (default)
    rst    Generate reStructuredText
  """


  proc main() =
    var
      handler = roff_handler
      p = init_opt_parser(short_no_val={'h', 'v'},
                          long_no_val= @["help", "version"], mode=LaxMode)
    while true:
      p.next()
      case p.kind
      of cmd_end: break
      of cmd_short_option, cmd_long_option:
        case p.key
        of "v", "version": stdout.write_line("mancia version " & VERSION); quit(0)
        of "h", "help": stdout.write_line(USAGE); quit(0)
        else:
          stderr.write_line("Error: Unknown option '", p.key, "'")
          stderr.write(USAGE)
          quit(1)
      of cmd_argument:
        case p.key
        of "roff": discard
        of "rst": handler = rst_handler
        else:
          stderr.write_line("Error: Unknown format '", p.key, "'")
          stderr.write_line("Supported formats: roff, rst")
          quit(1)
    let
      input = new_file_stream(stdin)
      output = new_file_stream(stdout)
    defer:
      input.close()
      output.close()
    try:
      parse_scdoc(input, handler(output))
    except CatchableError as ex:
      stderr.write_line(ex.msg)
      quit(1)
    quit(0)


  main()

