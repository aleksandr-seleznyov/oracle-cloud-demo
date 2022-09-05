
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    oci = {
      version = ">= 4.90"
      source  = "oracle/oci"
    }
  }
}

variable "private_key" {
  default = ""
}

provider "oci" {
  region = "eu-frankfurt-1"
  private_key = var.private_key

}


resource "oci_identity_compartment" "tf-compartment" {
  description = "Compartment for Terraform resources."
  name        = "tf-compartment"
}

locals {
  vcn_cidr_block                = "10.0.0.0/16"
  public_subnet_cidr_block      = "10.0.10.0/24"
  private_subnet_cidr_block     = "10.0.20.0/24"
  oracle_linux_8_amd64_image_id = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaandftbicox5dje7ufgporxov4o3wckbu5mxw27tyjxolekjwrcgsq"
  oracle_linux_8_arm64_image_id = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaanbxc5ihgflyoyfe7bzohdkovitufny4lyc5hn7wodgao44ljs27a"

}