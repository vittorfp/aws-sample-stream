module "es" {
	source  = "git::https://github.com/terraform-community-modules/tf_aws_elasticsearch.git?ref=v1.1.0"

	domain_name                    = "elasticsearch-trips"
	management_public_ip_addresses = ["179.198.8.97"]
	instance_count                 = 1
	instance_type                  = "m4.2xlarge.elasticsearch"
	es_zone_awareness              = false
	ebs_volume_size                = 10
}