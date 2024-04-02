#!/bin/bash

# Navigate to the desired directory
cd /opt/minecraft

# Download the Minecraft server jar
wget --tries=5 --waitretry=10 -O server.jar https://piston-data.mojang.com/v1/objects/8dd1a28015f51b1803213892b50b7b4fc76e594d/server.jar

# Run the Minecraft server
java -Xmx4096M -Xms1024M -jar server.jar nogui

# Accept EULA after the server's first termination (which generates eula.txt)
sed -i 's/eula=false/eula=true/g' eula.txt

# Then, run the Minecraft server again
java -Xmx4096M -Xms1024M -jar server.jar nogui