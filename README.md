# Homelab — Servidor aranet (OMV)

Servidor casero en laptop Dell Inspiron de 20+ años con **3.1 GB RAM** corriendo OpenMediaVault (Debian).
Funciona como NAS, nube privada, DNS, monitor y más — todo auto-hospedado y bajo tu control.

**IP:** 192.168.10.114 (.116) | **Hostname:** aranet | **SO:** OMV (Debian 12)
**Fecha base:** 2026-07-23

---

## 📦 Servicios

| Servicio | Puerto | Stack | Estado | Descripción |
|----------|--------|-------|--------|-------------|
| **Nextcloud** | 8085 | `/opt/nc` | ✅ | Nube privada: archivos, calendario, contactos |
| **Collabora** | 9980 | `/opt/nc` | ✅ | Office en navegador (integrado en Nextcloud) |
| **Immich** | 2283 | `/opt/immich` | ✅ | Backup fotos + galería (SIN ML por RAM) |
| **Pi-hole** | 53, 8080 | `/opt/pihole` | ✅ | Bloqueo anuncios/telemetría de toda la LAN |
| **File Browser** | 8082 | Portainer #2 | ✅ | Gestor archivos web |
| **Heimdall** | 8083 | Portainer #3 | ✅ | Dashboard de enlaces |
| **WordPress** | 8084 | Portainer #4 | ⏸️ Parado | Blog (parado para ahorrar RAM) |
| **Beszel** | 8090 | Portainer #8 | ⚠️ | Monitor (agente con KEY placeholder) |
| **Glances** | 61208 | Portainer #7 | ✅ | Monitor completo |
| **Syncthing** | 8384 | huérfano | ⏸️ Exited | Sync P2P (sin compose) |
| **Portainer** | 9000, 9443 | — | ✅ | Gestión visual contenedores |
| **Samba** | 445, 139 | OMV | ✅ | Compartir archivos en LAN |

---

## 🗂️ Estructura del repo

```
homelab/
├── README.md                      # Este índice
├── .gitignore                     # Protege .env reales y datos
├── services/                      # Un compose por servicio
│   ├── nextcloud/                 # Nextcloud + MariaDB + Collabora (IPs fijas)
│   ├── immich/                    # Immich sin ML (RAM-constrained)
│   ├── pihole/                    # Pi-hole DNS + GUI
│   ├── filebrowser/               # File Browser
│   ├── heimdall/                  # Dashboard
│   ├── wordpress/                 # WordPress + MariaDB (parado)
│   ├── beszel/                    # Beszel hub + agent
│   ├── glances/                   # Glances monitor
│   └── syncthing/                 # Syncthing (compose de rescate)
├── docs/                          # Guías
│   ├── tailscale-setup.md         # Acceso remoto VPN
│   ├── balenaetcher-install.md    # Grabar USB/SD
│   └── disaster-recovery.md       # Cómo resucitar TODO
└── backup/                        # Scripts de respaldo
    ├── backup-homelab.sh          # Backup completo (compose + configs + BD)
    └── restore-homelab.sh         # Restore rápido (1 servicio o todo)
```

---

## 🔐 Secrets

**NUNCA se commitean `.env` reales.** El repo tiene `.env.example` con `CHANGE_ME_*`.
Tus passwords reales viven en:
- `/opt/nc/.env`, `/opt/immich/.env`, `/opt/pihole/.env` (en el server)
- Un gestor de contraseñas (Bitwarden/KeePass) para respaldo fuera del server

---

## 💾 Backup y Restore

```bash
# Hacer backup (corre en la laptop, respalda aranet por SSH)
./backup/backup-homelab.sh

# Restaurar un servicio
./backup/restore-homelab.sh nextcloud

# Restaurar todo
./backup/restore-homelab.sh all

# Listar backups
./backup/restore-homelab.sh list
```

Ver guía completa de disaster recovery: **docs/disaster-recovery.md**

---

## 🚀 Despliegue rápido (nuevo server)

```bash
# 1. Clona el repo
git clone https://github.com/enriq007e2-bit/homelab.git
cd homelab

# 2. Por cada servicio: copia .env.example → .env, rellena, docker compose up -d
cp services/nextcloud/.env.example /opt/nc/.env && nano /opt/nc/.env
cp services/nextcloud/docker-compose.yml /opt/nc/ && cd /opt/nc && docker compose up -d

# 3. Restaura datos desde backup
./backup/restore-homelab.sh all
```

---

## 🌐 Acceso

| Servicio | LAN | Tailscale |
|----------|-----|-----------|
| Nextcloud | http://192.168.10.114:8085 | igual (vía subnet router) |
| Immich | http://192.168.10.114:2283 | igual |
| Pi-hole | http://192.168.10.114:8080/admin | — |
| Portainer | https://192.168.10.114:9443 | igual |
| Heimdall | http://192.168.10.114:8083 | igual |

Ver **docs/tailscale-setup.md** para acceso remoto sin abrir puertos.

---

## ⚠️ RAM (3.1 GB total)

~2.2 GB usados, **~980 MB libres**. Regla: si subes miles de fotos a Immich de golpe,
para Collabora (`docker stop collabora`, libera ~615 MB).

---

*Mantén este README actualizado. Última revisión: 2026-07-23*
