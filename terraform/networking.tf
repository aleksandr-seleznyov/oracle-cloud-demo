resource "oci_core_vcn" "main" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  cidr_block     = local.vcn_cidr_block
  display_name   = "Main VCN"
  dns_label = "local"
}

resource "oci_core_internet_gateway" "igw-main" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "Main Internet Gateway"
}


resource "oci_core_nat_gateway" "ngw-main" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "Main NAT Gateway"
}


resource "oci_bastion_bastion" "bastion" {
  bastion_type                 = "STANDARD"
  compartment_id               = oci_identity_compartment.tf-compartment.id
  target_subnet_id             = oci_core_subnet.private.id
  client_cidr_block_allow_list = ["0.0.0.0/0"]
  name                         = "BastionMain"
}



data "oci_core_services" "all_oci_services" {
  filter {
    name   = "name"
    values = ["All .* Services In Oracle Services Network"]
    regex  = true
  }
}

resource "oci_core_service_gateway" "sgw-main" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "Main Service Gateway"
  services {
    service_id = lookup(data.oci_core_services.all_oci_services.services[0], "id")
  }
}


resource "oci_core_route_table" "rt-public" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  vcn_id         = oci_core_vcn.main.id
  display_name   = "Public Subnet Route Table"


  route_rules {
    description       = "Internet Route"
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.igw-main.id
  }
}

resource "oci_core_default_route_table" "rt-private" {
  manage_default_resource_id = oci_core_vcn.main.default_route_table_id
  compartment_id             = oci_identity_compartment.tf-compartment.id
  display_name               = "Private Subnet Route Table"


  route_rules {
    description       = "Internet Route"
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_nat_gateway.ngw-main.id
  }

}

resource "oci_core_subnet" "public" {
  cidr_block                 = local.public_subnet_cidr_block
  compartment_id             = oci_identity_compartment.tf-compartment.id
  vcn_id                     = oci_core_vcn.main.id
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.rt-public.id
  display_name               = "Public Subnet"
  dns_label = "public"
}

resource "oci_core_subnet" "private" {
  cidr_block                 = local.private_subnet_cidr_block
  compartment_id             = oci_identity_compartment.tf-compartment.id
  vcn_id                     = oci_core_vcn.main.id
  prohibit_public_ip_on_vnic = true
  route_table_id             = oci_core_default_route_table.rt-private.id
  display_name               = "Private Subnet"
  dns_label = "private"
}

# Protocol numbers: https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
resource "oci_core_default_security_list" "sl-vcn" {
  manage_default_resource_id = oci_core_vcn.main.default_security_list_id
  compartment_id             = oci_identity_compartment.tf-compartment.id
  display_name               = "Main Security List"

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = local.vcn_cidr_block
    description = "Allow all inbound traffic from VCN"
  }

  ingress_security_rules {
    protocol    = "1" # ICMP
    source      = local.vcn_cidr_block
    description = "Allow ICMP"
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "Allow 80 from Internet"

    tcp_options {
      max = "80"
      min = "80"
    }
  }

  ingress_security_rules {
    protocol    = "6" # TCP
    source      = "0.0.0.0/0"
    description = "Allow 443 from Internet"
    tcp_options {
      max = "443"
      min = "443"
    }
  }

  egress_security_rules {
    protocol    = "6" # TCP
    destination = "0.0.0.0/0"
    description = "Allow all outbound traffic"
  }

}

resource "oci_network_load_balancer_network_load_balancer" "access-nlb" {
  compartment_id                 = oci_identity_compartment.tf-compartment.id
  display_name                   = "Access NLB"
  subnet_id                      = oci_core_subnet.public.id
  is_preserve_source_destination = false
  is_private                     = false
}

resource "oci_network_load_balancer_listener" "access-nlb" {
  default_backend_set_name = oci_network_load_balancer_backend_set.teleport.name
  name                     = "teleport"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.access-nlb.id
  port                     = 443
  protocol                 = "TCP"
}

resource "oci_network_load_balancer_backend_set" "teleport" {
  name                     = "teleport"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.access-nlb.id
  policy                   = "FIVE_TUPLE"
  health_checker {
    protocol           = "TCP"
    timeout_in_millis  = 3000
    interval_in_millis = 10000
    retries            = 3
    port               = 443
  }
}

resource "oci_network_load_balancer_backend" "teleport" {
  name                     = "teleport"
  backend_set_name         = oci_network_load_balancer_backend_set.teleport.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.access-nlb.id
  port                     = 443
  target_id                = oci_core_instance.access-vm.id
  weight                   = 1
}

resource "oci_load_balancer" "applications-lb" {
  compartment_id = oci_identity_compartment.tf-compartment.id
  display_name   = "Applications LB"
  shape          = "flexible"
  shape_details {
    maximum_bandwidth_in_mbps = 10
    minimum_bandwidth_in_mbps = 10
  }
  subnet_ids     = [oci_core_subnet.public.id]
  is_private     = false
}


resource "oci_load_balancer_backend_set" "applications-lb" {
  name             = "k8s-nodes"
  load_balancer_id = oci_load_balancer.applications-lb.id
  policy           = "ROUND_ROBIN"
  health_checker {
    protocol          = "TCP"
    timeout_in_millis = 3000
    interval_ms       = 10000
    retries           = 3
    port              = 80
  }
}


resource "oci_load_balancer_backend" "k8s-master" {
  load_balancer_id = oci_load_balancer.applications-lb.id
  port             = 80
  weight           = 1
  backendset_name  = oci_load_balancer_backend_set.applications-lb.name
  ip_address       = oci_core_instance.kubernetes-master-vm.private_ip
}

resource "oci_load_balancer_backend" "k8s-node-001" {
  load_balancer_id = oci_load_balancer.applications-lb.id
  port             = 80
  weight           = 1
  backendset_name  = oci_load_balancer_backend_set.applications-lb.name
  ip_address       = oci_core_instance.kubernetes-node-001-vm.private_ip
}

resource "oci_load_balancer_backend" "k8s-node-002" {
  load_balancer_id = oci_load_balancer.applications-lb.id
  port             = 80
  weight           = 1
  backendset_name  = oci_load_balancer_backend_set.applications-lb.name
  ip_address       = oci_core_instance.kubernetes-node-002-vm.private_ip
}





