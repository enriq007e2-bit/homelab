#!/usr/bin/env bash
#
# backup-homelab.sh — Backup completo del homelab aranet
# Respalda: compose files, .env (secretos), configs críticas y VOLÚMENES de datos
# Uso: ./backup-homelab.sh
#
# Genera: /opt/homelab-backups/homelab-YYYYMMDD-HHMM.tar.gz
# También vuelca las Bases de Datos (Nextcloud MariaDB, Immich Postgres, WordPress MariaDB)
#
set -euo pipefail

BACKUP_DIR="/opt/homelab-backups"
TIMESTAMP="$(date +%Y%m%d-%H%M)"
ARCHIVE="${BACKUP_DIR}/homelab-${TIMESTAMP}.tar.gz"
REMOTE="root@192.168.10.114"   # aranet

echo "=== Backup homelab aranet ==="
mkdir -p "$BACKUP_DIR"

# 1. Compose files + .env (secretos incluidos en server, NO en repo)
echo "[1/5] Compose files + .env ..."
ssh "$REMOTE" bash -c "'
  cd /tmp && rm -rf hb && mkdir -p hb/opt hb/portainer
  # /opt compose
  for d in /opt/nc /opt/immich /opt/pihole; do
    [ -d "\$d" ] && cp -r "\$d" hb/opt/ 2>/dev/null
  done
  # Portainer stacks
  cp -r /docker/volumes/portainer_data/_data/compose hb/portainer/ 2>/dev/null
  # Syncthing orphan si existe
  [ -f /data/syncthing/config/config.xml ] && mkdir -p hb/syncthing && cp -r /data/syncthing hb/ 2>/dev/null
'"
ssh "$REMOTE" "cd /tmp/hb && tar czf /tmp/hb-compose.tar.gz . && echo OK"

# 2. Configs críticas (Pi-hole gravity, custom.list, Nextcloud config.php)
echo "[2/5] Configs críticas (Pi-hole, Nextcloud) ..."
ssh "$REMOTE" bash -c "'
  mkdir -p /tmp/hb-config/pihole /tmp/hb-config/nextcloud
  cp -r /opt/pihole/etc-pihole /tmp/hb-config/pihole/ 2>/dev/null
  cp -r /opt/pihole/etc-dnsmasq.d /tmp/hb-config/pihole/ 2>/dev/null
  cp /opt/nc/html/config/config.php /tmp/hb-config/nextcloud/ 2>/dev/null
  cp -r /opt/beszel/data /tmp/hb-config/beszel/ 2>/dev/null
  cd /tmp/hb-config && tar czf /tmp/hb-config.tar.gz . && echo OK
'"

# 3. Dump de Bases de Datos (para restore punto-en-tiempo)
echo "[3/5] Dumps de BD (Nextcloud, Immich, WordPress) ..."
ssh "$REMOTE" bash -c "'
  mkdir -p /tmp/hb-db
  docker exec nextcloud_db mysqldump -u root -p\"\$(printenv MYSQL_ROOT_PASSWORD)\" nextcloud > /tmp/hb-db/nextcloud.sql 2>/dev/null || \
  docker exec nextcloud_db mysqldump -u ncuser -p2f7e3f489503f1d5145a74ed76d6f09c nextcloud > /tmp/hb-db/nextcloud.sql 2>/dev/null
  docker exec immich_postgres pg_dump -U postgres immich > /tmp/hb-db/immich.sql 2>/dev/null
  docker exec wordpress_db mysqldump -u root -p13a8c947d67f94191e65bdc82baebcb9 wordpress > /tmp/hb-db/wordpress.sql 2>/dev/null || true
  cd /tmp/hb-db && tar czf /tmp/hb-db.tar.gz . && echo OK
'"

# 4. Empaquetar TODO en el server
echo "[4/5] Empaquetando archivo final ..."
ssh "$REMOTE" "cd /tmp && tar czf ${ARCHIVE} hb-compose.tar.gz hb-config.tar.gz hb-db.tar.gz 2>/dev/null && echo EMPACADO"

# 5. Copiar a esta máquina (o dejar en server)
echo "[5/5] Backup listo en: ${ARCHIVE}"
echo "    Tamaño: $(ssh "$REMOTE" "du -h $ARCHIVE" | cut -f1)"

# Opcional: copiar a esta laptop (descomenta):
# scp "$REMOTE:${ARCHIVE}" ~/homelab-backups/ 2>/dev/null && echo "Copiado a ~/homelab-backups/"

# Limpiar temporales en server
ssh "$REMOTE" "rm -rf /tmp/hb /tmp/hb-config /tmp/hb-db /tmp/hb-*.tar.gz" 2>/dev/null || true

echo "=== Backup completado: ${ARCHIVE} ==="
