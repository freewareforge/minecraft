#!/bin/bash

# Define the log file and start redirection
LOG_FILE="/home/mcuser/minecraft_server.log"
exec > >(tee -a "$LOG_FILE") 2>&1

# Set error handling
set -e

# Trap function to log the error and the command that caused it
error_handler() {
    local exit_code=$?
    echo "Error: Command failed with exit code $exit_code."
    echo "Failed command: ${BASH_COMMAND}"
    exit $exit_code
}

# Define input and output pipes for the java process
FIFO_INPUT="/tmp/minecraft-input"
FIFO_OUTPUT="/tmp/minecraft-output"

# Create input and output channels for server
mkfifo $FIFO_INPUT
mkfifo $FIFO_OUTPUT

# Keep output pipe open (workaround so redirection of final server process does not block logging)
cat $FIFO_OUTPUT > /dev/null &

# Define server file name and record for last downloaded version
SERVER_JAR="server.jar"
LAST_URL_FILE="/home/mcuser/last_url.txt"

# Function to fetch the latest server JAR URL
fetch_latest_jar_url() {
    local manifest_url="https://launchermeta.mojang.com/mc/game/version_manifest.json"
    local version_manifest=$(curl -s $manifest_url)
    echo $(echo "$version_manifest" | jq -r 'first(.versions[] | select(.type == "release").url)')
}

# Function to check and update the server if needed, or download for the first time
install_or_update() {
    echo "Checking for latest server version..."
    local latest_url=$(fetch_latest_jar_url)
    local latest_jar_url=$(curl -s $latest_url | jq -r '.downloads.server.url')

    # Check if the latest URL is different from the last run
    if [ -f "$LAST_URL_FILE" ]; then
        local last_url=$(cat $LAST_URL_FILE)
        if [ "$latest_jar_url" != "$last_url" ]; then
            echo "New server version found. Updating..."
            wget $latest_jar_url -O $SERVER_JAR
            echo $latest_jar_url > $LAST_URL_FILE
        fi
        echo "Latest server version already installed."
    else
        echo "Downloading latest server for first time..."
        echo $latest_jar_url > $LAST_URL_FILE
        wget $latest_jar_url -O $SERVER_JAR
    fi
}

# Function to monitor server output and trigger action when ready
monitor_and_op() {
    # Monitor the output FIFO for the specific readiness message
    grep -m 1 "\[Server thread/INFO\]: Done" $FIFO_OUTPUT
    echo "Server is ready, sending 'op username' command..."
    echo "op $MC_USER" > $FIFO_INPUT
    echo "'op username' command sent to Minecraft server."
}

# Extract memory size and unit (if unspecified, assumed megabytes)
memory_value=$(echo "$MEMORY" | grep -o -E '^[0-9]+(\.[0-9]+)?')
memory_unit=$(echo "$MEMORY" | grep -o -E '[mMgG]?$')

# Validate memory unit (should be m/M or g/G or empty)
if [[ -n "$MEMORY" ]] && [[ ! "$memory_unit" =~ ^[mMgG]?$ ]]; then
    echo "Error: Memory must be described in Megabytes (m) or Gigabytes (g), for example 512m or 0.5g."
    exit 1
fi

# Convert memory to megabytes if needed
if [[ "$memory_unit" =~ ^[gG]$ ]]; then
    memory_value=$(echo "$memory_value * 1024" | bc) # Convert gigabytes to megabytes
    memory_value=$(printf "%.0f" "$memory_value")  # Format as integer, remove decimal
fi

# Ensure a minimum memory allocation of 512 MB
if [[ "$memory_value" -lt 512 ]]; then
    echo "Error: JAVA_HEAP must allocate at least 512m of memory."
    exit 1
fi

JAVA_OPTS="-Xmx${memory_value}m -Xms${memory_value}m"

# Check for server initialization
INITIALIZED_FILE="/home/mcuser/initialized"

if [ ! -f "$INITIALIZED_FILE" ]; then

    # Download server
    install_or_update

    # Initialize server
    echo "Initializing server..."
    java $JAVA_OPTS -jar server.jar nogui
    echo "Accepting EULA automatically on your behalf..."
    sed -i 's/eula=false/eula=true/g' eula.txt

    # Create file indicating initialization has occurred
    echo "Server initialized."
    touch "$INITIALIZED_FILE"

    # Only op the user if MINECRAFT_USERNAME is provided
    if [ -n "$MC_USER" ]; then
        echo "Monitoring for server start to set admin..."
        monitor_and_op &
    fi

else

    # Update the server if needed

    install_or_update

fi

# Start server with IO channels
echo "Starting server..."
tail -f $FIFO_INPUT | java $JAVA_OPTS -jar server.jar nogui | tee $FIFO_OUTPUT
