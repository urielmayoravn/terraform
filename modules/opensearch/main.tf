# resource "aws_iam_service_linked_role" "opensearch" {
#   aws_service_name = "opensearchservice.amazonaws.com"
# }

resource "aws_opensearch_domain" "main" {
  # depends_on     = [aws_iam_service_linked_role.opensearch]
  domain_name    = var.domain_name
  engine_version = var.engine_version

  cluster_config {
    instance_type = var.cluster_config.instance_type
  }


  vpc_options {
    security_group_ids = var.vpc_options.security_group_ids
    subnet_ids         = var.vpc_options.subnet_ids
  }

  ebs_options {
    ebs_enabled = var.ebs_options.ebs_enabled
    volume_size = var.ebs_options.volume_size
    volume_type = var.ebs_options.volume_type
    iops        = var.ebs_options.iops
    throughput  = var.ebs_options.throughput
  }

  access_policies = var.access_policies != null ? var.access_policies : null
}
