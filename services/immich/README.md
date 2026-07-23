# Immich en aranet (3.1 GB RAM) — Guía rápida

## Por qué SIN Machine Learning

aranet tiene **3.1 GB RAM total**. El ML de Immich (reconocimiento facial/objetos) necesita un contenedor aparte que come **1.5–2 GB**. Con todo lo demás corriendo (Nextcloud, Collabora, Pi-hole, etc.), no cabe sin thrashing de swap.

**Decisión:** desplegar solo `immich-server` + `redis` + `database` (PostgreSQL con pgvector).  
**Resultado:** ~1.1 GB RAM total (server ~687 MB + DB ~383 MB + Redis ~8 MB).  
**Funciona:** backup automático de fotos, galería, álbumes, timeline, app móvil.  
**No funciona:** búsqueda por "cara de Enrique" / "perro" / "playa".

---

## Despliegue

```bash
# 1. Prepara directorios
mkdir -p /srv/dev-disk-by-uuid-3cbf356b-5d12-46da-be09-b46af845c46d/immich/library
mkdir -p /opt/immich/postgres

# 2. Copia .env.example a .env y rellena
cp .env.example .env
# Edita DB_PASSWORD con: openssl rand -hex 16

# 3. Descarga imágenes y arranca
docker compose pull
docker compose up -d
```

## Primer acceso

Abre http://192.168.10.114:2283  
→ Crea tu cuenta **admin** (email + contraseña que tú elijas). No hay credenciales por defecto.

## App móvil

1. Instala **Immich** (Play Store / App Store)
2. Servidor: `http://192.168.10.114:2283` (en casa)  
   o vía Tailscale cuando lo actives
3. Login con tu admin → **Activa "Subida automática"** en Ajustes

## Mantenimiento

```bash
# Ver logs
docker compose logs -f immich-server

# Parar todo (libera ~1.1 GB RAM)
docker compose stop

# Arrancar
docker compose start

# Actualizar
docker compose pull && docker compose up -d

# Backup de la DB (hazlo antes de actualizar)
docker exec immich_postgres pg_dump -U postgres immich > immich_backup_$(date +%F).sql
```

## RAM — qué esperar

| Estado | RAM libre |
|--------|-----------|
| Arranque (primer minuto) | ~174 MB (pico temporal) |
| Estable (5 min+) | **~980 MB** ✅ |

Si un día subes **miles de fotos a la vez** (genera muchas miniaturas) y notas lentitud:
```bash
docker stop collabora   # libera ~615 MB temporalmente
```

## Estructura en disco

```
/srv/dev-disk-by-uuid-.../immich/library/   ← Fotos originales + miniaturas (crece mucho)
/opt/immich/postgres/                        ← Base de datos (SSD, ~200-500 MB)
```

## Puertos

- **2283** — Web UI + API (app móvil)

## Notas importantes

- `IMMICH_MACHINE_LEARNING_ENABLED=false` en .env + no hay servicio `immich-machine-learning` en compose = ML completamente off.
- La DB usa imagen custom `ghcr.io/immich-app/postgres:14-vectorchord...` con extensiones vectoriales (pgvector/pgvectors). **No uses postgres:14 oficial** o fallarán migraciones.
- `restart: unless-stopped` en todo = sobrevive a reinicios del server.
- Fotos en disco de datos OMV (219 GB, 54 GB libres). DB en SSD del sistema (rendimiento).