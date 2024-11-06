data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.vpc_name
  cidr = var.vpc_cidr
  azs                    = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets        = slice("${cidrsubnets(var.vpc_cidr, 3, 3, 3, 3)}", 1, 4)
  public_subnets         = cidrsubnets(var.vpc_cidr, 6, 6, 6)
 
  enable_nat_gateway      = true
  single_nat_gateway      = false
  map_public_ip_on_launch = true
  one_nat_gateway_per_az  = true

  tags = var.tags
}
