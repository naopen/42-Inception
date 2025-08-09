FROM debian:bullseye

# Install MariaDB
RUN apt-get update && apt-get install -y \
    mariadb-server \
    mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration file
COPY conf/50-server.cnf /etc/mysql/mariadb.conf.d/50-server.cnf

# Copy initialization script
COPY tools/init_db.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/init_db.sh

# Create mysql run directory
RUN mkdir -p /var/run/mysqld && \
    chown -R mysql:mysql /var/run/mysqld && \
    chmod 755 /var/run/mysqld

# Expose MySQL port
EXPOSE 3306

# Run the initialization script
ENTRYPOINT ["/usr/local/bin/init_db.sh"]

# Start MariaDB
CMD ["mysqld"]
