# Use Alpine Linux for its small footprint
FROM alpine:latest

# License information
LABEL org.opencontainers.image.licenses="Apache-2.0"

# Expose the default Minecraft server port
EXPOSE 25565

# Set a default environment variable for Java heap size
ENV MEMORY=640m

# Install necessary packages
RUN apk add --no-cache openjdk21-jre wget bash udev jq curl bc

# Add a user for the Minecraft server to run under
RUN adduser -D mcuser

# Set the working directory
WORKDIR /home/mcuser

# Copy the entry point script
COPY entrypoint.sh .

# Change ownership to mcuser
RUN chown mcuser:mcuser entrypoint.sh

# Make the entry point script executable
RUN chmod +x entrypoint.sh

# Switch to user mcuser
USER mcuser

# Use the entry point script to start the container
ENTRYPOINT ["./entrypoint.sh"]