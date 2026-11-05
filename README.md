**English** | [Español](README.es.md)

# Transfer photos from Debian (GNOME) to a 4th-generation iPad (iOS 10.3.3)

A guide and script for sending photos from a **Debian 13 + GNOME** PC to a **classic iPad running iOS 10.3.3**, using only Python and Safari. Nothing needs to be installed on the iPad or on Debian.

> **The problem:** in GNOME Files the iPad shows up as a camera, and you cannot paste photos into it from Debian. This guide explains why and how to work around it.

---

## Table of contents

1. [Tested device](#tested-device)
2. [PC environment](#pc-environment)
3. [Why you can't paste a photo directly](#why-you-cant-paste-a-photo-directly)
4. [Solution: local HTTP server + Safari](#solution-local-http-server--safari)
5. [Using the script](#using-the-script)
6. [The other direction: iPad to Debian](#the-other-direction-ipad-to-debian)
7. [Troubleshooting](#troubleshooting)
8. [Security](#security)
9. [Alternatives](#alternatives)

---

## Tested device

| Field | Value |
|---|---|
| Device | iPad (4th generation), 9.7" Retina display |
| Model number | **MD510CI/A** (`CI` = Chile version) |
| Connectivity | Wi-Fi only (no cellular), Lightning connector |
| Release year | 2012 |
| Chip | Apple A6X |
| Nominal capacity | 16 GB (the system reports 13.05 GB usable) |
| iOS version | **10.3.3 (14G60)**, the last version this model supports |
| Name in Settings | `iPad` |

This information comes from **Settings → General → About** on the device itself. The serial number and the Wi-Fi/Bluetooth addresses are intentionally left out of this repository.

> **Note:** iOS 10.3.3 is the ceiling for this model, so many current apps (for example, the Nextcloud iOS app) can no longer be installed.

## PC environment

| Field | Value |
|---|---|
| System | Debian GNOME (kernel 6.12, Debian 13 "trixie") |
| File manager | GNOME Files (Nautilus) |
| iPad mount | GVfs (`gphoto2` and `afc`) |
| Tools used | `python3`, `gio`, `cp`, `hostname` |

---

## Why you can't paste a photo directly

When you connect the iPad over USB, GNOME mounts it in two different ways under `/run/user/$UID/gvfs/`:

| Mount | What it is | What it allows |
|---|---|---|
| `gphoto2:host=Apple_Inc._iPad_...` | The iPad seen as a **digital camera** (PTP protocol). Shows `DCIM/101APPLE`. | **Read-only**: you can copy photos to the PC. iOS does not allow writing to the camera roll over this protocol. |
| `afc:host=...` ("Documents on iPad") | **Apple File Conduit**, the protocol behind iTunes "File Sharing". | Only the folders of apps that enable file sharing. Never the Photos library. |

Result: Debian can **pull** photos off the iPad, but it **cannot push** them into the Photos app over USB using GNOME's tools.

You can check this from a terminal:

```bash
ls /run/user/$UID/gvfs/
```

## Solution: local HTTP server + Safari

The idea is to publish a folder from the PC on the local network using the web server built into Python, then open it from Safari on the iPad. Safari on iOS 10 lets you **long-press an image → Save Image**, which stores it in the Photos app.

### Step by step

1. **Connect both devices to the same network** (same router). Guest networks with client isolation can block the connection.

2. **Create the sending folder** and copy your photos into it:

   ```bash
   mkdir -p ~/Pictures/Enviar
   cp /path/to/your/photos/*.jpg ~/Pictures/Enviar/
   ```

3. **Find the PC's IP address:**

   ```bash
   hostname -I
   ```

   If there are several (wired and Wi-Fi), use the one on the network the iPad is connected to.

4. **Start the server** (it publishes only that folder, on port 8000):

   ```bash
   python3 -m http.server 8000 --directory ~/Pictures/Enviar
   ```

5. **On the iPad**, open Safari and go to `http://PC_IP:8000` (for example `http://192.168.1.16:8000`).

6. **Tap the file** to open the photo, **long-press it**, and choose **Save Image**.

7. **Check** that it appears in the Photos app.

8. **Stop the server** with `Ctrl+C` in the terminal.

## Using the script

The [`enviar.sh`](enviar.sh) script does steps 3 and 4 for you: it prints the addresses to open on the iPad and starts the server.

```bash
chmod +x enviar.sh
./enviar.sh                        # serves ~/Pictures/Enviar on port 8000
./enviar.sh ~/Pictures/Vacations   # serves a different folder
./enviar.sh ~/Pictures/Enviar 9000 # different folder and port
```

## The other direction: iPad to Debian

This direction **does** work natively:

- In GNOME Files open **iPad → DCIM → 101APPLE**. Instead of copy and paste, **drag** the files to a folder (this tends to be more reliable with gphoto2).
- Or from the terminal:

  ```bash
  cp "/run/user/$UID/gvfs/gphoto2:host=Apple_Inc._iPad_<ID>/DCIM/101APPLE/IMG_1526.PNG" ~/Pictures/
  ```

  Replace `<ID>` with the one shown by `ls /run/user/$UID/gvfs/`.
- You can also import with **Shotwell**, which GNOME offers when it detects the iPad.

## Troubleshooting

| Symptom | Likely cause | What to do |
|---|---|---|
| Safari won't load the page | Devices on different or isolated networks | Connect both to the same Wi-Fi or router; avoid the guest network. |
| Safari fails with one IP only | You used the IP of a different interface | Try the other IP shown by `hostname -I`. |
| "Could not connect" with the right IP | PC firewall | Check `sudo ufw status` and allow port 8000 (`sudo ufw allow 8000/tcp`); close it afterwards. |
| The image opens but there is no "Save Image" | You tapped instead of long-pressing | Long-press the image once it is open. |
| The iPad doesn't show up in GNOME Files | iPad locked or not trusted | Unlock it and tap **Trust** on the prompt. |
| `Address already in use` | Port 8000 is taken | Use another port, e.g. `./enviar.sh ~/Pictures/Enviar 8080`. |

## Security

- While the server is running, **anyone on your local network can see that folder**. Use a folder that contains only what you want to send, and **stop it with `Ctrl+C`** when you are done.
- The server uses plain HTTP with no password. Do not expose it to the Internet or open the port on your router.
- Do not publish your device's serial number or its MAC addresses (Wi-Fi/Bluetooth).

## Alternatives

- **Email:** send the photos to yourself and save them from Mail on the iPad.
- **VLC for iOS:** lets you drag files into its folder under "Documents on iPad". Useful for video, but it does not put photos in the camera roll.
- **AirDrop:** not practical between Linux and iOS 10.

## License

[MIT](LICENSE)
