# rotating-tor

Load balances requests using round-robin in HAproxy across multiple instances of Privoxy, with each instance forwarding requests to its respective Tor instance

## Usage

```bash
# build docker container
docker build -t rotating-tor -f dev.Dockerfile .

# start docker container,
# env TOR_INSTANCES=5 which represents how many tor instances are created
# first passed argument is the control port password for tor instances which defaults to "admin" if not provided
docker run -d -p 8123:8123 -e TOR_INSTANCES=5 rotating-tor -- admin

# try it out
curl -x localhost:8123 https://httpbin.org/ip
```
