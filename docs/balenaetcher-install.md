# balenaEtcher — Instalación en laptop (Ubuntu 26.04)

## Qué es

Herramienta gráfica para grabar imágenes (.iso, .img) a tarjetas SD / USB de forma segura y verificada.

## Instalación realizada (2026-07-22)

```bash
# 1. Descargado el portable oficial (ZIP) a ~/Downloads
# 2. Extraído e instalado en /opt/balenaEtcher/
sudo cp -r ~/Downloads/balenaEtcher-linux-x64-2.1.6/balenaEtcher-linux-x64 /opt/balenaEtcher
sudo chown root:root /opt/balenaEtcher/chrome-sandbox
sudo chmod 4755 /opt/balenaEtcher/chrome-sandbox  # critical para Electron

# 3. Arreglado symlink roto y creado .desktop
sudo ln -sf /opt/balenaEtcher/balena-etcher /opt/balenaEtcher/balenaEtcher
sudo cp /tmp/balenaEtcher.desktop /usr/share/applications/
sudo ln -sf /opt/balenaEtcher/balena-etcher /usr/local/bin/balena-etcher
sudo update-desktop-database
```

## Resultado

- **Menú de aplicaciones:** "balenaEtcher" (con icono oficial)
- **Terminal:** `balena-etcher`
- **Ubicación:** `/opt/balenaEtcher/`
- **Ejecutable principal:** `balena-etcher` (binario Electron)

## Uso

1. Abre balenaEtcher
2. **Flash from file** → selecciona tu `.iso` / `.img`
3. **Select target** → elige tu USB / SD
4. **Flash!** → te pedirá contraseña sudo (necesario para escribir al dispositivo)
5. Espera a que termine y verifique

## Notas

- El `chrome-sandbox` **debe** ser `root:root` modo `4755` o Electron aborta al arrancar.
- La versión portable no se auto-actualiza. Para actualizar: repite el proceso con la nueva versión.
- Funciona en Wayland (Ubuntu 26.04) sin problemas.