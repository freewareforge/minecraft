#!/bin/bash

# Navigate to the desired directory
cd /opt/minecraft

# Check for initialized file
if [ ! -f initialized ]; then

    echo "Initializing server, then running..."

    # Set the admin username from file created by user_data

    MINECRAFT_USERNAME=$(cat /opt/minecraft/username)
    echo "$MINECRAFT_USERNAME will be made server admin."

    # Download the Minecraft server jar
    wget --tries=5 --waitretry=10 --read-timeout=30 -O server.jar https://piston-data.mojang.com/v1/objects/79493072f65e17243fd36a699c9a96b4381feb91/server.jar

    # Run the Minecraft server
    java -Xmx4096M -Xms1024M -jar server.jar nogui

    # Accept EULA after the server's first termination (which generates eula.txt)
    sed -i 's/eula=false/eula=true/g' eula.txt

    # Then, run the Minecraft server again
    tmux new-session -d -s minecraft 'java -Xmx4096M -Xms1024M -jar server.jar nogui'

    # Wait a bit, then issue Minecraft server console command to make user admin, using the variable exported by the user_data
    sleep 30
    tmux send-keys -t minecraft "op $MINECRAFT_USERNAME" Enter

    # Unset the variable and cleanup the username file.

    unset MINECRAFT_USERNAME
    rm -f username

    # Create initialized file
    touch initialized

else

    # Directly run the server

    echo "Server previously initialized, running server now."

    tmux new-session -d -s minecraft 'java -Xmx4096M -Xms1024M -jar server.jar nogui'

fi