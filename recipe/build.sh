#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

# texinfo/texindex looks up awk via this
export TEXINDEX_AWK=${BUILD_PREFIX}/bin/awk

# Do not vendor AGPL URW base35 fonts (conda-forge 1.24.2 does).
# Alpine 1.24.2, MSYS2, and OpenBSD all build without --with-urw-fonts-dir.
# --without-urw-fonts skips the U foundry; --without-gs because ghostscript
# is not on pkgs/main. gropdf still works with groff's built-in PDF fonts.
autoreconf --force --verbose --install
./configure \
    --prefix="${PREFIX}" \
    --without-x \
    --without-gs \
    --without-urw-fonts \
    --disable-rpath

# Workaround for long shebang lines
find "${SRC_DIR}" -type f | \
    xargs -L1 perl -i.bak \
        -pe 's,^#!\@PERL\@ -w,#!/usr/bin/env perl,;' \
        -pe "s,perl -w,perl,;" \
        -pe "s,${PREFIX}/bin/perl,/usr/bin/env perl,;"

make -j"${CPU_COUNT}" install
make check
