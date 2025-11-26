output "vpc_vpc_id" {
  value = module.vpc.vpc_id
}

output "vpc_public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "vpc_private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "vpc_private_db_subnet_ids" {
  value = module.vpc.private_db_subnet_ids
}
