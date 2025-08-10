#!/usr/bin/env python3

import subprocess
import time

def run_command(cmd):
    """Run a command and return output"""
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        return result.stdout, result.stderr, result.returncode
    except Exception as e:
        return "", str(e), 1

print("=" * 50)
print("Manual Database Fix for 42-Inception")
print("=" * 50)

# Check current databases
print("\n1. Checking current databases...")
stdout, stderr, code = run_command("docker exec mariadb mysql -e 'SHOW DATABASES;'")
if code == 0:
    print(stdout)
else:
    print(f"Error: {stderr}")

# Create database and user
print("\n2. Creating WordPress database and user...")
sql_commands = """
CREATE DATABASE IF NOT EXISTS wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS 'nkannan'@'%' IDENTIFIED BY 'tsuchiura';
GRANT ALL PRIVILEGES ON wordpress.* TO 'nkannan'@'%';
CREATE USER IF NOT EXISTS 'nkannan'@'localhost' IDENTIFIED BY 'tsuchiura';
GRANT ALL PRIVILEGES ON wordpress.* TO 'nkannan'@'localhost';
FLUSH PRIVILEGES;
"""

# Write SQL commands to a temporary file
with open('/tmp/setup.sql', 'w') as f:
    f.write(sql_commands)

# Execute SQL commands
stdout, stderr, code = run_command("docker exec -i mariadb mysql < /tmp/setup.sql")
if code == 0:
    print("✓ Database and user created successfully")
else:
    print(f"Error creating database: {stderr}")

# Verify database creation
print("\n3. Verifying database creation...")
stdout, stderr, code = run_command("docker exec mariadb mysql -e 'SHOW DATABASES;'")
if code == 0 and "wordpress" in stdout:
    print("✓ WordPress database exists")
    print(stdout)
else:
    print("✗ WordPress database not found")

# Check users
print("\n4. Checking database users...")
stdout, stderr, code = run_command("docker exec mariadb mysql -e \"SELECT User, Host FROM mysql.user WHERE User='nkannan';\"")
if code == 0:
    print(stdout)
else:
    print(f"Error: {stderr}")

# Test connection with WordPress credentials
print("\n5. Testing connection with WordPress credentials...")
stdout, stderr, code = run_command("docker exec mariadb mysql -unkannan -ptsuchiura wordpress -e \"SELECT 'Connection successful!' as Result;\"")
if code == 0:
    print("✓ Connection successful!")
    print(stdout)
else:
    print(f"✗ Connection failed: {stderr}")

# Restart WordPress container
print("\n6. Restarting WordPress container...")
stdout, stderr, code = run_command("docker restart wordpress")
if code == 0:
    print("✓ WordPress container restarted")
else:
    print(f"Error: {stderr}")

# Wait for WordPress to initialize
print("\n7. Waiting for WordPress to initialize...")
for i in range(10):
    print(".", end="", flush=True)
    time.sleep(1)
print()

# Check WordPress logs
print("\n8. Recent WordPress logs:")
stdout, stderr, code = run_command("docker logs wordpress --tail 30")
print(stdout)

# Check if WordPress is accessible
print("\n9. Testing WordPress installation...")
stdout, stderr, code = run_command("docker exec wordpress wp core is-installed --allow-root --path=/var/www/wordpress")
if code == 0:
    print("✓ WordPress is installed!")
else:
    print("✗ WordPress is not installed yet")
    print("Checking wp-config.php...")
    stdout, stderr, code = run_command("docker exec wordpress cat /var/www/wordpress/wp-config.php | grep DB_")
    if code == 0:
        print("Database configuration in wp-config.php:")
        for line in stdout.split('\n'):
            if 'DB_' in line and 'define' in line:
                print(f"  {line.strip()}")

print("\n" + "=" * 50)
print("Fix process completed!")
print("=" * 50)
print("\nYou can now access:")
print("  https://nkannan.42.fr")
print("  https://nkannan.42.fr/wp-admin")
