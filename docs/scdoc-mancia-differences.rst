Differences between scdoc and mancia
====================================

Although mancia is designed to support the scdoc format and tries to to create
man pages which are rendered the same as the ones created by the
`scdoc <https://git.sr.ht/~sircmpwn/scdoc>`_ utility, there are some
difference between the two.


Nested lists
------------

mancia resets the item counter for nested lists, while scdoc does not.

Example:

.. code-block:: scdoc

    . Item 1
    . Item 2
        . Subitem 1
        . Subitem 2
    . Item 3


In scdoc, the output is::

    1. Item 1
    2. Item 2
       3. Subitem 1
       4. Subitem 2
    5. Item 3


In mancia, the output is::

    1. Item 1
    2. Item 2
       1. Subitem 1
       2. Subitem 2
    3. Item 3


Other differences
-----------------

If you find any other differences between scdoc and mancia, please report
them in the `issue tracker <https://github.com/heuer/mancia/issues>`_.
It is likely a bug in mancia.

