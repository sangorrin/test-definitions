tarball=hello-test-1.1.tgz

test_pre_check() {
    install_deps "build-essential"
}

test_build() {
    make
}

test_deploy() {
    put hello  $BOARD_TESTDIR/fuego.$TESTDIR/
}

test_run() {
    report "cd $BOARD_TESTDIR/fuego.$TESTDIR; \
        ./hello $FUNCTIONAL_HELLO_WORLD_ARG"
}

test_processing() {
    log_compare "$TESTDIR" "1" "SUCCESS" "p"
}
