# Disaster Recovery — Resucitar el homelab aranet desde cero

**Objetivo:** Si el disco muere, OMV se corrompe, o necesitas migrar a otro hardware,
puedes reconstruir el 100% del homelab en < 1 hora usando este repo + el backup.

---

## 📋 Qué necesitas

1. Este repo (`homelab`) clonado o descargado
2. Un backup reciente (`/opt/homelab-backups/homelab-*.tar.gz` en aranet)
3. La lista de **passwords/secrets** (NO están en el repo, están en tu gestor de contraseñas)
4. El hardware (laptop Inspiron / cualquier box con 3+ GB RAM + Debian/OMV)

---

## 🔄 Escenario A: El server arranca pero un contenedor se rompió

```bash
# Restaurar SOLO Nextcloud (ejemplo)
./backup/restore-homelab.sh nextcloud

# Restaurar todos
./backup/restore-homelab.sh all

# Ver backups disponibles
./backup/restore-homelab.sh list
```

El script:
1. Extrae el backup más reciente en el server
2. Copia compose + .env + configs al lugar original
3. Hace `docker compose up -d`
4. (Si aplica) restaura el dump de BD

---

## 🔄 Escenario B: Reinstalar OMV desde cero

### 1. Instala OMV (Debian + openmediavault)
```bash
# En el nuevo disco:
# - Instala Debian 12 (mínimo)
# - Sigue guía OMV: https://github.com/OpenMediaVault-Plugin-Developers/installScript
wget -O - https://github.com/OpenMediaVault-Plugin-Developers/installScript/raw/master/install | sudo bash
```

### 2. Instala Docker + Compose
```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
sudo apt install -y docker-compose-plugin
```

### 3. Libera el puerto 53 (para Pi-hole)
```bash
sudo systemctl disable --now systemd-resolved
sudo rm /etc/resolv.conf && echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
```

### 4. Crea estructura de carpetas
```bash
mkdir -p /opt/{nc,immich,pihole,heimdall,filebrowser,beszel,wordpress,portainer}
mkdir -p /srv/dev-disk-by-uuid-XXXX/immich/library   # disco de datos
```

### 5. Despliega cada servicio desde este repo
```bash
# Nextcloud (con .env rellenado)
cp services/nextcloud/.env.example /opt/nc/.env
# ← EDITA /opt/nc/.env con tus passwords
cp services/nextcloud/docker-compose.yml /opt/nc/
cd /opt/nc && docker compose up -d

# Immich
cp services/immich/.env.example /opt/immich/.env
# ← EDITA /opt/immich/.env (DB_PASSWORD, UPLOAD_LOCATION)
cp services/immich/docker-compose.yml /opt/immich/
cd /opt/immich && docker compose up -d

# Pi-hole
cp services/pihole/.env.example /opt/pihole/.env
# ← EDITA PIHOLE_PASSWORD
cp services/pihole/docker-compose.yml /opt/pihole/
cd /opt/pihole && docker compose up -d

# El resto (Portainer stacks #2-#8): usa Portainer GUI → "Add stack" → pega el YAML
```

### 6. Restaura datos desde backup
```bash
./backup/restore-homelab.sh all
```

---

## 🔄 Escenario C: Migrar a otro hardware (Inspiron master, por ejemplo)

Mismo que B, pero:
- Cambia IPs en `.env` / compose (`192.168.10.114` → la nueva)
- En Nextcloud `config.php` y `NEXTCLOUD_TRUSTED_DOMAINS` ajusta la IP
- En Immich `UPLOAD_LOCATION` apunta al nuevo disco de datos
- Tailscale: el nuevo host se une a la misma tailnet (mismo login)

---

## 🔑 Secrets que DEBES tener guardados (fuera del repo)

| Servicio | Dónde está el secreto real |
|----------|---------------------------|
| Nextcloud admin | `/opt/nc/.env` → `NEXTCLOUD_ADMIN_PASSWORD` (+ `config.php` salts) |
| Nextcloud DB | `/opt/nc/.env` → `DB_PASSWORD`, `DB_ROOT_PASSWORD` |
| Collabora | `/opt/nc/.env` → `COLLABORA_PASSWORD` |
| Immich Postgres | `/opt/immich/.env` → `DB_PASSWORD` |
| Pi-hole GUI | `/opt/pihole/.env` → `PIHOLE_PASSWORD` |
| WordPress DB | stack #4 env → `WP_DB_PASSWORD` |
| Beszel agent | KEY generada en GUI :8090 (pegar en `.env`) |
| Tailscale | Auth key de la admin console (se regenera) |

> ⚠️ Estos valores NO se commitean. El `.gitignore` bloquea `.env` reales.
> Guárdalos en un gestor de contraseñas (Bitwarden, KeePass, etc.).

---

## 💾 Estrategia de backup recomendada

| Frecuencia | Qué | Cómo |
|-----------|-----|------|
| **Diario** (cron 3 AM) | BD dumps (Nextcloud, Immich, WordPress) | `backup/backup-homelab.sh` (solo sección DB) |
| **Semanal** | Compose + .env + configs + BD | `backup/backup-homelab.sh` completo |
| **Mensual** | Copiar backup a disco externo / nube | `scp` o `rclone` a otro lugar |

### Programar backup automático (en aranet)
```bash
# Como root, crontab -e:
0 3 * * * /opt/homelab/backup/backup-homelab.sh >> /var/log/homelab-backup.log 2>&1
```

### Verificar que el backup sirve (prueba cada mes)
```bash
./backup/restore-homelab.sh list   # debe listar archivos
# Restaurar en un server de PRUEBA (no el productivo) para validar
```

---

## 🚨 Troubleshooting común

| Síntoma | Causa | Fix |
|---------|-------|-----|
| Nextcloud "access forbidden" tras restore | `config.php` con salts viejos | Usa el `config.php` del backup, NO el genérico |
| Immich no carga fotos tras restore | `UPLOAD_LOCATION` apunta a disco vacío | Restaura `/srv/.../immich/library` del backup de datos |
| Pi-hole no bloquea anuncios | `gravity.db` no restaurado | El backup incluye `/opt/pihole/etc-pihole/gravity.db` |
| Beszel agent reinicia | `KEY` placeholder | Genera KEY en GUI :8090, pégalo en `.env`, re-deploy |
| Puerto 53 ocupado | systemd-resolved activo | `systemctl disable --now systemd-resolved` |
| Collabora "not found" en Nextcloud | `domain: office\.casa` vs red | Revisa `extra_hosts` + `aliasgroup1` en compose |

---

## ✅ Checklist post-restauración

- [ ] `docker ps` muestra todos los contenedores Up/healthy
- [ ] Nextcloud http://192.168.10.114:8085 responde
- [ ] Immich http://192.168.10.114:2283 responde
- [ ] Pi-hole http://192.168.10.114:8080 admin carga
- [ ] `free -h` muestra > 500 MB libres
- [ ] `docker logs <svc>` no muestra errores críticos
- [ ] Tailscale conectado (si aplica)

---

*Mantén este archivo actualizado cada vez que cambies la topología.*
*Última revisión: 2026-07-23*
