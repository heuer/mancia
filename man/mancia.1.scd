MANCIA(1)

# NAME

mancia - generate _man_(7) manual page


# SYNOPSIS

*mancia* [format] < _input_


# DESCRIPTION

The mancia command line utility reads _scdoc_(5) syntax from the standard input
and writes _man_(7) style roff to the standard output. Alternatively, mancia
can also generate reStructuredText.


# FORMATS

The mancia utility can generate two formats: _man_(7) roff and reStructuredText.
The format is determined by the command line argument passed to mancia. If no
argument is provided, the default format is roff.


# SEE ALSO

_mancia_(5), _scdoc_(5)

