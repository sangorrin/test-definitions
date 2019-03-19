#!/bin/sh
# Copyright (c) 2019 Toshiba corp.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

usage() {
	echo "Usage: $0 -d test [-sv]" 1>&2
	echo " -d test to run (e.g.: Functional.hello_world)"
	echo " -s skip dependency installs"
	echo " -v verbose mode"
	echo " example:"
	echo " $0 -d Functional.hello_world -s -v"
	exit 1
}

while getopts "d:sv" o; do
	case "$o" in
		d) TEST="${OPTARG}" ;;
		s) SKIP_INSTALL='true' ;;
		v) VERBOSE=1 ;;
		*) usage ;;
	esac
done

[ -z "${TEST}" ] && usage

# output dir
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE
mkdir -p "${OUTPUT}"

# log dir
LOGDIR="$OUTPUT/logs/"
TEST_LOG="${LOGDIR}/testlog.txt"
mkdir -p "${LOGDIR}"

# build directory
BUILD_DIR="$OUTPUT/build"
mkdir -p "${BUILD_DIR}"

# deploy and run directory (see $BOARD_TESTDIR/fuego.$TESTDIR in tests)
BOARD_TESTDIR=$OUTPUT
TESTDIR=$TEST
mkdir -p "$BOARD_TESTDIR/fuego.$TESTDIR"

# test definition folder
TEST_HOME="$(pwd)/$TEST"

. ../../lib/sh-test-lib

# $1 is the function to call, $2... have arguments to the function
call_if_present() {
	if type "$1" 2>/dev/null | grep -q 'function'; then
		$@ ;
	else
		return 0
	fi
}

# $1 = local file (source); $2 = remote file (destination)
put() {
	cp -r "$@"
}

# $1 - command to execute
cmd() {
	/bin/sh -c "$@"
}

abort_job() {
	error_fatal "$1"
}

# check is variable is set and fail if otherwise
# $1 = variable to check
# $2 = optional message if variable is missing
assert_define () {
    varname=$1
    if [ -z "${!varname}" ]
    then
        if [ -n "$2" ]  ; then
            msg="$2"
        else
            msg="Make sure you use the correct overlays and specs for this test/benchmark."
        fi
        abort_job "$1 is not defined. $msg"
    fi
}

report() {
	# $1 - remote shell command, $2 - test log file.
	RETCODE=/tmp/$$-${RANDOM}
	touch $RETCODE
	cmd "{ $1; echo \$? > $RETCODE; } 2>&1 | tee $LOGDIR/testlog.txt"
	RESULT=$(cat $RETCODE)
	rm -f $RETCODE
	export REPORT_RETURN_VALUE=${RESULT}
	return ${RESULT}
}

log_compare() {
    # 1 - $TESTDIR, 2 - number of results, 3 - Regex, 4 - n, p (i.e. negative or positive)
    local RETURN_VALUE=0

    if [ -f ${TEST_LOG} ]; then
        current_count=`cat ${LOGDIR}/testlog.txt | grep -E "${3}" 2>&1 | wc -l`
        if [ "$4" = "p" ]; then
            if [ $current_count -ge $2 ] ; then
                echo "log_compare: pattern '$3' found $current_count times (expected greater or equal than $2)"
            else
                echo "ERROR: log_compare: pattern '$3' found $current_count times (expected greater or equal than $2)"
                RETURN_VALUE=1
            fi
        fi

        if [ "$4" = "n" ]; then
            if [ $current_count -le $2 ] ; then
                echo "log_compare: pattern '$3' found $current_count times (expected less or equal than $2)"
            else
                echo "ERROR: log_compare: pattern '$3' found $current_count times (expected less or equal than $2)"
                RETURN_VALUE=1
            fi
        fi
    else
        echo -e "\nFuego error reason: '$TEST_LOG' is missing.\n"
        RETURN_VALUE=1
    fi

    return $RETURN_VALUE
}

. $PWD/$TEST/fuego_test.sh

if [ -n "$tarball" ]; then
	tar xvf $TESTDIR/$tarball -C $BUILD_DIR --strip-components=1
fi

call_if_present test_pre_check
cd $BUILD_DIR
call_if_present test_build
call_if_present test_deploy
call_if_present test_run
call_if_present test_fetch_results
call_if_present test_processing
check_return "$TEST"
call_if_present test_cleanup

