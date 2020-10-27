## EC2
variable "INSTANCE_TYPE" {}
variable "AMI" {}
variable "KEY_NAME" {}

## Networking / Connection & Firewal 
variable "VPC" {}
variable "SUBNET" {}
variable "RDS_SUBNET" {type=list}
variable "EIP_ASSOCIATION" {}

variable "SQS_NAME" {}
variable "AWS_ACCOUNT" {}
variable "AWS_REGION" {}

variable "MASTER_USERNAME" {}
variable "MASTER_PASSWORD" {}
variable "DATABASE_NAME" {}


## Global
variable "TAGS" {type = map}

variable "MHAIP" {type = list(string)}
variable "MHAIP_Port" {
    default = "22"
}


