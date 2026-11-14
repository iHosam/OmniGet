FROM lscr.io/linuxserver/webtop:ubuntu-xfce

ENV TITLE="OmniGet" \
    WEBKIT_DISABLE_COMPOSITING_MODE=1 \
    WEBKIT_FORCE_SANDBOX=0

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        libayatana-appindicator3-1 \
        libpipewire-0.3-0 \
        ffmpeg \
        libgdk-pixbuf2.0-bin \
        librsvg2-common && \
    curl -s -L https://github.com/OpenSelena/omniget/releases/download/v0.14.0/OmniGet_0.14.0_arm64.deb -o /tmp/omniget.deb && \
    dpkg -i /tmp/omniget.deb && \
    rm -f /tmp/omniget.deb && \
    chmod 4755 /usr/bin/bwrap 2>/dev/null || true && \
    /usr/lib/aarch64-linux-gnu/gdk-pixbuf-2.0/gdk-pixbuf-query-loaders --update-cache 2>/dev/null || true && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Autostart OmniGet inside desktop session
RUN mkdir -p /etc/xdg/autostart && \
    cp /usr/share/applications/OmniGet.desktop /etc/xdg/autostart/ 2>/dev/null || true && \
    mkdir -p /etc/skel/Desktop && \
    cp /usr/share/applications/OmniGet.desktop /etc/skel/Desktop/ 2>/dev/null || true

# Allow HTTP access by falling back to JPEG mode when WebCodecs/HTTPS is unavailable
RUN python3 -c "import glob; target = 'window.isSecureContext?(window.VideoDecoder===void 0?(console.warn(\`VideoDecoder API unavailable: the stream is pinned to the jpeg encoder.\`),qc()):console.log(\`Pre-flight checks passed: Secure context and VideoDecoder API are available.\`),!0):(console.error(\`FATAL: Not in a secure context. WebCodecs require HTTPS.\`),Y&&(Y.textContent=\`Error: This application requires a secure connection (HTTPS). Please check the URL.\`,Y.classList.remove(\`hidden\`)),ea&&ea.classList.add(\`hidden\`),!1)'; repl = '(window.VideoDecoder===void 0||!window.isSecureContext)?(console.warn(\`JPEG fallback mode\`),qc(),!0):(console.log(\`Pre-flight checks passed\`),!0)'; [open(p, 'w', encoding='utf-8').write(open(p, 'r', encoding='utf-8').read().replace(target, repl)) for p in glob.glob('/usr/share/selkies/**/*.js', recursive=True) + glob.glob('/lsiopy/**/*.js', recursive=True) if target in open(p, 'r', encoding='utf-8').read()]"
