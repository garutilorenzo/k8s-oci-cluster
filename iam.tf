resource "oci_identity_dynamic_group" "compute_dynamic_group" {
  compartment_id = var.compartment_ocid
  description    = "Dynamic group which contains all instance in this compartment"
  matching_rule  = "All {instance.compartment.id = '${var.compartment_ocid}'}"
  name           = var.oci_identity_dynamic_group_name

  freeform_tags = local.tags
}

resource "oci_identity_policy" "compute_dynamic_group_policy" {
  compartment_id = var.compartment_ocid
  description    = "Policy to allow dynamic group ${oci_identity_dynamic_group.compute_dynamic_group.name} to read OCI api"
  name           = var.oci_identity_policy_name
  statements = [
    "allow dynamic-group ${oci_identity_dynamic_group.compute_dynamic_group.name} to read instance-family in tenancy",
    "allow dynamic-group ${oci_identity_dynamic_group.compute_dynamic_group.name} to read compute-management-family in tenancy",
    "allow dynamic-group ${oci_identity_dynamic_group.compute_dynamic_group.name} to read buckets in tenancy",
    "allow dynamic-group ${oci_identity_dynamic_group.compute_dynamic_group.name} to manage objects in tenancy where all {target.bucket.name='${oci_objectstorage_bucket.cert_bucket.name}', any {request.permission='OBJECT_CREATE', request.permission='OBJECT_INSPECT', request.permission='OBJECT_OVERWRITE', request.permission='OBJECT_DELETE', request.permission='OBJECT_READ'}}",
  ]

  freeform_tags = local.tags
}