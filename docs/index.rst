mancia – scdoc to man page and reStructuredText converter
=========================================================

Mancia (Italian for "tip") is a command-line utility for converting the scdoc
format to man(7) roff and reStructuredText (rst).

For more information about the scdoc format, see
`scdoc(5) <https://manpages.debian.org/unstable/scdoc/scdoc.5.en.html>`_ and
:doc:`mancia(5) <man/mancia.5>`.

It can be utilized as Nim library and may be used to convert scdoc input into
other formats as well, such as HTML or Markdown, if an appropriate handler is
implemented (the parser does not care about the output, it just reports
events to a handler).

An additional Python package provides functionality for using mancia as Python
library and within Sphinx.


Links
-----

* `GitHub homepage <https://github.com/heuer/mancia>`_
* `Issue tracker <https://github.com/heuer/mancia/issues>`_
* `PyPI homepage <https://pypi.org/project/mancia/>`_
* `scdoc homepage <https://git.sr.ht/~sircmpwn/scdoc>`_


Contents
--------

.. toctree::
    :maxdepth: 4

    usage
    scdoc-mancia-differences
    roff-rst-differences
    man/index
    python-and-sphinx
    changes

