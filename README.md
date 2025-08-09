# 42 Inception

## Description
This project aims to broaden knowledge of system administration by using Docker. It sets up a small infrastructure composed of different services under specific rules using Docker Compose.

## Architecture
- **NGINX**: Web server with TLS v1.2/v1.3 support (port 443 only)
- **WordPress**: PHP-FPM based WordPress installation
- **MariaDB**: Database server
- **Docker Network**: Custom bridge network for container communication
- **Volumes**: Persistent storage for WordPress files and MariaDB data

## Prerequisites
- Docker
- Docker Compose
- Make
- sudo privileges (for volume management)

## Installation

1. Clone the repository:
```bash
git clone https://github.com/na-kannan/42-Inception.git
cd 42-Inception
```

2. Configure environment variables:
```bash
cp srcs/.env.example srcs/.env
# Edit srcs/.env with your settings
```

3. Build and run the containers:
```bash
make
```

## Usage

### Available Commands
- `make` or `make all`: Build and start all containers
- `make up`: Start containers with build
- `make down`: Stop and remove containers
- `make stop`: Stop containers
- `make start`: Start stopped containers
- `make restart`: Restart all containers
- `make logs`: View container logs
- `make ps`: List running containers
- `make clean`: Remove containers and images
- `make fclean`: Complete cleanup including volumes
- `make re`: Complete rebuild

## Security Features
- TLS v1.2/v1.3 only
- No HTTP access (HTTPS only on port 443)
- Environment variables for sensitive data
- Self-signed SSL certificate
- Isolated Docker network
- Non-root container processes where possible

## Directory Structure
```
.
├── Makefile
└── srcs/
    ├── docker-compose.yml
    ├── .env
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            └── tools/
```

## Volumes
Data is persisted in:
- `/home/$USER/data/wordpress`: WordPress files
- `/home/$USER/data/mariadb`: MariaDB database

## Author
- na-kannan (na-kannan@student.42.fr)
