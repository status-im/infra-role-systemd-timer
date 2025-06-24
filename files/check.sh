#!/usr/bin/env bash
# vim: ft=bash

# Helpers
function is-enabled() { systemctl is-enabled $@ > /dev/null; }
function is-active() { systemctl is-active $@ > /dev/null; }
function is-failed() { systemctl is-failed $@ > /dev/null; }
function list-timer() { systemctl --no-pager -q -all list-timers $@; }
function status() { systemctl --no-pager -o cat -n 5 -q status $@; }
function print() { echo; list-timer "${NAME}.timer"; echo; status "${NAME}.service"; }
function success() { exit 0; }
function warning() { exit 1; }
function failure() { exit 2; }

SWITCH="ENABLED"

# Parse CLI flags
for i in "$@"; do
  case $i in
    --name=*)   NAME="${i#*=}";                 shift;;
    --disabled) SWITCH="DISABLED";              shift;;
    --warning)  WARNING=1;                      shift;;
    -*|--*)     echo "ERROR Unknown option $i"; exit 1;;
  esac
done

[[ -z "${NAME}" ]]  && { echo "No timer name provided!"; exit 1; }

# Check service and timer state.
TIMER_SWITCH=$(is-enabled ${NAME}.timer && echo "ENABLED" || echo "DISABLED")
TIMER_STATUS=$(is-active  ${NAME}.timer && echo "ACTIVE"  || echo "INACTIVE")
TIMER_HEALTH=$(is-failed  ${NAME}.timer && echo "FAILED"  || echo "HEALTHY")
SERVICE_SWITCH=$(is-enabled ${NAME}.service && echo "ENABLED" || echo "DISABLED")
SERVICE_STATUS=$(is-active  ${NAME}.service && echo "ACTIVE"  || echo "INACTIVE")
SERVICE_HEALTH=$(is-failed  ${NAME}.service && echo "FAILED"  || echo "HEALTHY")

# Print current state.
echo "${NAME}.timer: ${TIMER_SWITCH}, ${TIMER_STATUS}, ${TIMER_HEALTH}"
echo "${NAME}.service: ${SERVICE_SWITCH}, ${SERVICE_STATUS}, ${SERVICE_HEALTH}"

# Verify health.
if [[ "${TIMER_SWITCH}" != "${SWITCH}" ]]; then
    print
    if [[ "${SWITCH}" == "ENABLED" ]]; then
        if [[ "${WARNING}" == 1 ]]; then warning; else failure; fi
    else
        warning
    fi
fi
if [[ "${TIMER_HEALTH}"   != "HEALTHY" ]] ||
   [[ "${SERVICE_HEALTH}" != "HEALTHY" ]] ;then
    print
    if [[ "${WARNING}" == 1 ]]; then warning; else failure; fi
fi
