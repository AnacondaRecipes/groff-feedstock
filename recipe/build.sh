set -x

autoreconf -vfi
./configure --prefix=$PREFIX

# Workaround for long shebang lines
find $SRC_DIR -type f | \
    xargs -L1 perl -i.bak \
        -pe 's,^#!\@PERL\@ -w,#!/usr/bin/env perl,;' \
        -pe "s,perl -w,perl,;" \
        -pe "s,$PREFIX/bin/perl,/usr/bin/env perl,;"

# Workaround for a Makefile dep-graph race on install:
# /usr/bin/install: cannot stat './font/devpdf/download': No such file or directory
# 1.22.4 used the build_font_files convenience target; 1.24.x dropped it.
make -j${CPU_COUNT} font/devpdf/download
make -j${CPU_COUNT} install
make check
