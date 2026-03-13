#
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Copyright (c) 2026 -- Lars Heuer
#
"""\
Nox test runner configuration.
"""
import os
import sys
import re
from functools import partial
from itertools import chain
import shutil
import nox

_PY_DEFAULT_VERSION = sys.version[:4]
_PY_VERSIONS = [_PY_DEFAULT_VERSION]

nox.options.sessions = chain([f'test-{version}' for version in _PY_VERSIONS], ['lint'])


def _compile_ext(session):
    """\

    """
    session.run('nim', 'c', '--app:lib', '-d:release',
                '--out:mancia/converter.so', '--threads:on', '--passL:-s',
                '--opt:size', 'mancia/converter', external=True)


@nox.session(python=_PY_VERSIONS)
def test(session):
    """\
    Run test suite.
    """
    _compile_ext(session)
    session.install('-Ur', 'tests/requirements.txt')
    session.install('.')
    session.run('pytest')


@nox.session(python=_PY_DEFAULT_VERSION)
def docs(session):
    """\
    Build the documentation.
    """
    _compile_ext(session)
    session.install('-Ur', '../docs/requirements.txt')
    output_dir = os.path.abspath(os.path.join(session.create_tmp(), 'output'))
    shutil.rmtree(output_dir, ignore_errors=True)
    doctrees, html = map(partial(os.path.join, output_dir), ['doctrees', 'html'])
    session.install('.')
    session.cd('../docs')
    sphinx_build = partial(session.run, 'sphinx-build', '-W', '-d', doctrees, '.')
    sphinx_build('-b', 'html', html)


@nox.session(python=_PY_DEFAULT_VERSION)
def lint(session):
    """\
    Run linters.
    """
    session.install('ruff', 'mypy')
    session.run('mypy', 'mancia')
    session.run('ruff', 'check', '.')


@nox.session(name='build', python=_PY_DEFAULT_VERSION)
def build(session):
    """\
    Builds a wheel from local source.
    """
    session.install('flit-core', 'build')
    _compile_ext(session)
    shutil.rmtree('dist', ignore_errors=True)
    session.run('python', '-m', 'build', '--wheel', '--no-isolation', '-o', 'dist')


#
# Release related tasks
# 1. nox -e start-release -- version-number
# 2. run tests, update docs, update changes
# 3. nox -e finish-release -- version-number
# 4. git push / git push origin --tags
# 5. nox -e build-release -- version-number
# 6. nox -e upload-release
#


@nox.session(name='start-release', python=_PY_DEFAULT_VERSION)
def start_release(session):
    """\
    Prepares a release.

    * Creates a new branch release-VERSION_NUMBER
    * Changes the version number in segno.__version__ to VERSION_NUMBER
    """
    session.install('packaging')
    git = partial(session.run, 'git', external=True)
    git('checkout', 'main')
    prev_version = _get_current_version(session)
    version = _validate_version(session)
    valid_version = bool(int(session.run('python', '-c',
                    'from packaging.version import parse;'
                    f'prev_version = parse("{prev_version}");'
                    f'next_version = parse("{version}");'
                    'print(1 if prev_version < next_version else 0)',
                     silent=True)))
    if not valid_version:
        session.error('Invalid version')
    release_branch = f'release-{version}'
    git('checkout', '-b', release_branch, 'master')
    _change_version(session, prev_version, version)
    git('add', 'mancia/__init__.py')
    session.log(f'Now on branch "{release_branch}".'
                'Run the tests, run nox -e docs. Update and add CHANGES')
    session.log('Commit any changes.')
    session.log(f'When done, call nox -e finish-release -- {version}')


@nox.session(name='finish-release', python=_PY_DEFAULT_VERSION)
def finish_release(session):
    """\
    Finishes the release.

    * Merges the branch release-VERSION_NUMBER into master
    * Creates a tag VERSION_NUMBER
    * Increments the development version
    """
    version = _validate_version(session)
    release_branch = f'release-{version}'
    git = partial(session.run, 'git', external=True)
    git('checkout', 'main')
    git('merge', '--no-ff', release_branch, '-m',
        f'Merge release branch {release_branch}')
    git('tag', '-a', version, '-m', f'Release {version}')
    git('branch', '-d', release_branch)
    version_parts = version.split('.')
    patch = str(int(version_parts[2]) + 1)
    next_version = '.'.join(chain(version_parts[:2], patch)) + '.dev'
    _change_version(session, version, next_version)
    git('add', 'mancia/__init__.py')
    git('commit', '-m', 'Incremented development version')
    session.log('Finished. Run git push / git push origin --tags and '
                f'nox -e build-release -- {version} / nox -e upload-release')


@nox.session(name='build-release', python=_PY_DEFAULT_VERSION)
def build_release(session):
    """\
    Builds a release: Creates sdist and wheel
    """
    version = _validate_version(session)
    session.install('flit-core')
    git = partial(session.run, 'git', external=True)
    git('fetch')
    git('fetch', '--tags')
    git('checkout', version)
    _compile_ext(session)
    shutil.rmtree('dist', ignore_errors=True)
    session.run('flit', 'build', external=True)
    git('checkout', 'main')


@nox.session(name='upload-release', python=_PY_DEFAULT_VERSION)
def upload_release(session):
    """\
    Uploads a release to PyPI
    """
    session.install('twine')
    twine = partial(session.run, 'twine')
    twine('check', 'dist/*')
    twine('upload', 'dist/*')


def _validate_version(session):
    if not session.posargs:
        session.error('No release version provided')
    elif len(session.posargs) > 1:
        session.error('Too many arguments')
    version = session.posargs[0]
    if not re.match(r'^[0-9]+\.[0-9]+\.[0-9]+$', version):
        session.error(f'Invalid version number: "{version}"')
    return version


def _get_current_version(session):
    """\
    Returns the current Segno version.
    """
    fn = os.path.abspath(os.path.join(os.path.dirname(__file__), 'mancia/__init__.py'))
    with open(fn, encoding='utf-8') as f:
        content = f.read()
    m = re.search(r'^__version__ = ["\']([^"\']+)["\']$', content, flags=re.MULTILINE)
    if m:
        return m.group(1)
    session.error('Cannot find any version information')


def _change_version(session, prev_version, next_version):
    """\
    Changes the mancia.__init__.__version__ from previous_version to next_version.
    """
    fn = os.path.abspath(os.path.join(os.path.dirname(__file__), 'mancia/__init__.py'))
    with open(fn, encoding='utf-8') as f:
        content = f.read()
    new_content = re.sub(rf'^(__version__ = ["\'])({re.escape(prev_version)})(["\'])$',
                         rf'\g<1>{next_version}\g<3>', content,
                         flags=re.MULTILINE)
    if content != new_content:
        with open(fn, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return
    session.error(f'Cannot modify version. Provided: "{prev_version}"'
                  f'(previous) "{next_version}" (next)')

