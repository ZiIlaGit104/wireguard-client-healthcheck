# wireguard-client-healthcheck
Use with the wireguard docker container in client mode to perform healthchecks and IP leak testing.

## 🚀 What It Does
### This is a healthcheck script ran via docker healthchecks to test for VPN client connectivity, and IP leak detection/alerting.
### Includes Logging and alerting via discord Webhook

## 📦 Requirements
### -You will need A DDNS hostname that resolves to your real/ISP IP address that you are looking to hide.  This is used to compare the resolved IP trough the VPN and compare it to a lookup of the IP returned for this hostname, and if they are the same a leak is detected.
### -You will need something like [Autoheal](https://github.com/willfarrell/docker-autoheal) to attempt to restart the container once it is marked 'Unhealthy'
