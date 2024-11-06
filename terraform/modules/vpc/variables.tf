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
