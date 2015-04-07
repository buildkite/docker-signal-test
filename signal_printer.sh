#!/usr/bin/env bash

trap "echo 'Received SIGHUP'; exit" SIGHUP
trap "echo 'Received SIGINT'; exit" SIGINT
trap "echo 'Received SIGTERM'; exit" SIGTERM
trap "echo 'Exiting...'" EXIT

while true; do
  echo "Waiting for a signal..."
  sleep 1
done
