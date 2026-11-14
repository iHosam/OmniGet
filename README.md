# OmniGet - Containerized Web Edition (Pi 5 / ARM64 & Linux)

A customized, self-hosted Dockerized web deployment of [OmniGet](https://github.com/OpenSelena/omniget) running inside a containerized Linux desktop environment (LinuxServer Webtop + Selkies). This version enables full browser-based access from any device on your local network without requiring a local GUI installation.

---

## 🚀 Key Differences & Enhancements Compared to Stock OmniGet

Stock OmniGet is distributed as a native desktop application (Electron/Tauri GUI app for Windows, macOS, and Linux desktop environments). This repository provides a dedicated containerized edition specifically patched and optimized for headless Linux servers, Raspberry Pi 5 (ARM64), and browser-based access.

Below are the key differences, fixes, and architecture improvements in this release:

### 1. Web-Accessible Containerization (Webtop + Selkies)
* **Stock OmniGet:** Requires a local display server (X11/Wayland) and desktop session to run directly on the host operating system.
* **This Version:** Bundled with a lightweight XFCE desktop environment powered by `linuxserver/webtop` and the modern **Selkies** WebCodecs/WebRTC streaming engine. The application streams directly to any modern web browser on port `3005` (e.g., `http://pi5.local:3005/` or `http://<IP>:3005/`).

### 2. HTTP JPEG Streaming Fallback (Bypassing WebCodecs HTTPS Restriction)
* **Stock Selkies / Webtop Issue:** Modern browsers enforce the W3C Secure Context policy for the `WebCodecs` API (`window.isSecureContext === true`). When accessed over a local network IP via plain HTTP (`http://192.168.1.x:3005/`), stock Selkies halts execution with a fatal error:
  ```text
  FATAL: Not in a secure context. WebCodecs require HTTPS.
  Error: This application requires a secure connection (HTTPS). Please check the URL.
  ```
* **Our Patch:** Modified the pre-flight routine in Selkies (`selkies-core.js`) to automatically detect when a secure context or `VideoDecoder` API is missing and trigger the built-in **JPEG streaming fallback mode** (`qc()`). This enables full browser streaming over local LAN HTTP without requiring reverse proxies, domain names, or self-signed SSL certificates.

### 3. Bubblewrap (`bwrap`) Permission & Sandbox Crash Fix
* **The Root Cause:** In modern Ubuntu desktop bases, GTK icon themes delegate SVG rendering to sandboxed helper utilities (`glycin` & `bubblewrap`). Inside Docker containers, unprivileged non-root users (`abc`) cannot create new user namespaces, causing `bwrap` to fail with:
  ```text
  bwrap: setting up uid map: Permission denied
  ```
  When the window manager (`libwnck`) subsequently attempts to render fallback window icons, it fails with:
  ```text
  Wnck:ERROR:.../libwnck/xutils.c:default_icon_at_size: assertion failed: (base)
  ```
* **The Memory Leak Impact:** In stock container images, this assertion triggered an infinite crash-and-restart loop inside the S6 supervisor. Each failed cycle leaked child processes (`xfsettingsd`, dbus daemons, gvfs helpers), accumulating **over 1,860 orphan processes** and inflating RAM usage up to **1.43–3.0 GB**, eventually exhausting the X11 connection limit (`Maximum number of clients reached`).
* **Our Fix:** 
  - Installed `librsvg2-common` and `libgdk-pixbuf2.0-bin` and regenerated the GdkPixbuf loader cache.
  - Granted setuid permissions to Bubblewrap (`chmod 4755 /usr/bin/bwrap`).
  - Completely resolved the assertion failure, stopped the crash loop, and stabilized RAM usage to a clean baseline (~100–200 MB for idle desktop services).

### 4. Raspberry Pi 5 / ARM64 WebKit Optimization
* Configured container environment variables to optimize WebKit rendering under ARM64 and GPU acceleration:
  - `WEBKIT_DISABLE_COMPOSITING_MODE=1`: Prevents OpenGL compositor crashes on software/headless render nodes.
  - `WEBKIT_FORCE_SANDBOX=0`: Disables conflicting nested WebKit sandboxing inside the container.

### 5. Automated Session Autostart
* Pre-configured XDG autostart hooks (`/etc/xdg/autostart/OmniGet.desktop`) and Desktop shortcuts (`/etc/skel/Desktop/OmniGet.desktop`). OmniGet launches automatically the moment the web stream opens.

### 6. Flexible Shared Storage & Volume Mounting
* Pre-configured Docker Compose mappings linking `./config` for persistent application settings and `./downloads` for saved files.
* Includes optional volume mounts to share download directories directly with external torrent/downloader clients (e.g. qBittorrent).

---

## 📦 Quick Start

### Prerequisites
* Docker and Docker Compose installed.
* ARM64 Linux host (e.g., Raspberry Pi 4/5) or compatible Linux server.

### Installation

1. **Clone this repository:**
   ```bash
   git clone https://github.com/iHosam/OmniGet.git
   cd OmniGet
   ```

2. **Start the container:**
   ```bash
   docker compose up -d --build
   ```

3. **Access the application:**
   Open your browser and navigate to:
   ```text
   http://<YOUR-SERVER-IP>:3005/
   ```
   *(e.g., `http://192.168.1.91:3005/` or `http://pi5.local:3005/`)*

---

## 🛠️ Configuration (`docker-compose.yml`)

```yaml
services:
  omniget:
    build: .
    image: omniget-local:latest
    container_name: omniget
    restart: unless-stopped
    privileged: true
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
      - TITLE=OmniGet
    volumes:
      - ./config:/config
      - ./downloads:/config/Downloads
      # Bind mount external downloads directory (optional)
      - /home/pi5sam/docker/qbittorrent/downloads:/downloads
    ports:
      - "3005:3000"
    shm_size: "1gb"
```

| Parameter | Function |
| :--- | :--- |
| `3005:3000` | Exposes the Selkies web interface on host port `3005`. |
| `shm_size: 1gb` | Prevents browser / WebKit crashes caused by limited shared memory. |
| `./config` | Preserves OmniGet user preferences, history, and theme settings. |
| `./downloads` | Destination folder for files downloaded by OmniGet. |

---

## 📊 Dashboard & Homarr Integration

If you use a self-hosted dashboard like **Homarr**, you can add an OmniGet card with the following settings:
- **Display URL:** `http://<SERVER-IP>:3005/`
- **Docker Container Integration:** Map to container `omniget` to monitor live status, RAM usage, and start/stop controls.

---

## 📜 Credits & License
- Original OmniGet application by [OpenSelena](https://github.com/OpenSelena/omniget).
- Desktop container base by [LinuxServer.io Webtop](https://github.com/linuxserver/docker-webtop).
- In-browser WebRTC/WebCodecs engine by [Selkies](https://github.com/selkies-project/selkies).
