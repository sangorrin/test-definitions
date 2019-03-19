tarball=bzip2-1.0.5.tar.gz

test_build() {
    echo "#!/bin/sh
    is_busybox() {
        realname=\$(readlink -f \$1)
        if echo "\$realname" | grep -q "busybox"; then return 0; fi
        return 1
    }
    if bzip2 -1  < sample1.ref > sample1.rb2; then echo 'TEST-1 OK'; else echo 'TEST-1 FAILED'; fi;
    if bzip2 -2  < sample2.ref > sample2.rb2; then echo 'TEST-2 OK'; else echo 'TEST-2 FAILED'; fi;
    if bzip2 -3  < sample3.ref > sample3.rb2; then echo 'TEST-3 OK'; else echo 'TEST-3 FAILED'; fi;
    if bzip2 -d  < sample1.bz2 > sample1.tst; then echo 'TEST-4 OK'; else echo 'TEST-4 FAILED'; fi;
    if bzip2 -d  < sample2.bz2 > sample2.tst; then echo 'TEST-5 OK'; else echo 'TEST-5 FAILED'; fi;
    if ( is_busybox \$(which bzip2) ); then
        if bzip2 -d < sample3.bz2 > sample3.tst; then echo 'TEST-6 OK'; else echo 'TEST-6 FAILED'; fi;
    else
        if bzip2 -ds < sample3.bz2 > sample3.tst; then echo 'TEST-6 OK'; else echo 'TEST-6 FAILED'; fi;
    fi
    if cmp sample1.bz2 sample1.rb2; then echo 'TEST-7 OK'; else echo 'TEST-7 FAILED'; fi;
    if cmp sample2.bz2 sample2.rb2; then echo 'TEST-8 OK'; else echo 'TEST-8 FAILED'; fi;
    if cmp sample3.bz2 sample3.rb2; then echo 'TEST-9 OK'; else echo 'TEST-9 FAILED'; fi;
    if cmp sample1.tst sample1.ref; then echo 'TEST-10 OK'; else echo 'TEST-10 FAILED'; fi;
    if cmp sample2.tst sample2.ref; then echo 'TEST-11 OK'; else echo 'TEST-11 FAILED'; fi;" > run-tests.sh
}

test_deploy() {
    put {sample*,run-tests.sh}  "$BOARD_TESTDIR/fuego.$TESTDIR/"
}

test_run() {
    report "cd $BOARD_TESTDIR/fuego.$TESTDIR; sh -v run-tests.sh 2>&1"
}

test_processing() {
    local RETURN_VALUE=0

    log_compare "$TESTDIR" "11" "^TEST.*OK" "p"
    if [ $? -ne 0 ]; then RETURN_VALUE=1; fi
    log_compare "$TESTDIR" "0" "^TEST.*FAILED" "n"
    if [ $? -ne 0 ]; then RETURN_VALUE=1; fi

    return $RETURN_VALUE
}


