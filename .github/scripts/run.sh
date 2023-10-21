#!/usr/bin/env bash

set -m # Enable Job Control (handle SIGCHLD)

exit_status=0
pids=()
declare types

echo "before"

remove_pid() {
  new_pids=()
  for pid in "${pids[@]}"; do
    if [ "$pid" -ne "$1" ]; then
      new_pids+=($pid)
    fi
  done
  pids=("${new_pids[@]}")
}

stop_all() {
  echo "stop all unfinished processes"
  for pid in "${pids[@]}"; do
    echo "stopping pid ${pid}"
    kill -TERM $pid
  done
  for pid in "${pids[@]}"; do
    wait $pid
    echo "pid ${pid} stopped with $?"
  done
}

handle_sigchld() {
  trap ' ' CHLD
  echo "handle sigchld"
  for pid in "${pids[@]}"; do
    pid_status=$(ps -p ${pid} -o pid=,stat=)
    if [ "x${pid_status}" = "x" ]; then
      remove_pid $pid
      wait $pid
      pid_exit_code=$?
      if [ ${pid_exit_code} -ne 0 ]; then
        echo "Process ${pid} (${types[$pid]}) failed with code ${pid_exit_code}"
        exit_status=$pid_exit_code
        stop_all
      else
        echo "Process ${pid} (${types[$pid]}) finished successfully (${pid_exit_code})"
      fi
    fi
  done
  trap 'handle_sigchld' CHLD
}

trap 'handle_sigchld' CHLD

process1() {
  echo "$(date) process1 start"
  sleep 5
  echo "$(date) process1 done"
}

process2() {
  echo "$(date) process2 start"
  sleep 2
  echo "$(date) process2 done"
  exit 5
}

process1 > ./process1.out 2>&1 &
pids+=($!)
types[$!]="process1"
process2 > ./process2.out 2>&1 &
pids+=($!)
types[$!]="process2"
echo "begin wait"
wait
echo "exit status ${exit_status}"
exit $exit_status