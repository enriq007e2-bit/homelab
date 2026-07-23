# Homelab Documentation — Índice Maestro

**Servidor principal:** aranet (OMV) — 192.168.10.114 / .116  
**Subnet router Tailscale:** Inspiron master — 192.168.10.111  
**Laptop personal:** Inspiron-5520 (Ubuntu 26.04) — corre Hermes, sin Docker  
**Fecha base:** 2026-07-22

---

## 📦 Servicios en aranet (OMV)

| Servicio | Puerto(s) | Estado | Descripción |
|----------|-----------|--------|-------------|
| **Nextcloud** | 8085 (HTTP) | ✅ | Nube privada: archivos, Office, Calendario, Contactos |
| **Collabora Online** | 9980 (interno) | ✅ | Motor Office (Word/Excel/PPT en navegador) |
| **Immich** | 2283 | ✅ | Backup fotos + galería (tipo Google Photos) — **SIN ML** por RAM |
| **Pi-hole** | 53 (DNS), 8080 (admin) | ✅ | Bloqueo anuncios/telemetría red completa |
| **Portainer** | 9000 (HTTP), 9443 (HTTPS) | ✅ | Gestión visual contenedores |
| **Heimdall** | 8083 | ✅ | Dashboard enlaces (página de inicio) |
| **WordPress** | 8084 | ⏸️ Parado | Blog/sitio (parado p/ ahorrar RAM) |
| **Beszel** | 8090 | ✅ | Monitor ligero (agente + hub) |
| **Glances** | 61208 | ✅ | Monitor completo (web) |
| **Samba** | 445, 139 | ✅ | Compartir archivos en LAN |

---

## 🔗 Acceso remoto — Tailscale (VPN privada)

**Sin abrir puertos en el router.** Usa WireGuard + DERP relays.

| Dispositivo | Hostname Tailscale | Red anunciada |
|-------------|-------------------|---------------|
| Inspiron master (subnet router) | `master` | `192.168.10.0/24` |
| aranet (OMV) | `aranet-nextcloud` | (cliente, usa red del master) |
| Laptop personal | `laptop-personal` | (cliente) |

> Ver guía completa: [tailscale-setup.md](tailscale-setup.md)

---

## 💾 Estructura de datos (dónde vive qué)

| Dato | Ubicación | Disco |
|------|-----------|-------|
| Nextcloud (archivos, DB, config) | `/opt/nc/` | SSD sistema |
| Immich fotos | `/srv/dev-disk-by-uuid-3cbf.../immich/library` | HDD datos (219 GB) |
| Immich DB (PostgreSQL) | `/opt/immich/postgres` | SSD sistema |
| Pi-hole config | `/opt/pihole/` | SSD sistema |
| Portainer data | `/docker/volumes/portainer_data` | SSD sistema |
| WordPress | `/opt/wordpress/` | SSD sistema |
| Beszel/Glances/Heimdall | `/opt/<servicio>/` | SSD sistema |

> **Regla:** Fotos/pesos grandes → HDD datos (`/srv/...`). Bases de datos activas → SSD (`/opt/...`).

---

## 🐳 Contenedores — Patrones y comandos

### Redes
- `nextcloud-net` (172.24.0.0/16) — Nextcloud + MariaDB + Collabora (IPs fijas)
- `bridge` (default) — Collabora también conectado aquí p/ callback WOPI
- `pihole_default` — Pi-hole solo

### IPs fijas (nextcloud-net)
| Contenedor | IP |
|------------|-----|
| nextcloud_db | 172.24.0.3 |
| nextcloud | 172.24.0.4 |
| collabora | 172.24.0.2 |

### Comandos útiles
```bash
# Ver todo
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

# Logs
docker logs -f <contenedor>

# Reiniciar servicio
docker restart <contenedor>

# Parar/Arrancar stack completo
cd /opt/nc && docker compose stop|start
cd /opt/immich && docker compose stop|start

# Ver consumo RAM/CPU
docker stats --no-stream

# Limpiar imágenes no usadas
docker image prune -a
```

---

## 🔧 Mantenimiento rutinario

| Qué | Cuándo | Cómo |
|-----|--------|------|
| **Actualizar OMV** | Cuando OMV notifique | GUI OMV → Actualizaciones → Aplicar (reinicia Docker) |
| **Actualizar contenedores** | Mensual | Portainer → Stacks → Update → Pull + Deploy |
| **Backup Nextcloud** | Semanal | `cd /opt/nc && docker exec -u www-data nextcloud php occ maintenance:backup` + copiar `/opt/nc` |
| **Backup Immich DB** | Semanal | `docker exec immich_postgres pg_dump -U postgres immich > immich_$(date +%F).sql` |
| **Limpieza Docker** | Mensual | `docker system prune -a --volumes` (cuidado con volumes) |
| **Verificar disco** | Mensual | `df -h /opt /srv` — alerta si > 80% |
| **Verificar RAM** | Semanal | `free -h` — alerta si disponibles < 500 MB |

---

## ⚠️ RAM en aranet — Realidad (3.1 GB total)

| Servicio | RAM típica (idle) |
|----------|-------------------|
| Immich (server+postgres+redis) | ~1.1 GB |
| Collabora | ~160 MB |
| Nextcloud + MariaDB | ~200 MB |
| Pi-hole | ~30 MB |
| Portainer | ~55 MB |
| Beszel + Glances + Heimdall | ~150 MB |
| **Total usado** | **~2.2 GB** |
| **Disponible** | **~980 MB** |

**Regla de oro:** Si subes MILES de fotos a Immich de golpe → para Collabora (`docker stop collabora`, libera ~615 MB). Día a día no hace falta.

---

## 📚 Documentación detallada

| Tema | Archivo |
|------|---------|
| Tailscale (acceso remoto) | [tailscale-setup.md](tailscale-setup.md) |
| balenaEtcher (grabar USB/SD) | [balenaetcher-install.md](balenaetcher-install.md) |
| Nextcloud + Collabora (detalles, hairpin, WOPI) | `~/.hermes/skills/devops/homelab-docker-services/references/nextcloud-collabora.md` |
| Immich (sin ML, RAM) | skill `homelab-docker-services` → sección "Immich" |
| Pi-hole (gravity 3M, custom.list) | skill `homelab-docker-services` → sección "Pi-hole" |
| Portainer (deploy via Upload, no Web Editor) | skill `homelab-docker-services` → sección "Portainer" |
| File Browser (permisos, db) | skill `homelab-docker-services` → sección "File Browser" |
| SSH recovery (si se muere sshd) | skill `homelab-docker-services` → references/ssh-recovery.md |

---

## 🚀 Próximos pasos / Pendientes

- [ ] Completar auth Tailscale en aranet (link pendiente)
- [ ] Completar auth Tailscale en laptop personal (repo noble)
- [ ] Probar acceso Nextcloud/Immich desde celular via Tailscale
- [ ] Configurar backup automático (rsync a disco externo o nube)
- [ ] Evaluar mover Immich a Inspiron master si RAM sigue justa
- [ ] Limpiar stacks fantasmas en Portainer (#4 WordPress viejo, #5 Nextcloud viejo)

---

## 🤝 Cómo trabajamos (recordatorio)

1. **Tú decides, yo ejecuto** — Tú das la visión/prioridad; yo hago el trabajo técnico.
2. **Estabilidad > novedad** — No toques lo que funciona sin razón.
3. **Documentamos todo** — Cada aventura queda en skills y .md para no repetir.
4. **Comandos cortos o archivos** — SSH multi-línea se rompe; mejor `.sh` o `.yml` subidos.
5. **Seguridad ante todo** — Tailscale antes que abrir puertos; rotar passwords tras compartirlos.

---

*Última actualización: 2026-07-22 — Sesión completa: Nextcloud limpio + Office + Immich + balenaEtcher + Tailscale docs*