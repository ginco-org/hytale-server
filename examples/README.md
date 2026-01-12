# Hytale Server Docker Examples

This directory contains various Docker Compose configurations for different use cases.

## Available Examples

### 1. Basic Server (`basic-server.yml`)

A minimal configuration for getting started quickly.

**Features:**
- Default settings
- 4GB memory
- Interactive authentication

**Use case:** Testing, small servers, getting started

```bash
docker-compose -f basic-server.yml up -d
```

---

### 2. Production Server (`production-server.yml`)

A robust configuration for production deployments.

**Features:**
- 8GB memory
- Automatic backups every 30 minutes
- Optimized JVM settings
- Resource limits
- Health checks
- Log rotation

**Use case:** Production servers, public servers

```bash
mkdir -p backups
docker-compose -f production-server.yml up -d
```

---

### 3. Modded Server (`modded-server.yml`)

Configuration for running servers with mods.

**Features:**
- 8GB memory
- Mod directory mounting
- Custom server type

**Use case:** Modded gameplay, custom content

```bash
mkdir -p mods
# Add your mod files to the mods directory
docker-compose -f modded-server.yml up -d
```

---

### 4. GSP Automated (`gsp-automated.yml`)

Configuration for Game Server Providers and automated deployments.

**Features:**
- Token-based authentication
- No user interaction required
- Environment variable configuration

**Use case:** Hosting providers, automated provisioning

**Requirements:**
- GSP entitlement (`sessions.unlimited_servers`)
- Valid session and identity tokens

```bash
# Create .env file with tokens
cat > .env << EOF
SESSION_TOKEN=your_session_token
IDENTITY_TOKEN=your_identity_token
OWNER_UUID=your_owner_uuid
EOF

docker-compose -f gsp-automated.yml up -d
```

---

### 5. Offline Testing (`offline-testing.yml`)

Configuration for local testing without authentication.

**Features:**
- No authentication required
- Quick startup
- Local testing

**Use case:** Development, testing, LAN parties

**Warning:** Do not use for public servers

```bash
docker-compose -f offline-testing.yml up -d
```

---

## Quick Comparison

| Feature | Basic | Production | Modded | GSP | Offline |
|---------|-------|------------|--------|-----|---------|
| **Memory** | 4GB | 8GB | 8GB | 6GB | 4GB |
| **Backups** | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Health Checks** | ❌ | ✅ | ❌ | ❌ | ❌ |
| **Mods** | ❌ | ❌ | ✅ | ❌ | ❌ |
| **Auto Auth** | ❌ | ❌ | ❌ | ✅ | ✅ (offline) |
| **Resource Limits** | ❌ | ✅ | ✅ | ❌ | ❌ |
| **Use Case** | Testing | Production | Modded | Hosting | Development |

---

## General Usage Pattern

1. Choose an example that fits your needs
2. Copy the example file to your working directory
3. Customize environment variables if needed
4. Create any required directories (data, mods, backups)
5. Start the server: `docker-compose -f <example>.yml up -d`
6. Check logs: `docker-compose -f <example>.yml logs -f`
7. Stop the server: `docker-compose -f <example>.yml down`

---

## Customizing Examples

All examples can be customized by:

1. **Copying and modifying the file:**
   ```bash
   cp basic-server.yml my-server.yml
   # Edit my-server.yml
   docker-compose -f my-server.yml up -d
   ```

2. **Using environment variables:**
   ```bash
   MEMORY=12G docker-compose -f basic-server.yml up -d
   ```

3. **Creating a .env file:**
   ```bash
   echo "MEMORY=12G" > .env
   docker-compose -f basic-server.yml up -d
   ```

---

## Common Customizations

### Change Memory
```yaml
environment:
  MEMORY: "12G"  # Allocate 12GB
```

### Change Port
```yaml
ports:
  - "25565:5520/udp"  # External port 25565, internal 5520
environment:
  BIND_ADDRESS: "0.0.0.0:5520"
```

### Enable Backups
```yaml
environment:
  ENABLE_BACKUP: "true"
  BACKUP_FREQUENCY: "60"  # Every 60 minutes
volumes:
  - ./backups:/data/backups
```

### Use Pre-release Version
```yaml
environment:
  HYTALE_VERSION: "pre-release"
```

---

## Troubleshooting

### Server won't start
- Check logs: `docker-compose logs -f`
- Verify EULA is set to "true"
- Ensure ports aren't already in use
- Check available memory

### Can't connect
- Verify firewall allows UDP traffic on port 5520
- Check port forwarding configuration (UDP, not TCP)
- Ensure server is authenticated (check logs)

### Authentication fails
- For interactive auth: Follow the URL in the logs
- For token auth: Verify tokens are valid and not expired
- Check session limit (100 servers without GSP entitlement)

---

## Additional Resources

- [Main README](../README.md)
- [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827)
- [Server Provider Authentication Guide](https://support.hytale.com/hc/en-us/articles/45328341414043)
