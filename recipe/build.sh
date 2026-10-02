#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# conda-forge 1.24.2: texinfo's texindex looks up awk via TEXINDEX_AWK.
# Point it at conda gawk in BUILD_PREFIX, not /usr/bin/awk.
export TEXINDEX_AWK="${BUILD_PREFIX}/bin/awk"

autoreconf --force --verbose --install

# Same as AR 1.22.4: only --prefix. Do not pass --without-x / --without-gs /
# --without-urw-fonts — those were never enabled on pkgs/main (no X, gs, or
# URW fonts in the PBP env). Autoconf then selects gropdf "basic" (14 PDF
# standard fonts), which is groff 1.24.0 restoring 1.23.0 behaviour
# (ChangeLog 2026-01-20). Do not pass Alpine's --disable-rpath: that is a
# musl packaging flag; conda compilers already write our RPATH.
#
# Not vendoring Artifex urw-base35-fonts (AGPL-3.0). Debian/Gentoo use a
# system fonts-urw-base35 / media-fonts/urw-fonts package; conda-forge and
# Nix (enableUrwFonts) vendor the tarball. We cannot ship AGPL on main.
./configure --prefix="${PREFIX}"

# Workaround for long shebang lines
find "${SRC_DIR}" -type f | \
    xargs -L1 perl -i.bak \
        -pe 's,^#!\@PERL\@ -w,#!/usr/bin/env perl,;' \
        -pe "s,perl -w,perl,;" \
        -pe "s,${PREFIX}/bin/perl,/usr/bin/env perl,;"

# 1.22.4 needed a pre-install `make font/devpdf/build_font_files` because
# that stamp target generated font/devpdf/download and the Makefile dep
# graph could race (`install: cannot stat './font/devpdf/download'`).
# 1.24.2 deleted that stamp; `font/devpdf/download` is a real target with
# explicit deps (ChangeLog 2026-01-26 / font/devpdf/devpdf.am). Do not
# invoke the old name — it is gone.
#
# A *different* parallel-install race remains on 1.24.2 (Gentoo #983579:
# `install: ... tty.tmac: File exists`). Compile in parallel, install
# serially, matching Gentoo 1.24.2.
make -j"${CPU_COUNT}"
make -j1 install
make check
