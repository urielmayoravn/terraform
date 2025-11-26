resource "aws_security_group" "sg" {
  name        = var.name
  description = var.desc
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ingress_rules" {
  for_each                     = { for index, value in var.ingress_rules : index => value }
  security_group_id            = aws_security_group.sg.id
  ip_protocol                  = each.value.ip_protocol
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "egress_rules" {
  for_each          = { for index, value in var.egress_rules : index => value }
  security_group_id = aws_security_group.sg.id
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4
}
