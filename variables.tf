variable "tenancy_ocid" {
  description = "Do not edit this unless you want the Minecraft compartment to be a child of something other than root."
}

variable "availability_domain_name" {
  description = "Try changing this if the stack fails to deploy an Ampere instance.  Availability may be limited."
}

variable "compartment_name" {
  description = "The name for the new compartment (child of root) to house this game server.  Must be unique in the tenancy."
  type        = string
  default     = "Minecraft"
}

variable "user_name" {
  description = "Username for login to the instance"
  type        = string
  default     = "mcuser"
}

variable "user_password" {
  description = "Password for login to the instance. This should be very strong. Recommend a long phrase you can remember."
  type        = string
}