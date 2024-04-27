output "server_public_ip" {
  description = "The IP address to enter in Minecraft to connect to the server"
  value = oci_core_instance.minecraft_server.public_ip
}