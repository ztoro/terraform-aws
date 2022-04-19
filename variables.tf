variable "AWS_ACCESS_KEY" {}
variable "AWS_SECRET_KEY" {}
variable "MYSQL_DBNAME" {}
variable "MYSQL_USERNAME" {}
variable "MYSQL_PASSWORD" {}
variable "MYSQL_INSTANCE_SIZE" {}
variable "MYSQL_INSTANCE_SPACE" {}
variable "EC2_INSTANCE_SIZE" {}
variable "EC2_INSTANCE_SPACE" {}
variable "AWS_REGION" {
  default = "eu-west-1"
}


variable "number_of_instances" {
  type        = string
  default     = 1
}

data "aws_vpc" "my_test" {
  default = true
}

data "aws_security_group" "default" {
  vpc_id = data.aws_vpc.my_test.id
  name   = "default"
}