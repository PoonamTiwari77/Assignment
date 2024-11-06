module "vpc" {
  source = "./modules/vpc"
  vpc_name = var.vpc_name
  vpc_cidr = var.vpc_cidr
  tags = var.tags
}

module "postgres-db-instance" {
  source = "./modules/ec2"
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnets
  instance_type = var.instance_type
  standby_instance_count = var.num_replicas
  tags = var.tags
}
