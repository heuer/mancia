#
# mancia documentation build configuration file
#
import os
import sys

#sys.path.insert(0, os.path.abspath('../python'))

import mancia

extensions = [
    'mancia.sphinx_ext',
]

scdoc_source_dir = '../man/'
scdoc_output_dir = './man/'

templates_path = ['_templates']

highlight_language = 'none'

source_suffix = '.rst'

master_doc = 'index'

project = 'mancia'
copyright = '2026 Lars Heuer'
author = 'Lars Heuer'
version = mancia.__version__

language = 'en'

exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store', '.venv']

show_authors = False

html_theme = 'furo'
html_static_path = ['_static']
html_logo = '_static/logo.svg'
html_favicon = html_logo

html_theme_options = {
    "navigation_with_keys": True,
    'globaltoc_collapse': False
}

pygments_dark_style = 'lightbulb'

