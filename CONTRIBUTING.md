# Contributing to Hytale Server Docker

Thank you for your interest in contributing to this project! This document provides guidelines for contributing.

## How to Contribute

### Reporting Issues

1. Check if the issue already exists in the [issue tracker](https://github.com/ginco-org/hytale-server/issues)
2. If not, create a new issue with:
   - Clear, descriptive title
   - Detailed description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - Environment details (OS, Docker version, etc.)
   - Relevant logs or screenshots

### Submitting Changes

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test your changes thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to your branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Pull Request Guidelines

- Write clear, concise commit messages
- Update documentation if needed
- Add tests if applicable
- Ensure the Docker image builds successfully
- Keep changes focused on a single feature/fix

## Development Setup

### Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- Git

### Building Locally

```bash
git clone https://github.com/ginco-org/hytale-server.git
cd hytale-server
docker build -t gincoorg/hytale-server:dev .
```

### Testing

```bash
# Test basic startup
docker-compose up

# Test with different configurations
MEMORY=8G EULA=true docker-compose up

# Test build for multiple architectures
docker buildx build --platform linux/amd64,linux/arm64 .
```

## Project Structure

```
hytale-server/
├── .github/
│   └── workflows/          # GitHub Actions workflows
├── scripts/                # Entrypoint and helper scripts
│   ├── entrypoint.sh      # Main entrypoint script
│   ├── download-server.sh # Server file download
│   └── install-mods.sh    # Mod installation
├── Dockerfile             # Docker image definition
├── docker-compose.yml     # Example compose file
├── .env.example           # Example environment config
└── README.md              # Main documentation
```

## Coding Standards

### Shell Scripts

- Use `#!/bin/bash` shebang
- Use `set -e` for error handling
- Add comments for complex logic
- Follow Google Shell Style Guide

### Docker

- Keep images as small as possible
- Use multi-stage builds when beneficial
- Follow Docker best practices
- Minimize layers

### Documentation

- Keep README.md up to date
- Document all environment variables
- Provide examples for common use cases
- Use clear, simple language

## Areas for Contribution

We welcome contributions in these areas:

### High Priority

- [ ] Automated testing suite
- [ ] Performance optimizations
- [ ] Additional authentication methods
- [ ] Better error messages and logging

### Medium Priority

- [ ] Plugin/mod management improvements
- [ ] Metrics and monitoring integration
- [ ] Backup/restore automation
- [ ] Configuration templates

### Nice to Have

- [ ] Web UI for management
- [ ] Kubernetes Helm charts
- [ ] Additional examples
- [ ] Translations

## Getting Help

- Check the [README.md](README.md) for documentation
- Look through [existing issues](https://github.com/ginco-org/hytale-server/issues)
- Read the [Hytale Server Manual](https://support.hytale.com/hc/en-us/articles/45326769420827)
- Ask questions in GitHub Discussions

## Code of Conduct

- Be respectful and inclusive
- Welcome newcomers
- Focus on constructive feedback
- Help others learn

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
