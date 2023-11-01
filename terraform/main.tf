variable "config_file_profile" { type = string }
variable "home_region" { type = string }
variable "region" { type = string }
variable "tenancy_id" { type = string }
variable "compartment_id" { type = string }
variable "ssh_public_key_path" { type = string }
variable "ssh_private_key_path" { type = string }

module "oke" {
  source  = "oracle-terraform-modules/oke/oci"
  version = "5.0.0"

  # Provider
  providers           = { oci.home = oci.home }
  config_file_profile = var.config_file_profile
  home_region         = var.home_region
  region              = var.region
  tenancy_id          = var.tenancy_id
  compartment_id      = var.compartment_id
  ssh_public_key_path = var.ssh_public_key_path
  ssh_private_key_path = var.ssh_private_key_path
  
  kubernetes_version = "v1.27.2"
  cluster_type = "enhanced"
  cluster_name         = "oke-kuberay"
  bastion_allowed_cidrs = ["0.0.0.0/0"]
  allow_worker_ssh_access     = true
  control_plane_allowed_cidrs = ["0.0.0.0/0"]
  control_plane_is_public = true

  # Resource creation
  assign_dns           = false
  create_vcn           = true
  create_bastion       = false
  create_cluster       = true
  create_operator      = false
  create_iam_resources = false
  use_defined_tags     = false


  worker_pools = {
   cpu = {
     description = "CPU pool", enabled = true,
     mode        = "node-pool", boot_volume_size = 150, shape = "VM.Standard.E3.Flex", ocpus = 8, memory = 128, size = 1,
    }

    a10 = {
      description = "VM.GPU.A10.1 pool", enabled = true,
      mode        = "node-pool", shape = "VM.GPU.A10.1", boot_volume_size = 150, placement_ads = [1], size = 1,
    } 
  }
}
terraform {
  required_providers {
    oci = {
      configuration_aliases = [oci.home]
      source                = "oracle/oci"
      version               = ">= 5.4.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "oci" {
  config_file_profile = var.config_file_profile
  region              = var.region
  tenancy_ocid        = var.tenancy_id
}

provider "oci" {
  alias               = "home"
  config_file_profile = var.config_file_profile
  region              = var.home_region
  tenancy_ocid        = var.tenancy_id
}
