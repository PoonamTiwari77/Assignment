locals {
  private_keys_folder          = "postgres-key"
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["099720109477"]  # Canonical's AWS account ID for official Ubuntu images

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "postgres_sg" {
  vpc_id = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "postgres-sg"
  }
}

# Master (Primary) Instance
resource "aws_instance" "postgres_master" {
  ami             = data.aws_ami.ubuntu_ami.id
  instance_type   = var.instance_type
  subnet_id       = element(var.private_subnet_ids, 0)  # Deploy in the first AZ
  security_groups = [aws_security_group.postgres_sg.id]
  key_name = aws_key_pair.postgres_db.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name

  tags = merge(
    var.tags,
    var.postgres_db_tags,
    { Name = "Postgres-Master"})
}

# Standby (Read-Only) Instances
resource "aws_instance" "postgres_standby" {
  count           = var.standby_instance_count
  ami             = data.aws_ami.ubuntu_ami.id
  instance_type   = var.instance_type
  subnet_id = (count.index < length(var.private_subnet_ids) && var.standby_instance_count < length(var.private_subnet_ids)) ? var.private_subnet_ids[count.index + 1] : var.private_subnet_ids[count.index % length(var.private_subnet_ids)] # Deploy in different AZs
  security_groups = [aws_security_group.postgres_sg.id]
  key_name = aws_key_pair.postgres_db.key_name
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_instance_profile.name

  tags = merge(
    var.tags,
    var.postgres_db_tags,
    { Name = "Postgres-Standby"})
}

# RSA key of size 4096 bits
resource "tls_private_key" "postgres_db_private_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "postgres_db" {
  key_name   = "postgres-db-key"
  public_key = tls_private_key.postgres_db_private_key.public_key_openssh
}

# Placing private key in s3 bucket
data "aws_s3_bucket" "bucket" {
  bucket = "my-terraform-state-files-bucket"
}

resource "aws_s3_object" "ssh_key" {
  key     = "${local.private_keys_folder}/${aws_key_pair.postgres_db.key_name}"
  bucket  = data.aws_s3_bucket.bucket.id
  content = tls_private_key.postgres_db_private_key.private_key_pem
  acl     = "private"
}
