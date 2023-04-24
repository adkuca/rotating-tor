#!/bin/bash

if [ $# -ne 2 ]; then
  echo "Usage: $0 CONTROL_PORT PASSWORD"
  exit 1
fi

control_port="$1"
password="$2"

IFS=$'\n' readarray -t response_lines < <(cat <<EOF | nc -w 5 localhost "$control_port" 2>&1 | tr -d '\r'
AUTHENTICATE "$password"
SIGNAL NEWNYM
QUIT
EOF
)

if [ ${#response_lines[@]} -eq 0 ]; then
  echo "Error: Unable to connect to Tor control port"
  exit 2
fi

# The server responds with "250 OK" on success or "515 Bad authentication" if
# the authentication cookie is incorrect.  Tor closes the connection on an
# authentication failure.
if [[ ! "${response_lines[0]}" == "250 OK" ]]; then
  if [[ "${response_lines[0]}" == "515 Authentication failed"* ]]; then
    echo "${response_lines[0]}"
    exit 3
  else
    echo "something went wrong with authentication 🙃"
    echo "${response_lines[0]}"
    exit 3
  fi
fi

# The server responds with "250 OK" if the signal is recognized (or simply
# closes the socket if it was asked to close immediately), or "552
# Unrecognized signal" if the signal is unrecognized
if [[ ! "${response_lines[1]}" == "250 OK" ]]; then
  if [[ "${response_lines[1]}" == "552 Unrecognized signal"* ]]; then
    echo "${response_lines[1]}"
    exit 4
  else
    echo "something went wrong with signal newnym 🙃"
    echo "${response_lines[1]}"
    exit 4
  fi
fi

echo "Success: Tor identity changed"
exit 0