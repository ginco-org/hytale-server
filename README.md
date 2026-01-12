# Hytale Server Docker Image

[![Docker Pulls](https://img.shields.io/docker/pulls/gincoorg/hytale-server.svg)](https://hub.docker.com/r/gincoorg/hytale-server)
[![Docker Stars](https://img.shields.io/docker/stars/gincoorg/hytale-server.svg)](https://hub.docker.com/r/gincoorg/hytale-server)
[![GitHub Issues](https://img.shields.io/github/issues/ginco-org/hytale-server.svg)](https://github.com/ginco-org/hytale-server/issues)

A Docker image for running Hytale dedicated servers, inspired by [itzg/minecraft-server](https://github.com/itzg/docker-minecraft-server).

## Quick Start

### Using Docker Compose (Recommended)

1. Create a `docker-compose.yml` file:

```yaml
version: '3.8'

services:
  hytale:
    image: gincoorg/hytale-server:latest
    container_name: hytale-server
    restart: unless-stopped
    ports:
      - "5520:5520/udp"
    environment:
      EULA: "true"  # Accept Hytale EULA
      MEMORY: "4G"
    volumes:
      - ./data:/data
```

2. Start the server:

```bash
docker-compose up -d
```

3. Authenticate the server (if not using tokens):

```bash
docker-compose logs -f
```

Follow the authentication URL displayed in the logs.

### Using Docker CLI

```bash
docker run -d \
  --name hytale-server \
  -p 5520:5520/udp \
  -e EULA=true \
  -e MEMORY=4G \
  -v $(pwd)/data:/data \
  gincoorg/hytale-server:latest
```

## Important Notes

### QUIC Protocol (UDP)

Hytale uses the **QUIC protocol over UDP**, not TCP. Make sure to:

- Expose UDP port 5520 (or your custom port)
- Configure your firewall to allow UDP traffic
- If behind a router, forward **UDP** port 5520 to your server

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| **Memory** | 4GB | 6GB+ |
| **CPU** | 2 cores | 4+ cores |
| **Storage** | NVMe SSD strongly recommended |
| **Java** | 25 (included in image) |

## Environment Variables

### Required

| Variable | Default | Description |
|----------|---------|-------------|
| `EULA` | `false` | Must be set to `true` to accept the [Hytale EULA](https://www.hytale.com/eula) |

### Memory

| Variable | Default | Description |
|----------|---------|-------------|
| `MEMORY` | `4G` | Memory allocation (e.g., `4G`, `8G`, `12G`) |
| `JVM_OPTS` | G1GC settings | Additional JVM arguments |

### Version

| Variable | Default | Description |
|----------|---------|-------------|
| `HYTALE_VERSION` | `latest` | Server version: `latest` or `pre-release` |

### Network

| Variable | Default | Description |
|----------|---------|-------------|
| `BIND_ADDRESS` | `0.0.0.0:5520` | IP and port to bind |

### Authentication

| Variable | Default | Description |
|----------|---------|-------------|
| `AUTH_MODE` | `authenticated` | `authenticated` or `offline` |
| `HYTALE_SERVER_SESSION_TOKEN` | _(empty)_ | Session token for automated auth |
| `HYTALE_SERVER_IDENTITY_TOKEN` | _(empty)_ | Identity token for automated auth |
| `OWNER_UUID` | _(empty)_ | Owner UUID for profile selection |

### Server Options

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_AOT_CACHE` | `true` | Enable AOT cache for faster startup |
| `ENABLE_SENTRY` | `false` | Enable Sentry crash reporting |
| `ALLOW_OP` | `true` | Allow operator permissions |

### Backups

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_BACKUP` | `false` | Enable automatic backups |
| `BACKUP_FREQUENCY` | `30` | Backup interval in minutes |
| `BACKUP_DIR` | `/data/backups` | Backup directory |

### Server Type

| Variable | Default | Description |
|----------|---------|-------------|
| `TYPE` | `vanilla` | Server type: `vanilla` or custom |

## Authentication

### Method 1: Interactive Device Flow (Default)

1. Start the server without tokens
2. Check the logs for the authentication URL
3. Visit the URL and enter the provided code
4. Server will authenticate automatically

```bash
docker-compose logs -f
```

Example output:
```
===================================================================
DEVICE AUTHORIZATION
===================================================================
Visit: https://accounts.hytale.com/device
Enter code: ABCD-1234
===================================================================
```

### Method 2: Token Passthrough (Automated)

For automated deployments, provide authentication tokens:

```yaml
environment:
  HYTALE_SERVER_SESSION_TOKEN: "your-session-token"
  HYTALE_SERVER_IDENTITY_TOKEN: "your-identity-token"
  OWNER_UUID: "your-profile-uuid"
```

See the [Server Provider Authentication Guide](https://support.hytale.com/hc/en-us/articles/45328341414043) for details on obtaining tokens.

### Method 3: Offline Mode

For testing or local servers:

```yaml
environment:
  AUTH_MODE: "offline"
```

**Note:** Offline mode disables player validation and service API access.

## Volumes

| Path | Description |
|------|-------------|
| `/data` | Main data directory (world, configs, logs) |
| `/data/universe` | World save data |
| `/data/mods` | Installed mods |
| `/data/logs` | Server logs |
| `/data/backups` | Automatic backups (if enabled) |
| `/data/.cache` | AOT cache and optimized files |

## Installing Mods

### Option 1: Volume Mount

```yaml
volumes:
  - ./data:/data
  - ./mods:/mods:ro
```

Place your mod `.jar` or `.zip` files in the `./mods` directory.

### Option 2: Direct Copy

Copy mods directly to `./data/mods/` directory.

## Examples

### Basic Server

```yaml
services:
  hytale:
    image: gincoorg/hytale-server:latest
    ports:
      - "5520:5520/udp"
    environment:
      EULA: "true"
      MEMORY: "4G"
    volumes:
      - ./data:/data
```

### Server with Backups

```yaml
services:
  hytale:
    image: gincoorg/hytale-server:latest
    ports:
      - "5520:5520/udp"
    environment:
      EULA: "true"
      MEMORY: "6G"
      ENABLE_BACKUP: "true"
      BACKUP_FREQUENCY: "60"
    volumes:
      - ./data:/data
```

### Server with Mods

```yaml
services:
  hytale:
    image: gincoorg/hytale-server:latest
    ports:
      - "5520:5520/udp"
    environment:
      EULA: "true"
      MEMORY: "8G"
      TYPE: "custom"
    volumes:
      - ./data:/data
      - ./mods:/mods:ro
```

### Pre-release Server

```yaml
services:
  hytale:
    image: gincoorg/hytale-server:latest
    ports:
      - "5520:5520/udp"
    environment:
      EULA: "true"
      MEMORY: "4G"
      HYTALE_VERSION: "pre-release"
    volumes:
      - ./data:/data
```

### Automated Server (GSP)

```yaml
services:
  hytale:
    image: gincoorg/hytale-server:latest
    ports:
      - "5520:5520/udp"
    environment:
      EULA: "true"
      MEMORY: "6G"
      HYTALE_SERVER_SESSION_TOKEN: "${SESSION_TOKEN}"
      HYTALE_SERVER_IDENTITY_TOKEN: "${IDENTITY_TOKEN}"
      OWNER_UUID: "${OWNER_UUID}"
    volumes:
      - ./data:/data
```

## Building from Source

```bash
git clone https://github.com/ginco-org/hytale-server.git
cd hytale-server
docker build -t gincoorg/hytale-server:latest .
```

## Resources

- [Hytale Official Site](https://www.hytale.com/)
- [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827)
- [Server Provider Authentication Guide](https://support.hytale.com/hc/en-us/articles/45328341414043)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Disclaimer

This is an unofficial Docker image. Hytale and related trademarks are property of Hypixel Studios.
