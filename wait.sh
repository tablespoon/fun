#!/bin/bash

WAIT_SHM_FILE="/dev/shm/wait_output.$$"
WAIT_PROGRESS_ANIMATION="\ | / -"

WAIT_runChild() {
	$1 &>"$WAIT_SHM_FILE"
	kill -s SIGHUP $$
}

WAIT_jobDone() {
	wait_output=$(<"$WAIT_SHM_FILE")
	printf '\r\033[K' 1>&2
	break 2
}

WAIT_waitForHUP() {
	trap WAIT_jobDone SIGHUP
	local i

	printf "%s " "$@" 1>&2
	while :; do
		for i in $WAIT_PROGRESS_ANIMATION; do
			printf "%s" "$i" 1>&2
			sleep .1
			printf "\b" 1>&2
		done
	done
}

WAIT_cleanup() {
	ps -o ppid,pid $WAIT_child_pid | awk -v parent=$$ '$1==parent { print $2 }' | xargs -r kill 2>/dev/null
	rm -f "$WAIT_SHM_FILE" &>/dev/null
}

WAIT() {
	trap WAIT_cleanup EXIT
	WAIT_runChild "$1" &
	WAIT_child_pid=$!
	WAIT_waitForHUP "$2"
	WAIT_cleanup
}
