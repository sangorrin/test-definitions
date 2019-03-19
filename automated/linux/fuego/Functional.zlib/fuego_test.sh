tarball=zlib-1.2.3.tar.bz2

test_build() {
    install_deps "build-essential" "$SKIP_INSTALL"
    ./configure --includedir=/usr/include --libdir=/usr/lib
    make >/dev/null
}

test_deploy() {
	put example minigzip  $BOARD_TESTDIR/fuego.$TESTDIR/
}

test_run() {
	report "cd $BOARD_TESTDIR/fuego.$TESTDIR; echo hello world | ./minigzip | ./minigzip -d || \
	echo ' minigzip test FAILED '
	if ./example; then \
	echo ' zlib test OK '; \
	else \
	echo ' zlib test FAILED '; \
	fi"  
}

test_processing() {
	P_CRIT="zlib test OK"
	N_CRIT="zlib test FAILED"

	log_compare "$TESTDIR" "1" "${P_CRIT}" "p"
	log_compare "$TESTDIR" "0" "${N_CRIT}" "n"
}




