MANCIA(5)

# NAME

scdoc - document format for writing manual pages


# SYNTAX

The syntax is the same as described in _scdoc_(5), written by Drew
DeVault and licensed under the MIT, but it is repeated here
in other words. _scdoc_(5) is the primary reference for the syntax.

Input files must use the UTF-8 encoding.


## Preamble

Each file must begin with the following preamble:

	_NAME_(_section_) ["left_footer" ["center_header"]]

_NAME_ is the name of the man page, and _section_ is the section it is
written for (see _man_(1) for information on manual sections).

Although not enforced, the _NAME_ should be provided in uppercase letters.

_left\_footer_ and _center\_header_ are optional arguments which set the text
positioned at those locations in the generated man page, and *must* be
surrounded with double quotes.


## Section headers

A section of a man page is indicated by one or two hash signs(_#_). Each
header must have an empty line on either side.

Main sections like _NAME_, _SYNOPSIS_, and _DESCRIPTION_ etc. should be
provided in upper case letters.

```
# NAME
```

A subsection is indicated by two hash signs and is usually provided in title
cases:

```
## Subsection
```

## Paragraphs

Begin a new paragraph with an empty line.

Newline characters are ignored, they are treated like whitespace within the
current paragraph.

An input like

```
Now they know how many holes
it takes to fill the Albert Hall
```

is the same as

```
Now they know how many holes it takes to fill the Albert Hall
```

Both result in:

Now they know how many holes it takes to fill the Albert Hall


## Line breaks

To enforce an explicit line break, a line has to end with _\+\+_.

```
Listen++
Do you want to know a secret?
```

Result:

Listen++
Do you want to know a secret?


## Bullet lists

A list is introduced by an empty line, followed by any number of items. An item
is indicated by a line starting with a hyphen (-) followed by a space.
Subitems are indicated by additional indentation.

```
- Item 1
- Item 2
    - Subitem 1
    - Subitem 2
- Item 3
```

Result:

- Item 1
- Item 2
	- Subitem 1
	- Subitem 2
- Item 3

Long items in lists can be split into multiple lines by indenting the
subsequent line to the same level and two additional spaces.

```
- Item 1
- This is a long item that is split into multiple lines. The subsequent
  line is indented to the same level and two additional spaces.
- Item 3
```

Result:

- Item 1
- This is a long item that is split into multiple lines. The subsequent
  line is indented to the same level and two additional spaces.
- Item 3


Explicit line breaks can be used within list items as well:

```
- Item 1++
  This is still part of item 1.
- Item 2
```

Result:

- Item 1++
  This is still part of item 1.
- Item 2


## Enumerated lists

An enumerated list is introduced by an empty line, followed by any number of
items. An item is indicated by a line starting with a dot . followed by a space.

Subitems are indicated by additional indentation.

```
. Item 1
. Item 2
    . Subitem 1
    . Subitem 2
. Item 3
```

Result:

. Item 1
. Item 2
	. Subitem 1
	. Subitem 2
. Item 3


Enumerated list items can also be split into multiple lines or contain explicit
line breaks, just like bullet list items.

```
. Item 1
. This is a long item that is split into multiple lines. The subsequent
  line is indented to the same level and two additional spaces.
. Item 3++
  This is still part of item 3.
```

Result:

. Item 1
. This is a long item that is split into multiple lines. The subsequent
  line is indented to the same level and three additional spaces.
. Item 3++
  This is still part of item 3.


## Literal blocks

A literal block is a block of text that is not processed for formatting. It is
indicated by a line containing three backticks (_```_) before and after the
block.

Literal blocks are indented by one tab (four spaces) by default.

```
	\```
	This is a literal block. It will not be processed for formatting, so
	*bold* and _underlined_ text will not be interpreted.
	\```
```

Result:

```
This is a literal block. It will not be processed for formatting, so
*bold* and _underlined_ text will not be interpreted.
```

Note that _\\_ is still interpreted within literal blocks, which for example
can be useful to output _```_ inside of a literal block.


## Tables

Tables are introduced by an empty line, followed by a number of rows.

A vertical bar | indicates a new row, while a colon : introduces a new column.

Aside from the vertical bar, the first row accepts [ to indicate that all cells
should have a border, or ] to indicate that the a border is around the whole
table. | indicates a table with no borders at all.

A typical, left aligned table with explicit borders around all cells starts
with [[.

The row or column indicator must be followed by an alignment indicator.
If this is missing (symbolized by a whitespace), the cell inherits the
alignment of the cell above it.

scdoc supports [ for left alignment, - for centered content and ] for right
alignment.

The content of a cell is provided deliminted by space character after the
alignment indicator (which may be a space character as well).

Empty cells are permitted, but all rows must have the same number of columns.

Example:

```
[[ *Title*
:[ *Lead vocals*
:[ *Length*
|  Yellow Submarine
:  Starr
:] 2:40
|  Only a Northern Song
:  Harrison
:  3:24
|  All Together Now
:  McCartney
:  2:11
|  Hey Bulldog
:  Lennon
:  3:11
```


Result:

[[ *Title*
:[ *Lead vocals*
:[ *Length*
|  Yellow Submarine
:  Starr
:] 2:40
|  Only a Northern Song
:  Harrison
:  3:24
|  All Together Now
:  McCartney
:  2:11
|  Hey Bulldog
:  Lennon
:  3:11


In addition to the mentioned alignment characters, it is also possible to
enforce that a column should fill the available space with < for left aligned
cells, = for centered cells, and > for right aligned cells.

The cell content may be breaked into multiple lines by a newline character
and three additional spaces in the following line.

Explicit line breaks via ++ are not supported in tables.

```
[< *Title*
:[ *Author*
|  You Know My Name
   (Look Up the Number)
:  Lennon/McCartney
|  Everybody's Got Something to Hide
   Except Me and My Monkey
:  Lennon/McCartney
```


[< *Title*
:[ *Author*
|  You Know My Name
   (Look Up the Number)
:  Lennon/McCartney
|  Everybody's Got Something to Hide
   Except Me and My Monkey
:  Lennon/McCartney


## Comments

A comment is a line that starts with a semicolon (_;_) followed by a space and
the comment text.

```
; This is a comment
```


# CONVENTIONS

By convention, all scdoc documents should be hard wrapped at 80 columns.


# SEE ALSO

_mancia_(1), _scdoc_(5)

