resource "oci_core_instance" "minecraft_server" {
  availability_domain = var.availability_domain_name
  compartment_id      = oci_identity_compartment.minecraft_compartment.id
  shape               = "VM.Standard.A1.Flex"
  depends_on = [oci_core_subnet.public_subnet]

  shape_config {
    ocpus         = 1
    memory_in_gbs = 6
  }

  create_vnic_details {
    assign_public_ip = true
    subnet_id        = oci_core_subnet.public_subnet.id
  }

  source_details {
    source_type = "image"
    source_id   = "ocid1.image.oc1..aaaaaaaa4bhzxdzvzl2ekifexq23ygl7bkw5v3lk7eamleusll25o7eyd52q"
  }

  metadata = {
    user_data = base64encode(<<-EOF
      #!/bin/bash
      exec > >(tee /var/log/tf-user_data.log) 2>&1
      set -e
      useradd -m -s /bin/bash ${var.user_name}
      echo "${var.user_name}:${var.user_password}" | chpasswd
      usermod -aG wheel mcuser
      sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
      systemctl restart sshd
      yum install java-21 -y
      yum install wget -y
      yum install tmux -y
      yum install firewalld -y
      firewall-offline-cmd --zone=public --add-port=25565/tcp
      systemctl enable firewalld
      systemctl start firewalld
      mkdir /opt/minecraft
      chown mcuser:mcuser /opt/minecraft
      cat <<'STARTUP_SCRIPT' > /opt/minecraft/startup.sh
      ${file("startup.sh")}
      STARTUP_SCRIPT
      chmod +x /opt/minecraft/startup.sh
      chown mcuser:mcuser /opt/minecraft/startup.sh
      cat <<'MINECRAFT_SERVICE' > /etc/systemd/system/minecraft.service
      ${file("minecraft.service")}
      MINECRAFT_SERVICE
      echo ${var.minecraft_username} > /opt/minecraft/username
      systemctl daemon-reload
      systemctl enable minecraft.service
      systemctl start minecraft.service
      EOF
    )
  }
}