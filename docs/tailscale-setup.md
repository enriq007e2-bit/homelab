# Tailscale — Acceso remoto seguro a tu homelab (sin abrir puertos)

## Topología actual

```
┌─────────────────┐     Tailscale (WireGuard)      ┌─────────────────┐
│   Tu celular    │ ◄────────────────────────────► │  Subnet Router  │
│  (con app TS)   │                                 │  (Inspiron .111)│
└─────────────────┘                                 └────────┬────────┘
                                                                │
                                                                ▼
                                              ┌─────────────────────────────────┐
                                              │   Red 192.168.10.0/24 (aranet)  │
                                              │  192.168.10.114 → Nextcloud:8085 │
                                              │  192.168.10.114 → Immich:2283    │
                                              │  192.168.10.114 → Collabora:9980 │
                                              │  192.168.10.114 → Pi-hole:8080   │
                                              └─────────────────────────────────┘
```

## Estado actual (2026-07-22)

| Máquina | Tailscale | Rol |
|---------|-----------|-----|
| **Inspiron master** (.111/.110) | ✅ Instalado + **Subnet Router** | Anuncia `192.168.10.0/24` |
| **aranet** (.114) | ✅ Instalado (hostname: `aranet-nextcloud`) | Pendiente: auth + aprobar rutas |
| **Laptop personal** (esta) | ⏳ Instalando (repo noble en Ubuntu 26.04) | Pendiente: auth |

## Configuración paso a paso

### 1. Autenticar aranet (ya instalado)
```bash
# En aranet (ya hecho, genera link):
ssh root@192.168.10.114 "tailscale up --hostname=arnet-nextcloud --accept-routes"
# → Abre el link que muestra en el navegador → Autoriza "aranet-nextcloud"
```

### 2. Instalar y autenticar en laptop personal (esta)
```bash
# Ubuntu 26.04 (resolute) usa repo noble (24.04 LTS):
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-list | sudo tee /etc/apt/sources.list.d/tailscale.list
sudo apt update && sudo apt install -y tailscale

# Autenticar:
sudo tailscale up --hostname=laptop-personal
# → Abre el link → Autoriza "laptop-personal"
```

### 3. Verificar que las rutas funcionan
```bash
# En la laptop:
tailscale status
# Debe verse "aranet-nextcloud" y al lado "192.168.10.0/24" (subnet)

# Probar acceso a Nextcloud via Tailscale:
curl http://192.168.10.114:8085/api/server/ping
# Debe responder 200 / JSON

# Probar Immich:
curl http://192.168.10.114:2283/api/server/ping
```

### 4. En el celular
1. Instala app **Tailscale** (Play Store / App Store)
2. Inicia sesión con la **misma cuenta** (Google/Microsoft/GitHub)
3. Activa el switch → Verás "aranet-nextcloud" en la lista
4. Abre navegador → `http://192.168.10.114:8085` → ¡Nextcloud desde cualquier parte!

## Qué servicios quedan accesibles via Tailscale

| Servicio | URL Tailscale | Notas |
|----------|---------------|-------|
| Nextcloud | `http://192.168.10.114:8085` | Files, Office, Calendar, Contacts |
| Immich | `http://192.168.10.114:2283` | Backup fotos + galería |
| Collabora | (interno, vía Nextcloud) | Office online |
| Pi-hole Admin | `http://192.168.10.114:8080/admin` | Solo si necesitas ver stats DNS |
| Portainer | `https://192.168.10.114:9443` | Gestión contenedores (HTTPS) |
| Heimdall | `http://192.168.10.114:8083` | Dashboard de enlaces |

## Notas importantes

- **NO abres puertos en el router** — Tailscale usa WireGuard + DERP relays, todo sale saliente.
- **Subnet Router** = Inspiron master (.111). Él "anuncia" la red .10.0/24 a la tailnet. aranet NO necesita ser subnet router (ya está en esa red).
- **Aprobar rutas**: en la admin console de Tailscale (web) → Machines → aranet-nextcloud → "..." → **Approve routes** para `192.168.10.0/24`.
- **Trusted domains en Nextcloud**: ya incluye `192.168.10.114` y `office.casa`. Como entras por IP Tailscale (la misma .114), funciona sin tocar config.
- **Immich app móvil**: pon `http://192.168.10.114:2283` como servidor. Funciona igual que en casa.

## Troubleshooting

| Síntoma | Qué revisar |
|---------|-------------|
| `curl 192.168.10.114:8085` falla desde laptop | `tailscale status` muestra la subnet? `tailscale ping aranet-nextcloud` responde? |
| Celular no ve aranet en app Tailscale | ¿Misma cuenta? ¿Switch activado? ¿Subnet router online? |
| Nextcloud dice "dominio no de confianza" | Agrega la IP Tailscale a `NEXTCLOUD_TRUSTED_DOMAINS` (pero Tailscale usa la misma IP .114, así que no debería pasar) |
| Collabora no carga desde fuera | El callback WOPI usa IP .114:8085 que SÍ llega via Tailscale. Si falla, revisa que `office.casa` resuelva (solo DNS local Pi-hole). Desde fuera usa IP directa. |

## Comandos útiles

```bash
# Ver estado
tailscale status

# Ver IPs Tailscale de cada máquina
tailscale ip -4

# Ping a otro nodo
tailscale ping aranet-nextcloud

# Ver rutas anunciadas
tailscale netcheck

# Logs
journalctl -u tailscaled -f
```