<p align="center">
  <img src="assets/lanview.svg" width="128" height="128" alt="LanView Logo">
</p>

<h1 align="center">LanView</h1>
<p align="center">
  <strong>Zero-Daemon, Unattended Linux &amp; Wayland Remote Desktop over SSH</strong><br>
  <em>Direct Kernel DRM/KMS Capture • VAAPI &amp; Multi-Plane GBM Decompression • Kernel <code>/dev/uinput</code> Control</em>
</p>

---

## Why LanView? (English)

Unattended remote desktop access on **Linux Wayland** is notoriously difficult:
- Traditional tools (*RustDesk, AnyDesk, TeamViewer*) often fail at the Wayland login screen (SDDM/GDM) or trigger mandatory XDG Desktop Portal confirmation popups (*"Do you want to share your screen?"*) that nobody can click on an unattended machine.
- Compositor-specific VNC servers (*wayvnc*, *krfb*, *gnome-remote-desktop*) only work *after* a user logs in, depend on a single compositor, and require permanently open ports/daemons.

**LanView takes a completely different approach:**
1. **Zero Daemon / Zero Open Ports on Target Machines:** Nothing runs on the remote Linux machine while idle. When you click **Connect**, LanView streams a lightweight agent over an encrypted **SSH connection** (`stdin`/`stdout`) that terminates immediately when you disconnect.
2. **Works at the Login Screen (SDDM/GDM) & Across Wayland/X11:** Because LanView reads display planes directly from the Linux kernel (`DRM/KMS`) and injects mouse/keyboard events via `/dev/uinput`, it works before login, during login transitions, and inside any Wayland compositor (KDE Plasma, GNOME, Sway, Hyprland) or X11.
3. **Hardware-Accelerated & Intel Gen12+ CCS / 10-Bit Ready:**
   - Uses `ffmpeg -f kmsgrab` with `VAAPI` GPU scaling and encoding where supported.
   - Automatically detects **Intel Gen12+ Multi-Plane Render Compression (`RC_CCS`)** and **10-bit DeepColor (`AB30`/`XB30`)** framebuffers (which corrupt standard `ffmpeg kmsgrab`) and uses a built-in native `libgbm` + `libturbojpeg` decompressor for artifact-free frames.
   - Includes automatic headless/X11 fallback for dual-GPU NVIDIA systems with powered-off physical monitors.
4. **Zero-Lag Credit Flow Control & Login Watchdog:**
   - Credit-based frame pacing (max 2 frames in flight) eliminates TCP/SSH bufferbloat.
   - Built-in DRM/CRTC watchdog detects display modesets during login/unlock and seamlessly restarts capture without reconnecting.

---

## Warum LanView? (Deutsch)

Unbeaufsichtigter Fernzugriff unter **Linux Wayland** scheitert bei klassischen Tools fast immer am Anmeldebildschirm (SDDM/GDM) oder am Wayland-Bestätigungsdialog (*„Möchten Sie den Bildschirm teilen?“*).

**LanView löst das auf Kernel-Ebene über SSH:**
- **Kein Dienst auf dem Ziel-PC:** Kein dauerhafter Daemon, kein offener Port außer Standard-SSH (Port 22).
- **Funktioniert vor, während und nach dem Login:** Direkter Zugriff über Kernel-`DRM/KMS` und `/dev/uinput` – inklusive automatischem Watchdog beim Wechsel vom Login-Screen in die Wayland-Sitzung.
- **Multi-Monitor-Umschaltung in Echtzeit:** Erkennung aller angeschlossenen Monitore (`M1`, `M2`, `M3` ...) mit korrektem Maus-Mapping pro Bildschirm.
- **Einzelne JSON-Konfigurationsdateien pro Maschine:** Übersichtlich verwaltbar unter `~/.config/lanview/stations/*.json`.

---

## Architecture / Architektur

```
+-----------------------------------+            Encrypted SSH Pipe             +-------------------------------------------+
| Local Client (PyQt6 GUI)          |  ======================================>  | Remote Target (Linux Wayland / X11)       |
|                                   |   stdin: JSON input (mouse/key/ack/cfg)   |                                           |
| • Station Selector (~/.config/..) |                                           | • Ephemeral Python/C Agent in RAM         |
| • Multi-Monitor Switcher (M1..Mn) |  <======================================  | • DRM/KMS (VAAPI / Multi-Plane libgbm)    |
| • Native Scancode & Mouse Mapper  |   stdout: LVFR / LVJS binary frames       | • Kernel /dev/uinput Mouse & Keyboard     |
+-----------------------------------+                                           +-------------------------------------------+
```

---

## Requirements / Voraussetzungen

### Local Machine (Client)
- Linux with `python3`, `python3-pyqt6` (`python-pyqt6`), and `ssh` (OpenSSH client)

### Remote Machine (Target)
- Linux (Wayland or X11) with:
  - `sshd` (SSH key authentication recommended)
  - Passwordless `sudo` (`NOPASSWD`) or root SSH key login (required for `/dev/dri/card*` `CAP_SYS_ADMIN` and `/dev/uinput`)
  - Standard packages: `python3`, `ffmpeg`, `libdrm`, `libgbm`, `libjpeg-turbo` ( plus `gcc` for automatic one-time compilation of the multi-plane GBM helper on Intel Gen12+ / 10-bit systems)

---

## Installation

```bash
git clone https://github.com/tommy-max/lanview.git
cd lanview
./install.sh
```

Then launch **LanView Remote Desktop** from your application menu or run:

```bash
~/.local/bin/lanview
```

---

## Station Configuration (`~/.config/lanview/stations/*.json`)

Each remote machine is configured as a separate `.json` file in `~/.config/lanview/stations/`:

```json
{
  "id": "ws1",
  "name": "Workstation 1 – Office PC",
  "description": "Dual 1080p • Intel/AMD Graphics • KDE Plasma Wayland",
  "host": "ws1",
  "ip": "192.168.1.100",
  "user": "linuxuser",
  "default_fps": 25,
  "default_scale": 0.75
}
```

Optional fields:
- `"ssh_key"`: Path to a specific private key (e.g. `"~/.ssh/id_ed25519"`). If omitted or not found on disk, your default SSH key is used automatically.

---

## License

Released under the [MIT License](LICENSE).
