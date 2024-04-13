#output "public_subnet_ids" {
# value = aws_subnet.public_subnet[*].id
#}


output "vpc_id" {
value = aws_vpc.main.id
}


output "public_subnet_ids" {
  value = aws_subnet.public_subnet[*].id
}

output "private_subnets_ids" {
  value = aws_subnet.private_subnet[*].id
}


output "private_route_table_ids" {
  value = aws_route_table.private_subnets.id
}
