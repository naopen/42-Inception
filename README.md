# 42 Inception Project

A Docker-based infrastructure project that sets up WordPress with NGINX and MariaDB using Docker Compose.

## 🎯 Project Overview

This project creates a complete web infrastructure with:
- **NGINX**: Web server with SSL/TLS (port 443 only)
- **WordPress**: PHP-FPM based WordPress installation
- **MariaDB**: Database server
- **Docker**: Containerization of all services
- **Docker Compose**: Orchestration of containers

## ✅ Evaluation Requirements Met

### Security & Configuration
- ✅ HTTPS only (port 443) with TLSv1.2/TLSv1.3
- ✅ Self-signed SSL certificate
- ✅ No hardcoded passwords (uses .env file)
- ✅ Automatic WordPress configuration (no GUI setup needed)
- ✅ Two users created automatically (admin + regular user)
- ✅ Admin username doesn't contain "admin"

### Docker Requirements
- ✅ One Dockerfile per service
- ✅ Built from Debian stable base image
- ✅ No ready-made Docker images used
- ✅ No 'network: host' or 'links:' usage
- ✅ Docker network for container communication
- ✅ Automatic container restart on crash
- ✅ No infinite loops or hacky solutions

### Data Persistence
- ✅ WordPress files volume
- ✅ MariaDB database volume
- ✅ Volumes bind-mounted to host filesystem

## 📁 Project Structure

```
.
├── Makefile                    # Build and management commands
├── srcs/
│   ├── .env                    # Environment variables (create from .env.example)
│   ├── docker-compose.yml      # Docker Compose configuration
│   └── requirements/
│       ├── nginx/
│       │   ├── Dockerfile
│       │   ├── conf/           # NGINX configuration
│       │   └── tools/          # SSL generation & entrypoint
│       ├── wordpress/
│       │   ├── Dockerfile
│       │   ├── conf/           # PHP-FPM configuration
│       │   └── tools/          # WordPress auto-setup script
│       └── mariadb/
│           ├── Dockerfile
│           ├── conf/           # MariaDB configuration
│           └── tools/          # Database initialization
└── data/                       # Data volumes (created automatically)
    ├── wordpress/
    └── mariadb/
```

## 🚀 Quick Start

### 1. Prerequisites
- Docker and Docker Compose installed
- Make installed
- Root/sudo access for volume management

### 2. Configuration

Create `.env` file in `srcs/` directory:
```bash
cp srcs/.env.example srcs/.env
# Edit srcs/.env with your configuration
```

Required environment variables:
- `DOMAIN_NAME`: Your domain (e.g., `login.42.fr`)
- `DATA_PATH`: Path for data volumes
- Database credentials
- WordPress admin credentials

### 3. Build and Run

```bash
# Build and start all services
make

# Or use specific commands:
make up      # Start services
make down    # Stop services
make restart # Restart services
make logs    # View logs
make info    # Show configuration
make check   # Verify evaluation requirements
```

### 4. Access WordPress

- **Site URL**: `https://YOUR_DOMAIN_NAME`
- **Admin Panel**: `https://YOUR_DOMAIN_NAME/wp-admin`

## 🔧 Makefile Commands

| Command | Description |
|---------|-------------|
| `make` / `make up` | Build and start all services |
| `make down` | Stop and remove containers |
| `make stop` | Stop containers without removing |
| `make start` | Start stopped containers |
| `make restart` | Restart all services |
| `make logs` | View all logs |
| `make logs-SERVICE` | View specific service logs |
| `make ps` | Show container status |
| `make clean` | Remove containers and images |
| `make fclean` | Complete cleanup including data |
| `make re` | Rebuild from scratch |
| `make info` | Display configuration |
| `make check` | Check evaluation requirements |
| `make shell-SERVICE` | Access service shell |
| `make db` | Access MariaDB console |
| `make wp ARGS` | Run WP-CLI commands |
| `make help` | Show help message |

## 🔐 Security Features

- SSL/TLS encryption (v1.2/v1.3 only)
- Security headers (HSTS, X-Frame-Options, etc.)
- Database user isolation
- File permission management
- Disabled XML-RPC
- Hidden WordPress version
- Protected wp-config.php

## 🎓 Evaluation Checklist

Run the evaluation check:
```bash
make check
```

Manual verification steps:
1. ✅ Access https://YOUR_DOMAIN - Should show WordPress site
2. ✅ No installation page should appear
3. ✅ Login as admin user
4. ✅ Create/edit content
5. ✅ Login as regular user
6. ✅ Add comments
7. ✅ Restart VM and verify data persistence

## 🐛 Troubleshooting

### Port 443 Already in Use
```bash
sudo lsof -i :443
# Kill the process using the port
```

### Permission Issues
```bash
# Fix data directory permissions
sudo chown -R $USER:$USER data/
```

### Container Issues
```bash
# Check logs
make logs-SERVICE_NAME

# Access container shell
make shell-SERVICE_NAME

# Complete cleanup and rebuild
make fclean
make
```

### Database Connection Issues
```bash
# Check MariaDB logs
make logs-mariadb

# Access database console
make db
```

## 📚 Technical Details

### Automatic WordPress Configuration

The WordPress setup script (`wp_setup.sh`) automatically:
- Downloads WordPress core files
- Creates wp-config.php with security salts
- Installs WordPress with provided credentials
- Creates two users (admin and regular)
- Configures permalinks and settings
- Creates initial content
- Sets proper file permissions

### NGINX Configuration

- Listens only on port 443 (HTTPS)
- TLS v1.2 and v1.3 only
- Security headers enabled
- Optimized for WordPress
- Gzip compression
- Static file caching

### MariaDB Configuration

- Optimized buffer sizes
- UTF8MB4 character set
- Query optimization
- Security hardening
- Automatic user creation

## 📝 Notes for Evaluators

1. **No GUI Setup Required**: WordPress is fully configured automatically
2. **Credentials**: All credentials are in the `.env` file
3. **Persistence**: Data survives container restarts
4. **Security**: No hardcoded passwords, proper isolation
5. **Compliance**: Meets all 42 project requirements

## 🤝 Contributing

This is a 42 School project. While contributions are welcome for learning purposes, please note that students must complete their own implementation for academic integrity.

## 📄 License

This project is part of the 42 School curriculum.

---

**Author**: nkannan (42 Tokyo)  
**Project**: Inception  
**Score Goal**: 125/100 (with bonus)
