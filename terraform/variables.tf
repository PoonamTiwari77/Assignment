variable "aws_profile" {
  type        = string
  description = "AWS profile to be used to interact with AWS"
  default    = "aws-profile"
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "The type of EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "num_replicas" {
  description = "Number of read replicas"
  type        = number
  default     = 1
}

variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "superads-vpc"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {CreatedBy   = "Terraform"}
}
