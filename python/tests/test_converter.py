#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2026 -- Lars Heuer
#
"""\
Tests against the converter.

Since all tests are done against the Nim implementation, we just check that
the converter returns something.
"""
from mancia.converter import to_rst, to_roff

_SCDOC = """NAME(1)

# NAME

"""


def test_rst():
    res = to_rst(_SCDOC)
    assert res
    assert "NAME(1)" in res
    assert """
NAME
====
""" in res


def test_roff():
    res = to_roff(_SCDOC)
    assert res
    assert '.TH "NAME" "1"' in res
    assert ".SH NAME" in res

