resource "oci_core_vcn" "vcn0" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = oci_identity_compartment.minecraft_compartment.id
  display_name   = "VCN0"
  depends_on = [oci_identity_compartment.minecraft_compartment]
}

resource "oci_core_internet_gateway" "igw" {
  compartment_id = oci_identity_compartment.minecraft_compartment.id
  display_name   = "IGW"
  vcn_id         = oci_core_vcn.vcn0.id
}

resource "oci_core_route_table" "rt" {
  compartment_id = oci_identity_compartment.minecraft_compartment.id
  vcn_id         = oci_core_vcn.vcn0.id
  route_rules {
    network_entity_id = oci_core_internet_gateway.igw.id
    destination        = "0.0.0.0/0"
    destination_type   = "CIDR_BLOCK"
  }
}

resource "oci_core_security_list" "minecraft" {
  compartment_id = oci_identity_compartment.minecraft_compartment.id
  vcn_id         = oci_core_vcn.vcn0.id
  egress_security_rules {
    protocol = "all"
    destination = "0.0.0.0/0"
  }
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      max = 25565
      min = 25565
    }
  }
  ingress_security_rules {
    protocol = "6" # TCP
    source   = "0.0.0.0/0"
    tcp_options {
      max = 22
      min = 22
    }
  }
}

resource "oci_core_subnet" "public_subnet" {
  compartment_id      = oci_identity_compartment.minecraft_compartment.id
  vcn_id              = oci_core_vcn.vcn0.id
  cidr_block          = "10.0.0.0/24"
  display_name        = "Public"
  route_table_id      = oci_core_route_table.rt.id
  security_list_ids   = [oci_core_security_list.minecraft.id]
  prohibit_public_ip_on_vnic = false
}