tarball=hello-test-1.1.tgz

function test_build {
    make
}

function test_deploy {
    put hello  $BOARD_TESTDIR/fuego.$TESTDIR/
}

function test_run {
    report "cd $BOARD_TESTDIR/fuego.$TESTDIR; \
        ./hello $FUNCTIONAL_HELLO_WORLD_ARG"
}

function test_processing {
    log_compare "$TESTDIR" "1" "SUCCESS" "p"
}
