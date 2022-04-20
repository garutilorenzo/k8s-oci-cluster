variable "compartment_ocid" {

}

variable "tenancy_ocid" {

}

variable "user_ocid" {

}

variable "fingerprint" {

}

variable "private_key_path" {

}

variable "region" {
  default = "<change_me>"
}

module "k8s_cluster" {
  PATH_TO_PUBLIC_KEY     = "<change_me>"
  PATH_TO_PRIVATE_KEY    = "<change_me>"
  PATH_TO_PUBLIC_LB_CERT = "<change_me>"
  PATH_TO_PUBLIC_LB_KEY  = "<change_me>"
  region                 = var.region
  availability_domain    = "<change_me>"
  compartment_ocid       = var.compartment_ocid
  my_public_ip_cidr      = "<change_me>"
  environment            = "staging"
  uuid                   = "<change_me>"
  install_longhorn       = true
  install_nginx_ingress  = true
  source                 = "github.com/garutilorenzo/k8s-oci-cluster"
}

output "k8s_servers_ips" {
  value = module.k8s_cluster.k8s_servers_ips
}

output "k8s_workers_ips" {
  value = module.k8s_cluster.k8s_workers_ips
}

output "public_lb_ip" {
  value = module.k8s_cluster.public_lb_ip
}