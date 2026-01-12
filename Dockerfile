FROM eclipse-temurin:25-jre-jammy

LABEL maintainer="Ginco Organization"
LABEL org.opencontainers.image.source="https://github.com/ginco-org/hytale-server"
LABEL org.opencontainers.image.description="Dockerized Hytale Server similar to itzg/minecraft-server"

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
    curl \
    wget \
    unzip \
    jq \
    net-tools \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Create user and directories
RUN useradd -m -u 1000 -s /bin/bash hytale && \
    mkdir -p /data /hytale /downloads && \
    chown -R hytale:hytale /data /hytale /downloads

# Set working directory
WORKDIR /data

# Copy scripts
COPY --chown=hytale:hytale scripts/ /scripts/
RUN chmod +x /scripts/*.sh

# Environment variables
ENV HYTALE_VERSION=latest \
    MEMORY=4G \
    JVM_OPTS="-XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200" \
    BIND_ADDRESS=0.0.0.0:5520 \
    ENABLE_AOT_CACHE=true \
    ENABLE_SENTRY=false \
    ALLOW_OP=true \
    ENABLE_BACKUP=false \
    BACKUP_FREQUENCY=30 \
    BACKUP_DIR=/data/backups \
    AUTH_MODE=authenticated \
    EULA=false \
    TYPE=vanilla \
    HYTALE_SERVER_SESSION_TOKEN="" \
    HYTALE_SERVER_IDENTITY_TOKEN="" \
    OWNER_UUID=""

# Expose UDP port for QUIC protocol
EXPOSE 5520/udp

# Volumes for persistent data
VOLUME ["/data"]

# Switch to hytale user
USER hytale

# Entrypoint
ENTRYPOINT ["/scripts/entrypoint.sh"]
