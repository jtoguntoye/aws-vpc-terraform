output "vpc_security_id" {
  value = aws_vpc.terraform_platform_vpc.default_security_group_id
}

output "vpc_id" {
  value = aws_vpc.terraform_platform_vpc.id
}

output "availability_zones" {
    value = data.aws_availability_zones.available.names
}

