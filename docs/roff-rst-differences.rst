Output differences between roff and rst
=======================================

Even if the output of roff and reStructuredText (rst) should be similar,
there are some differences. The roff output provides more features than the
rst output:

* The reStructuredText output does not support the table and cell formatting
  options of scdoc.
* The information from the scdoc preamble is not included in the
  reStructuredText output (aside from the name and section).
* man uses usually underline for emphasis, while reStructuredText uses italic.

