Usage
=====

mancia is a command-line utility to generate man pages from scdoc files,
see also :doc:`mancia(1) <man/mancia.1>`.

It can be used as follows:

.. code:: bash

    mancia < input.1.scd > output.1

This will read the scdoc file `input.1.scd` and write the generated man page
to `output.1`. The output file can then be installed in the appropriate
location for man pages on the system, such as `/usr/share/man/man1/` for
section 1 man pages.

While its main purpose is to generate man pages, mancia can also be used to
generate reStructuredText (rst) output from scdoc files.

To do this, use the `rst` option:

.. code:: bash

    mancia rst < input.1.scd > output.1.rst

See :doc:`roff-rst-differences` for differences and limitations of the rst
output compared to the roff output.


