Using mancia with Python and Sphinx
===================================

Mancia can be used in Python scripts and provides a Sphinx extension
to convert scdoc files to reStructuredText during the Sphinx build process.


Installation
------------

Mancia can be installed using pip:

.. code:: bash

   pip install mancia


Usage
-----

To use mancia in a Python script, you can import the `mancia.converter` module
and call either `to_rst` or `to_roff` to convert scdoc content to
reStructuredText or roff, respectively.

Here's an example of how to convert an scdoc file to reStructuredText:

.. code:: python

   from mancia.converter import to_rst

   with open('input.scd') as scdoc_file, \
        open('output.rst', 'w') as rst_file:
        rst_file.write(to_rst(scdoc_file.read()))


Command Line Interface
----------------------

The Python package also provides a command line interface (CLI) that allows
you to convert scdoc files to roff or reStructuredText directly from the
terminal.

.. code:: bash

   pymancia < input.scd > output


.. code:: bash

   pymancia --format rst < input.scd > output.rst



Sphinx Extension
-----------------

Mancia provides a Sphinx extension that allows to include scdoc files in
Sphinx documentation. To use the extension, add `mancia.sphinx_ext`
to the `extensions` list in the Sphinx `conf.py` file:

.. code:: python

   extensions = [
       'mancia.sphinx_ext',
       # other extensions...
   ]


Configuration
~~~~~~~~~~~~~

The Sphinx extension supports the following configuration options:

``scdoc_source_dir``
    The directory where your scdoc files are located.
    Default is ``man``.

``scdoc_output_dir``
    The directory where the converted reStructuredText files will be saved.
    Default is ``man``.

.. code:: python

   extensions = [
       'mancia.sphinx_ext',
       # other extensions...
   ]

   scdoc_source_dir = '../man/'
   scdoc_output_dir = './man/'



