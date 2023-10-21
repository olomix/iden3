#!/usr/bin/env bash

set -m # Enable Job Control (handle SIGCHLD)

npm install -g newman || exit 1

exit_status=0
pids=()
declare types

echo "before"

remove_pid() {
  local new_pids=()
  local pid
  for pid in "${pids[@]}"; do
    if [ "$pid" -ne "$1" ]; then
      new_pids+=($pid)
    fi
  done
  pids=("${new_pids[@]}")
}

stop_all() {
  echo "Terminate all unfinished processes"
  for pid in "${pids[@]}"; do
    echo "Killing process '${types[$pid]}' (pid:${pid})"
    kill -TERM $pid
  done
  for pid in "${pids[@]}"; do
    wait $pid
    echo "Process '${types[$pid]}' (pid:${pid}) was stopped with exit code $?"
  done
}

handle_sigchld() {
  trap ' ' CHLD
  echo "Handle SIGCHLD, (PIDS to check: ${pids[@]})"
  local pid
  for pid in "${pids[@]}"; do
    pid_status=$(ps -p ${pid} -o pid=,stat=)
    if [ "x${pid_status}" = "x" ]; then
      echo "Process '${types[$pid]}' (pid:${pid}) is not running"
      remove_pid $pid
      wait $pid
      pid_exit_code=$?
      echo "Process '${types[$pid]}' (pid:${pid}) exit code: ${pid_exit_code}"
      if [ ${pid_exit_code} -ne 0 ]; then
        echo "Process '${types[$pid]}' (pid:${pid}) failed"
        exit_status=$pid_exit_code
        stop_all
        return
      else
        echo "Process '${types[$pid]}' (pid:${pid}) finished successfully"
      fi
    fi
  done
  trap 'handle_sigchld' CHLD
}

newman run \
  .github/testcases/get_registry_manifests.postman_collection.json \
  --bail --verbose > newman-error.out 2>&1 &
pids+=($!)
types[$!]="newman-error"

newman run \
  .github/testcases/get_registry_manifests.postman_collection.json \
  --bail --verbose > newman-ok.out 2>&1 &
pids+=($!)
types[$!]="newman-ok"

echo "PIDS: ${pids[@]}"
trap 'handle_sigchld' CHLD

handle_sigchld

echo "Waiting for newmans"
wait

trap ' ' CHLD
echo "Exit status ${exit_status}"
exit $exit_status
