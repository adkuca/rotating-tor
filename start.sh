#!/bin/bash

set -e

add_control_password_to_tor_config_template() {
  local control_password=$1
  sed -i "s/%HASHED_CONTROL_PASSWORD/$(tor --quiet --hash-password $control_password)/g" /etc/tor/torrc.template
}

create_tor_config() {
  local index=$1
  local socks_port=$2
  local control_port=$3
  cp /etc/tor/torrc.template "/etc/tor/torrc$index"
  sed -i "s/%INDEX/$index/g" "/etc/tor/torrc$index"
  sed -i "s/%SOCKS_PORT/$socks_port/g" "/etc/tor/torrc$index"
  sed -i "s/%CONTROL_PORT/$control_port/g" "/etc/tor/torrc$index"
}

create_tor_service() {
  local index=$1
  cp -r /etc/service/.tor.template "/etc/service/tor$index"
  sed -i "s/%i/$index/g" "/etc/service/tor$index/run"
  sed -i "s/%i/$index/g" "/etc/service/tor$index/finish"
}

create_privoxy_config() {
  local index=$1
  local privoxy_port=$2
  local tor_socks_port=$3
  cp /etc/privoxy/config.template "/etc/privoxy/config$index"
  sed -i "s/%INDEX/$index/g" "/etc/privoxy/config$index"
  sed -i "s/%LISTEN_PORT/$privoxy_port/g" "/etc/privoxy/config$index"
  sed -i "s/%TOR_SOCKS_PORT/$tor_socks_port/g" "/etc/privoxy/config$index"
}

create_privoxy_service() {
  local index=$1
  cp -r /etc/service/.privoxy.template "/etc/service/privoxy$index"
  sed -i "s/%i/$index/g" "/etc/service/privoxy$index/run"
  sed -i "s/%i/$index/g" "/etc/service/privoxy$index/finish"
}

create_haproxy_config() {
  local privoxy_ports=("$@")
  local privoxy_backend_servers=""

  for i in "${!privoxy_ports[@]}"; do
    privoxy_backend_servers="$privoxy_backend_servers\n    server privoxy$(($i + 1)) 127.0.0.1:${privoxy_ports[$i]} check"
  done

  # remove the initial newline character from the haproxy_privoxy_backend_servers string
  privoxy_backend_servers="${privoxy_backend_servers#\\n    }"

  cp /etc/haproxy/haproxy.cfg.template /etc/haproxy/haproxy.cfg
  sed -i "s/%PRIVOXY_BACKEND_SERVERS/$privoxy_backend_servers/g" /etc/haproxy/haproxy.cfg
}

if [[ -z "$TOR_INSTANCES" || ! "$TOR_INSTANCES" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: Please set the TOR_INSTANCES environment variable to a valid non-zero integer."
  exit 1
fi

# use first argument, if not provided default to "admin"
tor_control_password=${1:-admin}

BASE_TOR_SOCKS_PORT=9050
BASE_TOR_CONTROL_PORT=9051
BASE_PRIVOXY_PORT=8250

privoxy_ports=()

for i in $(seq 1 $TOR_INSTANCES); do
  # calculating new instance ports using even numbers starting from the base values
  tor_socks_port=$((BASE_TOR_SOCKS_PORT + (i - 1) * 2))
  tor_control_port=$((BASE_TOR_CONTROL_PORT + (i - 1) * 2))
  privoxy_port=$((BASE_PRIVOXY_PORT + (i - 1) * 2))
  privoxy_ports+=($privoxy_port)

  add_control_password_to_tor_config_template $tor_control_password
  create_tor_config $i $tor_socks_port $tor_control_port
  create_tor_service $i
  create_privoxy_config $i $privoxy_port $tor_socks_port
  create_privoxy_service $i
done

create_haproxy_config "${privoxy_ports[@]}"

runsvdir /etc/service
