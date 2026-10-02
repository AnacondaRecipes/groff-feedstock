#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# texinfo/texindex looks up awk via this (conda-forge groff 1.24.2)
export TEXINDEX_AWK=${BUILD_PREFIX}/bin/awk

# conda-forge 1.24.2: URW base35 fonts as a second source so gropdf can
# generate font/devpdf/download. ghostscript/netpbm are not on pkgs/main;
# HAVE_URW_FONTS is enough for the download target.
autoreconf --force --verbose --install
./configure --prefix=$PREFIX --with-urw-fonts-dir=${SRC_DIR}/urw-base35-fonts/fonts

# Workaround for long shebang lines
find $SRC_DIR -type f | \
    xargs -L1 perl -i.bak \
        -pe 's,^#!\@PERL\@ -w,#!/usr/bin/env perl,;' \
        -pe "s,perl -w,perl,;" \
        -pe "s,$PREFIX/bin/perl,/usr/bin/env perl,;"

make -j${CPU_COUNT} install
make check
