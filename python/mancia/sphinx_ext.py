#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2026 -- Lars Heuer
#
"""\
Sphinx extension for automatic ``.scd`` to ``.rst`` conversion.

This extension takes ``.scd`` files from ``scdoc_source_dir`` and converts
them to ``.rst`` in the ``scdoc_output_dir``.
"""
from pathlib import Path
from sphinx.application import Sphinx
from .converter import to_rst


__all__ = ['convert_scdoc_files', 'setup']


def convert_scdoc_files(app: Sphinx):
    """\
    Takes the ``.scd`` files from the source directory and creates ``.rst``
    files in the output directory.
    """
    source_dir = Path(app.config.scdoc_source_dir or 'man')
    output_dir = Path(app.config.scdoc_output_dir or 'man')
    if not source_dir.exists():
        return
    output_dir.mkdir(parents=True, exist_ok=True)
    for scd_file in source_dir.glob('*.scd'):
        with open(scd_file) as fscd, \
             open(output_dir / (scd_file.stem + '.rst'), 'w') as frst:
            frst.write(to_rst(fscd.read()))


def setup(app: Sphinx):
    """\
    Setup the Sphinx extension.
    """
    from . import __version__
    app.add_config_value('scdoc_source_dir', default='man', rebuild='env')
    app.add_config_value('scdoc_output_dir', default='man', rebuild='env')
    app.connect('builder-inited', convert_scdoc_files)
    return {
        'version': __version__,
        'parallel_read_safe': True,
        'parallel_write_safe': True,
    }

