#Get list of available zones using data sources
data "aws_availability_zones" "available" {
    state = "available"
}  

resource "aws_vpc" "terraform_platform_vpc" {
    cidr_block = var.vpc_cidr
    assign_generated_ipv6_cidr_block = true
    
    tags = var.tags
}

resource "aws_internet_gateway" "terraform_platform_vpc_ig" {
vpc_id = aws_vpc.terraform_platform_vpc.id

tags =merge(var.tags,
{
    Name = format("aws_vpc_IG-%s",var.name) 
})
   
}


resource "aws_route" "IG_route" {
  route_table_id =  aws_vpc.terraform_platform_vpc.default_route_table_id
  gateway_id     =  aws_internet_gateway.terraform_platform_vpc_ig.id
  destination_cidr_block = "0.0.0.0/0" 
}

resource "aws_subnet" "public_subnet" {
    count      = 2
    vpc_id     = aws_vpc.terraform_platform_vpc.id
    cidr_block = cidrsubnet("192.168.0.0/16", 8, count.index+1)
    map_public_ip_on_launch = true
    availability_zone = data.aws_availability_zones.available.names[count.index]
  
    tags = merge (
        var.tags,
        {
            Name = format("publicSubnet-%s", count.index +1)
        }
    )
}

resource "aws_subnet" "private_subnet" {
    count = 2
    vpc_id =  aws_vpc.terraform_platform_vpc.id
     cidr_block = cidrsubnet("192.168.0.0/16", 8, count.index+3)
    map_public_ip_on_launch = false
    availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = merge(
        var.tags,
        {
            Name = format("privateSubnet-%s", count.index+1)
        })

}

resource "aws_eip" "nat_eip" {
    vpc = true
    depends_on = [aws_internet_gateway.terraform_platform_vpc_ig]
    tags = merge(
        var.tags,
        {
            Name = format("nat_eip-%s", var.name)
        }    
)

}

resource "aws_nat_gateway" "nat_gw" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = element(aws_subnet.public_subnet[*].id, 0)
    depends_on = [aws_internet_gateway.terraform_platform_vpc_ig]
     tags = merge(
        var.tags,
        {
            Name = format("nat_gw-%s", var.name)
        }
        
        )
}

resource "aws_route_table" "private-rtb" {
    vpc_id = aws_vpc.terraform_platform_vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id =  aws_nat_gateway.nat_gw.id
    }

    tags = merge(
        var.tags,
        {
            Name = format("private_routetable-%s", var.name)
        }
        
        )
}

resource "aws_route_table_association" "private-rtb-association" {
    count = length(aws_subnet.private_subnet[*].id)
    subnet_id = element(aws_subnet.private_subnet[*].id, count.index)
    route_table_id = aws_route_table.private-rtb.id
}