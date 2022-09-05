resource "oci_core_instance" "access-vm" {
  display_name        = "access-vm-amd64"
  availability_domain = "BxoK:EU-FRANKFURT-1-AD-1"
  compartment_id      = oci_identity_compartment.tf-compartment.id
  shape               = "VM.Standard.E2.1.Micro"


  metadata = {
    ssh_authorized_keys = file("ssh-keys/inst-public.key.pub")
  }

  create_vnic_details {
    assign_public_ip = false
    display_name     = "access-vm-vnic"
    subnet_id        = oci_core_subnet.private.id
    hostname_label = "access"
  }

  source_details {
    source_id               = local.oracle_linux_8_amd64_image_id
    source_type             = "image"
    boot_volume_size_in_gbs = "50"
  }

  agent_config {
    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }

  preserve_boot_volume = false
}


resource "oci_core_instance" "kubernetes-master-vm" {
  display_name        = "k8s-master"
  availability_domain = "BxoK:EU-FRANKFURT-1-AD-1"
  compartment_id      = oci_identity_compartment.tf-compartment.id
  shape               = "VM.Standard.A1.Flex"

  metadata = {
    ssh_authorized_keys = file("ssh-keys/inst-public.key.pub")
  }

  create_vnic_details {
    assign_public_ip = false
    display_name     = "k8s-master-vnic"
    subnet_id        = oci_core_subnet.private.id
    hostname_label = "k8s-master"
  }

  source_details {
    source_id               = local.oracle_linux_8_arm64_image_id
    source_type             = "image"
    boot_volume_size_in_gbs = "50"
  }

  shape_config {
    ocpus         = "2"
    memory_in_gbs = "12"
  }

  agent_config {
    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }

  preserve_boot_volume = false
}

resource "oci_core_instance" "kubernetes-node-001-vm" {
  display_name        = "k8s-arm64-node-001"
  availability_domain = "BxoK:EU-FRANKFURT-1-AD-1"
  compartment_id      = oci_identity_compartment.tf-compartment.id
  shape               = "VM.Standard.A1.Flex"

  metadata = {
    ssh_authorized_keys = file("ssh-keys/inst-public.key.pub")
  }

  create_vnic_details {
    assign_public_ip = false
    display_name     = "k8s-arm64-node-vnic"
    subnet_id        = oci_core_subnet.private.id
    hostname_label = "k8s-arm64-node-001"
  }

  source_details {
    source_id               = local.oracle_linux_8_arm64_image_id
    source_type             = "image"
    boot_volume_size_in_gbs = "50"
  }

  shape_config {
    ocpus         = "2"
    memory_in_gbs = "12"
  }

  agent_config {
    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }

  preserve_boot_volume = false
}


resource "oci_core_instance" "kubernetes-node-002-vm" {
  display_name        = "k8s-amd64-node-002"
  availability_domain = "BxoK:EU-FRANKFURT-1-AD-1"
  compartment_id      = oci_identity_compartment.tf-compartment.id
  shape               = "VM.Standard.E2.1.Micro"

  metadata = {
    ssh_authorized_keys = file("ssh-keys/inst-public.key.pub")
  }

  create_vnic_details {
    assign_public_ip = false
    display_name     = "k8s-amd64-node-002-vnic"
    subnet_id        = oci_core_subnet.private.id
    hostname_label = "k8s-amd64-node-002"
  }

  source_details {
    source_id               = local.oracle_linux_8_amd64_image_id
    source_type             = "image"
    boot_volume_size_in_gbs = "50"
  }

  agent_config {
    plugins_config {
      desired_state = "ENABLED"
      name          = "Bastion"
    }
  }

  preserve_boot_volume = false
}