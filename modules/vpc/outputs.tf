output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = [for psn in aws_subnet.public : psn.id]
}

output "private_subnet_ids" {
  value = [for ppsn in aws_subnet.private : ppsn.id]
}

output "private_db_subnet_ids" {
  value = [for pdbsn in aws_subnet.private_db : pdbsn.id]
}
