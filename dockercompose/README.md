Before this environment can be run, some manual configuration steps should be done.

# RSA key

Create a RSA key an save as [server/rsa_key](./server/rsa_key) file. This key will be used to cypher all sensible settings, so store it in a safe place.
If you loose this file you must recreate all the secrets. For example:

```
openssl genrsa --out ./config/broker/rsa_key 2048
```

# Create tunnel certs

In `config/tunnel-server/certs` you must put a certificate file and it's key for the
RDP tunnel server.

You can generate a self-signed certificate and, while defining tunneled RDP UDP
transport in OpenUDS instruct it not to verify the SSL certificate.

Here is an example of generating a self signed certificate:

```bash
openssl genrsa -out config/tunnel-server/certs/server.key 2048

openssl req -key config/tunnel-server/certs/server.key -new -out config/tunnel-server/certs/server.csr
# Fill with whatever you prefer but in Common Name just in case set the public
# domain used to access the tunnel (in this deployment this is the same one
# used to access the broker).

openssl x509 -signkey config/tunnel-server/certs/server.key -in config/tunnel-server/certs/server.csr -req -days 36500 -out config/tunnel-server/certs/server.crt
```

**Warning!** This is not a best practice at all. For sensible environments you
should seriously consider using valid and recognized certificates and configuring
your transports so that they validate the SSL certificate.

# Web access

This docker compose environment uses [Caddy](https://caddyserver.com) to manage HTTP/HTTPS access and SSL certificates. In order to setup
a valid certificate chain, you should set `DOMAIN_NAME` variable in `.env` file.

If Caddy detects a fqdn it will try to create a valid SSL certificate, if it detects a local/internal ip it will create
self signeg certicates (<https://caddyserver.com/docs/automatic-https>)

By default in this repo it is set to "uds.localhost". That name has 2
advantages for development purposes:

 1. Modern OSs will point to 127.0.0.1 with anything ending in ".localhost"
 1. `Caddy` will use it's internal CA to generate a certificate

# Prepare and set tunnel token

In order to comunicate with uds broker the guacamole and uds tunnel server must have a valid token.
This token can be any hash under 48 characters.  Generate this chain with any tool you want.
In python you can use:

```
import hashlib
import secrets
hashlib.sha256(secrets.token_bytes(32)).hexdigest()[:48]
```

## Run docker compose file

Go to the cloned directory and run

```
docker compose up -d
```

## Create / update database tables and deploy static webfiles

Open a shell in the broker service (`docker compose exec -it broker bash`) and
run:

```bash
python manage.py migrate
python manage.py collectstatic
```

## Register the tunnel token in the db

Open a shell in the broker service with `python manage.py shell` and run
there:

```python
import datetime
from uds.models.servers import Server
token=YOUR_GENERATED_TOKEN
tunnel=YOUR_DOCKER_COMPOSE_SERVER_IP
Server.objects.create(ip=tunnel, token=token,stamp=datetime.datetime.now())
quit()
```

## Configure token in guacamole and uds tunnel server

Edit guacamoletunnel/guacamole.properties and config/tunnel-server/udstunnel.conf files to replace GENERATED_TOKEN
literal with the created token.

## Restart docker compose environment

```
docker compose restart
```

# Accesing for the first time

Use a browser to connect to server's IP/URL as configured in Caddy.

Default admin is 'root' and password 'udsmam0'.

Create a new authenticator (for example of type Internal Database) and a new
admin user. Create also a group and ensure the newly cretead user is part of it
(it seems that OpenUDS refuses to allow acces to users in no group).

Login with new admin user, and disable default admin in Tools->Configuration->Security "allowRootWebAccess".

Check that default admin is no longer able to login!

# UDS Client

UDS uses dedicated clients to provide RDP connections. The easiest way to get those clients is openning an account in [UDSenterprise.com](https://www.udsenterprise.com/en/accounts/register) and download from there.

Once dowloaded save in `dockecompose/data/broker/clients` folder.
