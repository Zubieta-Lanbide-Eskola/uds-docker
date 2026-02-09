# Upgrade

This document does nots explain the general procedure for upgrading between
different UDS versions. It just talks about specifically changing between
different versions while using the docker based deployment contained in this
repository.

**Be aware!** Keep in mind that these are general tips, as a best practice,
ensure that you have a proper backup and rollback strategy before proceding
with the upgrade.

## Upgrading from 3.5 deployment to 4.0 deployment

In the 3.5 deployment branch Mysql was used instead of Mariadb. Besides that
no specific Mysql version pinning was done, so depending on when and how
the deployment was made a different version of Mysql could have been deployed.

Not only that but the structure of the deployment folders and organization of
data volumes has changed.

For all this reasons we suggest that you just make a database dump of the
old UDS database and restore it after a completely new deployment with the
4.0 branch.

Caddy version has also been upgraded but unless you have manually tweaked the
previous config in order to use local certs or something like that most proably
jus allowing a clean deployment to automatically renegotiate and obtain the
*Let'sEncrypt* based certificates will be the easiest upgrade approach.

Finally keep in mind that the database structure has been changed from UDS 3.5
to 4.0, so you will probablye have to execute the migrations as well as, just
in case, the collection of static files.

So, approximaterly you will have to:

* Dump current BBDD with something like:

```bash
docker compose exec -it mysql bash -c "mysqldump --compatible=ansi --single-transaction --default-character-set=utf8mb4 --hex-blob --skip-extended-insert -u udsuser -pudspassword uds" > /root/3_5_backup.sql
```

* Clean completely the current docker compose deployment with something like:

```bash
docker compose down -v --remove-orphans
```

* Move your current deployment files to another folder as a temporary backup

* Copy the new deployment files and customize the files in "config" folder.

  * Edit `.env` and set `DOMAIN_NAME`
  * Edit `config/guacamole/guacamole.properties` and `config/tunnel-server/udstunnel.conf` files to replace GENERATED_TOKEN
  * Copy the old `server/rsa_key` to `config/broker/rsa_key`
  * Generate certificates for the RDP tunnel server (see `README.md`)

     The 3.5 branch simply used fixed ones in the image. Now they are externalized to
     ensure that not all deployments use the same one.

  * Obtain the client installers and place them in `data/broker/clients`.
  
    You already have the clients in your old installation but they are the ones
    for UDS 3.5, not the ones for UDS 4.0.

* Start broker-db container and load the DB dump

```bash
docker compose up -d broker-db
docker compose cp /root/3_5_backup.sql broker-db:/tmp/3_5_backup.sql
docker compose exec broker-db bash -c "mariadb --default-character-set=utf8mb4 -u udsuser -pudspassword uds < /tmp/3_5_backup.sql"
docker compose exec broker-db bash -c "rm /tmp/3_5_backup.sql"
```

* Start the broker and excute the migrations and collection

```bash
docker compose up -d broker
docker compose exec -it broker bash

#Once inside the container
python manage.py migrate
python manage.py collectstatic
exit
```

* Start all the services and check

```bash
docker compose up -d
```

* Once you are convinced that everything is ok delete old backups
