resource "oci_identity_compartment" "minecraft_compartment" {
  name           = var.compartment_name
  compartment_id = var.tenancy_ocid
  description    = "Compartment created for Minecraft resources"
  enable_delete  = true # Set to true to allow deletion of the compartment
}