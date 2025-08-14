FROM node:20-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    unzip curl jq ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Store initial installation outside of the volume path
WORKDIR /opt/gunthy.dist
ADD https://gunthy.org/downloads/gunthy_linux.zip /tmp/gunthy_linux.zip
RUN unzip /tmp/gunthy_linux.zip -d /opt/gunthy.dist \
    && rm /tmp/gunthy_linux.zip \
    && chmod +x ./gunthy-linux

# This is the persistent mount point
VOLUME ["/opt/gunthy"]

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default workdir is the volume
WORKDIR /opt/gunthy
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["./gunthy-linux"]
