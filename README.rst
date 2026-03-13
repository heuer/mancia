mancia – scdoc to man page and reStructuredText converter
=========================================================

Mancia (Italian for "tip") is a command-line utility for converting the scdoc
format to man(7) roff and reStructuredText (rst).

For more information about the scdoc format, see
`scdoc(5) <https://manpages.debian.org/unstable/scdoc/scdoc.5.en.html>`_ and
`mancia(5) <https://mancia.readthedocs.io/en/latest/man/mancia.5.html>`_.


It can be utilized as Nim library and may be used to convert scdoc input into
other formats as well, such as HTML or Markdown, if an appropriate handler is
implemented (the parser does not care about the output, it just reports
events to a handler).

An additional `Python package <https://pypi.org/project/mancia/>`_ provides
functionality for using mancia as Python library and within Sphinx.


Documentation
-------------

See `<https://mancia.readthedocs.io/>`_ for the documentation.


Similar projects
^^^^^^^^^^^^^^^^
* `scdoc <https://git.sr.ht/~sircmpwn/scdoc>`_

