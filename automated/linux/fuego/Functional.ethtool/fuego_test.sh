test_pre_check() {
    install_deps "ethtool" "$SKIP_INSTALL"
    is_on_target_path ethtool PROGRAM_ETHTOOL
    assert_define PROGRAM_ETHTOOL "Missing 'ethtool' program on target board"
}

test_deploy() {
    put $TEST_HOME/ethtool_test.sh $BOARD_TESTDIR/fuego.$TESTDIR/
    put $TEST_HOME/../fuego_board_function_lib.sh $BOARD_TESTDIR/fuego.$TESTDIR
    put -r $TEST_HOME/tests $BOARD_TESTDIR/fuego.$TESTDIR/
}

test_run() {
    report "cd $BOARD_TESTDIR/fuego.$TESTDIR;\
    ./ethtool_test.sh"
}

test_processing() {
    log_compare "$TESTDIR" "0" "TEST-FAIL" "n"
}
