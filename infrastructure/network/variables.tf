variable "region" {
  description = "The AWS region to deploy resources in."
  type        = string
}

variable "prefix" {
  description = "Prefix for naming resources."
  type        = string
}

variable "cidr" {
    description = "The CIDR block for the VPC."
    type        = string
    default     = "10.0.0.0/16"
}

variable "az_count" {
    description = "The number of availability zones to use."
    type        = number
    default     = 2
}
