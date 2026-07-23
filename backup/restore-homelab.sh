#!/usr/bin/env bash
#
# restore-homelab.sh — Restaura UN servicio (o todos) desde backup
#
# Uso:
#   ./restore-homelab.sh nextcloud     # solo Nextcloud
#   ./restore-homelab.sh immich        # solo Immich
#   ./restore-homelab.sh all           # todos los servicios
#   ./restore-homelab.sh list          # lista backups disponibles
#
# El backup debe estar en /opt/homelab-backups/ en el server aranet.
#
set -euo pipefail

REMOTE="root@192.168.10.114"
BACKUP_DIR="/opt/homelab-backups"
TARGET="${1:-list}"

if [ "$TARGET" = "list" ]; then
  echo "=== Backups disponibles en ${REMOTE}:${BACKUP_DIR} ==="
  ssh "$REMOTE" "ls -lh ${BACKUP_DIR}/ 2>/dev/null || echo 'No hay backups'"
  exit 0
fi

# Selecciona el backup más reciente
LATEST="$(ssh "$REMOTE" "ls -t ${BACKUP_DIR}/homelab-*.tar.gz 2>/dev/null | head -1")"
if [ -z "$LATEST" ]; then
  echo "ERROR: no se encontró backup en $BACKUP_DIR"
  exit 1
fi
echo "=== Restaurando '$TARGET' desde: $LATEST ==="

# Extrae el backup a /tmp/hb-restore en el server
ssh "$REMOTE" "rm -rf /tmp/hb-restore && mkdir -p /tmp/hb-restore && cd /tmp/hb-restore && tar xzf $LATEST && echo EXTRAIDO"

restore_service() {
  local svc="$1"
  echo "--- Restaurando $svc ---"
  case "$svc" in
    nextcloud)
      ssh "$REMOTE" bash <<'EOF'
        cd /tmp/hb-restore
        cp -r hb/opt/nc/. /opt/nc/ 2>/dev/null
        cp hb-config/nextcloud/config.php /opt/nc/html/config/ 2>/dev/null
        cd /opt/nc && docker compose up -d
EOF
      ;;
    immich)
      ssh "$REMOTE" bash <<'EOF'
        cd /tmp/hb-restore
        cp -r hb/opt/immich/. /opt/immich/ 2>/dev/null
        cd /opt/immich && docker compose up -d
        docker exec -i immich_postgres psql -U postgres immich < /tmp/hb-restore/hb-db/immich.sql 2>/dev/null || echo "BD ya presente o vacia"
EOF
      ;;
    pihole)
      ssh "$REMOTE" bash <<'EOF'
        cd /tmp/hb-restore
        cp -r hb/opt/pihole/. /opt/pihole/ 2>/dev/null
        cp -r hb-config/pihole/etc-pihole /opt/pihole/ 2>/dev/null
        cp -r hb-config/pihole/etc-dnsmasq.d /opt/pihole/ 2>/dev/null
        cd /opt/pihole && docker compose up -d
EOF
      ;;
    wordpress)
      ssh "$REMOTE" bash <<'EOF'
        cd /tmp/hb-restore
        cp -r hb/portainer/compose/4/. /opt/wordpress/ 2>/dev/null || true
        cd /opt/wordpress && docker compose up -d 2>/dev/null || echo "Deploy en Portainer stack #4"
EOF
      ;;
    beszel)
      ssh "$REMOTE" bash <<'EOF'
        cd /tmp/hb-restore
        cp -r hb-config/beszel/data /opt/beszel/ 2>/dev/null
        echo "Re-deploy beszel en Portainer stack #8 con KEY real"
EOF
      ;;
    *)
      echo "Servicio '$svc' no reconocido. Opciones: nextcloud, immich, pihole, wordpress, beszel, all"
      ;;
  esac
}

if [ "$TARGET" = "all" ]; then
  for s in pihole nextcloud immich beszel wordpress; do
    restore_service "$s"
  done
else
  restore_service "$TARGET"
fi

# Limpiar
ssh "$REMOTE" "rm -rf /tmp/hb-restore" 2>/dev/null || true
echo "=== Restauración de '$TARGET' completada ==="
