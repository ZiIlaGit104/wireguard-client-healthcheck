# wireguard-client-healthcheck
Use with the wireguard docker container in client mode to perform healthchecks and IP leak testing.

## 🚀 What It Does
#### -This is a healthcheck script ran via docker healthchecks to test for VPN client connectivity, and IP leak detection/alerting.
#### -Includes Logging and alerting via discord Webhook

## 📦 Requirements
#### -You will need A DDNS hostname that resolves to your real/ISP IP address that you are looking to hide.  This is used to compare the resolved IP trough the VPN and compare it to a lookup of the IP returned for this hostname, and if they are the same a leak is detected.
#### -You will need something like [Autoheal](https://github.com/willfarrell/docker-autoheal) to attempt to restart the container once it is marked 'Unhealthy'

## Configure Docker Healthcheck and call this script as shown [In this docker-compose.yaml example](https://github.com/ZiIlaGit104/wireguard-client-healthcheck/blob/main/examples/docker-compose.yaml)

## Recommended to map this into your container via a docker volume mapping like:
### Docker Compose snippet:
```yaml
...
   volumes:
      - '/host/path/appdata/wg-client/config/wg_confs/wg0.conf:/config/wg_confs/wg0.conf'
      - '/host/path/appdata/wg-client/wireguard-healthcheck.sh:/config/wg_confs/wireguard-healthcheck.sh'
      - '/host/path/appdata/wg-client/wireguard-healthcheck.log:/config/wg_confs/wireguard-healthcheck.log'
...
```
### Docker Run Command snippet:
```sh
docker run -v /host/path/appdata/wg-client/config/wg_confs/wg0.conf:/config/wg_confs/wg0.conf \
           -v /host/path/appdata/wg-client/wireguard-healthcheck.sh:/config/wg_confs/wireguard-healthcheck.sh \
           -v /host/path/appdata/wg-client/wireguard-healthcheck.log:/config/wg_confs/wireguard-healthcheck.log \
           ... \
           [IMAGE_NAME]
```
