tarball=Dhrystone.tar.bz2

test_pre_check() {
    assert_define BENCHMARK_DHRYSTONE_LOOPS
    install_deps "build-essential" "$SKIP_INSTALL"
}

test_build() {
    patch -p0 -N -s < $TEST_HOME/dhry_1.c.patch || return
    CFLAGS+=" -DTIME"
    LDFLAGS+=" -lm"
    make CFLAGS="$CFLAGS" LDFLAGS="$LDFLAGS"
}

test_deploy() {
    put dhrystone  $BOARD_TESTDIR/fuego.$TESTDIR/
}

test_run() {
    report "cd $BOARD_TESTDIR/fuego.$TESTDIR; ./dhrystone $BENCHMARK_DHRYSTONE_LOOPS"
}

test_processing() {
    log_compare "$TESTDIR" "0" "Please increase number of runs" "n"
    dhrystones=$(grep "Dhrystones per Second:" "${TEST_LOG}" | awk '{print $NF}')
    add_metric "Benchmark.Dhrystone.Score" "pass" "${dhrystones}" "dhrystones"
}

