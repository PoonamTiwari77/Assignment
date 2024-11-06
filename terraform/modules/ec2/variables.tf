variable "vpc_id" {
  description = "The ID of the VPC where resources will be deployed"
  type        = string
}

# Subnet ID
variable "private_subnet_ids" {
  description = "The ID of the subnet where the instance will be deployed"
  type        = list(string)
}

# Instance Type
variable "instance_type" {
  description = "Type of EC2 instance to deploy"
  type        = string
  default     = "t2.micro"  # You can adjust this based on your needs
}

# Number of Standby Instances
variable "standby_instance_count" {
  description = "Number of standby (read-only) instances"
  type        = number
  default     = 2
}

variable "postgres_db_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = { 
    db = "postgres"
  }
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {CreatedBy   = "Terraform"}
}

