# fuego_board_function_lib.sh
#
# This shell library has a set of utility functions for
# performing actions on the board under test
#

# Use the following defaults, in case routines to detect values
# are not called.  This should show up in error
# messages so that users of the library can detect that
# the required precursor functions were not called

init_manager="init_manager-not-set"
logger_service="logger_service-not-set"
service_status="unknown"

# set_init_manager:
#   detects and sets the init_manager variable, which indicates which
#   initialization control program (process 1) is used on this board
set_init_manager() {
    if ls -l /proc/1/exe | grep systemd 2>&1 >/dev/null ; then
        init_manager="systemd"
    else
        init_manager="sysvinit"
    fi
}

# detect_logger_service
#   determine the name of the logger service on this board
# returns: name of logger service
detect_logger_service() {
    if [ "$init_manager" = "systemd" ] ; then
        logger_service="syslog-ng"
    else
        logger_service="syslog"
    fi
    echo $logger_service
}

# exec_service_on_target:
#   perform an action for a service on the this board
# $1: service name
# $2: action to perform (e.g. start, stop, restart)
# relies on $init_manager being set prior to call
exec_service_on_target() {
    if [ "$init_manager" = "systemd" ]
    then
        systemctl $2 $1
    else
        service $1 $2
    fi
}

# detect_active_eth_device
#   Detect the name of actived ethernet device
# returns: name of actived ethernet device
detect_active_eth_device() {
    ifconfig | cut -d' ' -f1 | sed '/^$/d' > driver_list
    for line in $(cat driver_list)
    do
        if ethtool $line | grep "baseT" > /dev/null
        then
            echo "$line"
            return
        fi
    done
    echo "have no Ethernet device"
}

# get_service_status:
#  get status of service
# returns: status of service
get_service_status() {
    if [ "$init_manager" = "systemd" ]
    then
        service_status=$(systemctl is-active $1)
    else
        service_status="unknown"
        if service $1 status | grep "is running"
        then
            service_status="active"
        else
            if service $1 status | grep "is stopped"
            then
                service_status="inactive"
            fi
        fi
    fi
    echo $service_status
}
