#!/bin/bash

# Common functions for all services
# This file can be sourced by other scripts

# Colors for output
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Check if environment variable is set
check_env() {
    local var_name=$1
    local var_value=${!var_name}
    
    if [ -z "$var_value" ]; then
        error "$var_name is not set!"
        return 1
    fi
    return 0
}

# Wait for service to be ready
wait_for_service() {
    local host=$1
    local port=$2
    local max_tries=${3:-60}
    local wait_time=${4:-1}
    
    log "Waiting for $host:$port to be ready..."
    
    for i in $(seq 1 $max_tries); do
        if nc -z "$host" "$port" 2>/dev/null; then
            log "$host:$port is ready!"
            return 0
        fi
        echo -n "."
        sleep $wait_time
    done
    
    error "$host:$port did not become ready in time"
    return 1
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir=$1
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        log "Created directory: $dir"
    fi
}

# Set ownership recursively
set_ownership() {
    local path=$1
    local owner=$2
    chown -R "$owner" "$path"
    log "Set ownership of $path to $owner"
}
