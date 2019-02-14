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
	echo " $0 -c Functional.hello_world -s -v"
	exit 1
}

while getopts "d:s:v" o; do
	case "$o" in
		d) TEST="${OPTARG}" ;;
		s) SKIP_INSTALL=1 ;;
		v) VERBOSE=1 ;;
		*) usage ;;
	esac
done

[ -z "${TEST}" ] && usage

# output dir
OUTPUT="$(pwd)/output"
mkdir -p "${OUTPUT}"

# log dir
LOGDIR="$(pwd)/output/logs/"
RESULT_FILE="${LOGDIR}/result.txt"
TEST_LOG="${LOGDIR}/testlog.txt"
mkdir -p "${LOGDIR}"

# build directory
BUILD_DIR="$(pwd)/output/build"
mkdir -p "${BUILD_DIR}"

# deploy and run directory ($BOARD_TESTDIR/fuego.$TESTDIR)
BOARD_TESTDIR=$OUTPUT
TESTDIR=$TEST
DEPLOY_DIR=$OUTPUT/fuego.$TESTDIR
mkdir -p "${DEPLOY_DIR}"

. ../../lib/sh-test-lib

# $1 is the function to call, $2... have arguments to the function
function call_if_present {
	if declare -f -F $1 >/dev/null ; then
		$@ ;
	else
		return 0
	fi
}

# $1 = local file (source); $2 = remote file (destination)
function put {
	for par in "${@:1:$(($#-1))}"; do
		if [ "$par" != "-r" -a "$par" != "${@: -1}" ]; then
			cp -r "$par" "${@: -1}"
		fi
	done
}

# $1 - command to execute
function cmd {
	/bin/sh -c "$@"
}

function report {
	# $1 - remote shell command, $2 - test log file.
	RETCODE=/tmp/$$-${RANDOM}
	touch $RETCODE
	cmd "{ $1; echo \$? > $RETCODE; } 2>&1 | tee $LOGDIR/testlog.txt"
	RESULT=$(cat $RETCODE)
	rm -f $RETCODE
	export REPORT_RETURN_VALUE=${RESULT}
	return ${RESULT}
}

function log_compare {
    # 1 - $TESTDIR, 2 - number of results, 3 - Regex, 4 - n, p (i.e. negative or positive)
    local RETURN_VALUE=0
    local PARSED_LOGFILE="testlog.${4}.txt"

    if [ -f ${LOGDIR}/testlog.txt ]; then
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
        echo -e "\nFuego error reason: '$LOGDIR/testlog.txt' is missing.\n"
        RETURN_VALUE=1
    fi

    return $RETURN_VALUE
}

source $PWD/$TEST/fuego_test.sh

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
call_if_present test_cleanup

