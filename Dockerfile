FROM docker.io/debian:sid

# Environment
ENV QEMU_CPU=2
ENV QEMU_RAM=1024M
ENV QEMU_DISK_SIZE=16G
ENV QEMU_DISK_FORMAT=qcow2
ENV QEMU_KEYBOARD=en-us
ENV QEMU_NET_DEVICE=rtl8139
ENV QEMU_NET_OPTIONS=hostfwd=tcp::13389-:3389,hostfwd=tcp::15900-:5900
ENV QEMU_BOOT_ORDER=cd
ENV QEMU_BOOT_MENU=off
ENV QEMU_KVM=false

# Install system packages
RUN export DEBIAN_FRONTEND=noninteractive \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		curl \
		net-tools \
		procps \
		python3 \
		python3-numpy \
		qemu-kvm \
		qemu-system-x86 \
		qemu-utils \
		runit \
		unzip \
	&& rm -rf /var/lib/apt/lists/*

# Install noVNC
ARG NOVNC_VERSION=v1.1.0
ARG NOVNC_TARBALL_URL=https://github.com/novnc/noVNC/archive/${NOVNC_VERSION}.tar.gz
RUN mkdir /opt/novnc/
RUN curl -sSfL "${NOVNC_TARBALL_URL:?}" | tar -xz --strip-components=1 -C /opt/novnc/

# Install Websockify
ARG WEBSOCKIFY_VERSION=v0.9.0
ARG WEBSOCKIFY_TARBALL_URL=https://github.com/novnc/websockify/archive/${WEBSOCKIFY_VERSION}.tar.gz
RUN mkdir -p /opt/novnc/utils/websockify/
RUN curl -sSfL "${WEBSOCKIFY_TARBALL_URL:?}" | tar -xz --strip-components=1 -C /opt/novnc/utils/websockify/

# Create data directories
RUN mkdir -p /var/lib/qemu/images/ /var/lib/qemu/iso/

# Download ReactOS ISO
ARG REACTOS_ISO_URL=https://downloads.sourceforge.net/project/reactos/ReactOS/0.4.12/ReactOS-0.4.12-iso.zip
ARG REACTOS_ISO_CHECKSUM=16351c1352a05576e920fe3453a4a9e79bfd551b1dba696fbd16c61b60ce4c86
RUN mkdir /tmp/reactos/ \
	&& curl -Lo /tmp/reactos/reactos.zip "${REACTOS_ISO_URL:?}" \
	&& echo "${REACTOS_ISO_CHECKSUM:?}  /tmp/reactos/reactos.zip" | sha256sum -c \
	&& unzip /tmp/reactos/reactos.zip -d /tmp/reactos/ \
	&& mv /tmp/reactos/*.iso /var/lib/qemu/iso/reactos.iso \
	&& rm -rf /tmp/reactos/

# Copy services
COPY --chown=root:root scripts/service/ /etc/service/

# Copy scripts
COPY --chown=root:root scripts/bin/ /usr/local/bin/

# Expose ports
## VNC
EXPOSE 5900/tcp
## noVNC
EXPOSE 6080/tcp

CMD ["/usr/local/bin/container-foreground-cmd"]
