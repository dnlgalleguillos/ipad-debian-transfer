# Pasar fotos de Debian (GNOME) a un iPad 4.ª generación (iOS 10.3.3)

Guía y script para enviar fotos desde un PC con **Debian 13 + GNOME** a un **iPad clásico con iOS 10.3.3**, usando solo Python y Safari. No requiere instalar nada en el iPad ni en Debian.

> **Problema:** en GNOME Files el iPad aparece como cámara y no deja pegar fotos desde Debian. Esta guía explica por qué y cómo resolverlo.

---

## Tabla de contenidos

1. [Dispositivo probado](#dispositivo-probado)
2. [Entorno del PC](#entorno-del-pc)
3. [Por qué no se puede pegar una foto directamente](#por-qué-no-se-puede-pegar-una-foto-directamente)
4. [Solución: servidor HTTP local + Safari](#solución-servidor-http-local--safari)
5. [Uso del script](#uso-del-script)
6. [Sentido contrario: iPad a Debian](#sentido-contrario-ipad-a-debian)
7. [Solución de problemas](#solución-de-problemas)
8. [Seguridad](#seguridad)
9. [Alternativas](#alternativas)

---

## Dispositivo probado

| Campo | Valor |
|---|---|
| Dispositivo | iPad (4.ª generación), pantalla Retina de 9,7" |
| Número de modelo | **MD510CI/A** (`CI` = versión para Chile) |
| Conectividad | Wi-Fi (sin celular), conector Lightning |
| Año de lanzamiento | 2012 |
| Chip | Apple A6X |
| Capacidad nominal | 16 GB (el sistema reporta 13,05 GB utilizables) |
| Versión de iOS | **10.3.3 (14G60)**, la última que admite este modelo |
| Nombre en Ajustes | `iPad` |

Datos tomados de **Ajustes → General → Información** del propio dispositivo. El número de serie y las direcciones Wi-Fi/Bluetooth se omiten a propósito en este repositorio.

> **Nota:** iOS 10.3.3 es el tope para este modelo. Por eso muchas apps actuales (por ejemplo, la app de Nextcloud para iOS) ya no se pueden instalar.

## Entorno del PC

| Campo | Valor |
|---|---|
| Sistema | Debian GNOME (kernel 6.12, Debian 13 "trixie") |
| Administrador de archivos | GNOME Files (Nautilus) |
| Montaje del iPad | GVfs (`gphoto2` y `afc`) |
| Herramientas usadas | `python3`, `gio`, `cp`, `hostname` |

---

## Por qué no se puede pegar una foto directamente

Al conectar el iPad por USB, GNOME lo monta de dos formas distintas dentro de `/run/user/$UID/gvfs/`:

| Montaje | Qué es | Qué permite |
|---|---|---|
| `gphoto2:host=Apple_Inc._iPad_...` | El iPad visto como **cámara digital** (protocolo PTP). Muestra `DCIM/101APPLE`. | Solo **leer** y copiar fotos hacia el PC. iOS no permite escribir en el carrete por este protocolo. |
| `afc:host=...` ("Documents on iPad") | **Apple File Conduit**, el protocolo de "Compartir archivos" de iTunes. | Solo las carpetas de las apps que habilitan compartir archivos. Nunca el carrete de Fotos. |

Resultado: Debian puede **sacar** fotos del iPad, pero **no meterlas** en la app Fotos por USB con las herramientas de GNOME.

Se puede comprobar desde la terminal:

```bash
ls /run/user/$UID/gvfs/
```

## Solución: servidor HTTP local + Safari

La idea es publicar una carpeta del PC en la red local con el servidor web incluido en Python, y abrirla desde Safari en el iPad. Safari de iOS 10 permite **mantener presionada una imagen → Guardar imagen**, que la guarda en la app Fotos.

### Paso a paso

1. **Conecta ambos equipos a la misma red** (mismo router). Redes de invitados con aislamiento de clientes pueden bloquear la conexión.

2. **Crea la carpeta de envío** y copia dentro las fotos:

   ```bash
   mkdir -p ~/Pictures/Enviar
   cp /ruta/a/tus/fotos/*.jpg ~/Pictures/Enviar/
   ```

3. **Averigua la IP del PC:**

   ```bash
   hostname -I
   ```

   Si hay varias (cable y Wi-Fi), usa la de la red a la que está conectado el iPad.

4. **Inicia el servidor** (publica solo esa carpeta, en el puerto 8000):

   ```bash
   python3 -m http.server 8000 --directory ~/Pictures/Enviar
   ```

5. **En el iPad**, abre Safari y entra a `http://IP_DEL_PC:8000` (por ejemplo `http://192.168.1.16:8000`).

6. **Toca el archivo** para abrir la foto, **mantén el dedo sobre ella** y elige **Guardar imagen**.

7. **Verifica** en la app Fotos que aparezca.

8. **Cierra el servidor** con `Ctrl+C` en la terminal.

## Uso del script

El script [`enviar.sh`](enviar.sh) hace los pasos 3 y 4 por ti: muestra las direcciones que debes abrir en el iPad y levanta el servidor.

```bash
chmod +x enviar.sh
./enviar.sh                       # sirve ~/Pictures/Enviar en el puerto 8000
./enviar.sh ~/Pictures/Vacaciones # sirve otra carpeta
./enviar.sh ~/Pictures/Enviar 9000 # otra carpeta y otro puerto
```

## Sentido contrario: iPad a Debian

Esta dirección **sí funciona** de forma nativa:

- En GNOME Files abre **iPad → DCIM → 101APPLE**. En lugar de copiar y pegar, **arrastra** los archivos a una carpeta (suele ser más fiable con gphoto2).
- O desde la terminal:

  ```bash
  cp "/run/user/$UID/gvfs/gphoto2:host=Apple_Inc._iPad_<ID>/DCIM/101APPLE/IMG_1526.PNG" ~/Pictures/
  ```

  Sustituye `<ID>` por el que muestre `ls /run/user/$UID/gvfs/`.
- También puedes importar con **Shotwell**, que GNOME ofrece al detectar el iPad.

## Solución de problemas

| Síntoma | Causa probable | Qué hacer |
|---|---|---|
| Safari no carga la página | Dispositivos en redes distintas o aislados | Conecta ambos al mismo Wi-Fi o router; evita la red de invitados. |
| Safari no carga solo con una IP | Se usó la IP de otra interfaz | Prueba la otra IP que muestra `hostname -I`. |
| "No se pudo conectar" con IP correcta | Firewall del PC | Revisa `sudo ufw status` y permite el puerto 8000 (`sudo ufw allow 8000/tcp`), ciérralo después. |
| La imagen se abre pero no aparece "Guardar imagen" | Tocaste en vez de mantener presionado | Mantén el dedo sobre la imagen ya abierta. |
| El iPad no aparece en GNOME Files | iPad bloqueado o sin confiar | Desbloquéalo y toca **Confiar** en el aviso. |
| `Address already in use` | El puerto 8000 está ocupado | Usa otro puerto, por ejemplo `./enviar.sh ~/Pictures/Enviar 8080`. |

## Seguridad

- Mientras el servidor corre, **cualquier equipo de tu red local puede ver esa carpeta**. Usa una carpeta que contenga solo lo que quieres enviar y **ciérralo con `Ctrl+C`** al terminar.
- El servidor usa HTTP sin cifrado y sin contraseña. No lo expongas a Internet ni abras el puerto en el router.
- No publiques el número de serie, ni las direcciones MAC (Wi-Fi/Bluetooth) de tu dispositivo.

## Alternativas

- **Correo electrónico:** envíate las fotos y guárdalas desde Mail en el iPad.
- **VLC para iOS:** permite arrastrar archivos a su carpeta en "Documents on iPad", útil para video, pero no deja las fotos en el carrete.
- **AirDrop:** no es práctico entre Linux e iOS 10.

## Licencia

[MIT](LICENSE)
