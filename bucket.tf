data "oci_objectstorage_namespace" "oci_bucket_namespace" {
  compartment_id = var.compartment_ocid
}

resource "oci_objectstorage_bucket" "cert_bucket" {
  compartment_id = var.compartment_ocid
  name           = var.oci_bucket_name
  namespace      = data.oci_objectstorage_namespace.oci_bucket_namespace.namespace

  access_type   = "NoPublicAccess"
  freeform_tags = local.tags
}