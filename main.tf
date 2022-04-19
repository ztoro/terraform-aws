provider "aws" {
  region = var.AWS_REGION
  access_key = var.AWS_ACCESS_KEY
  secret_key = var.AWS_SECRET_KEY
}

locals {
  region = "eu-west-1"
  tags = {
    Owner       = "user"
    Environment = "test"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.0"

  name = "vpc"
  cidr = "10.0.0.0/16"

  azs             = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = local.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id = module.vpc.vpc_id
}

module "mysql_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "mysql"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      description = "MySQL access from within VPC"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

module "nginx_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "nginx"
  vpc_id      = module.vpc.vpc_id

  #all outbound
  egress_with_cidr_blocks = [
    {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = module.vpc.vpc_cidr_block
    }
  ]

  tags = local.tags
}

module "elb_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name        = "mysql"
  vpc_id      = module.vpc.vpc_id

  # ingress
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "http"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "https"
      cidr_blocks = module.vpc.vpc_cidr_block
    },
  ]

  tags = local.tags
}

resource "aws_route53_zone" "this" {
  name          = "zoli-awstest.com"
  force_destroy = true
}

module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 3.0"

  zone_id = aws_route53_zone.this.zone_id

  domain_name               = "zoli-awstest.com"
  subject_alternative_names = ["*.zoli-awstest.com"]

  wait_for_validation = true
}


module "elb" {
  source  = "terraform-aws-modules/elb/aws"
  version = "3.0.1"

  name = "elb"

  subnets         = module.vpc.public_subnets
  security_groups = [module.elb_security_group.security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "http"
      lb_port           = "80"
      lb_protocol       = "http"
    },
    {
      instance_port     = "443"
      instance_protocol = "https"
      lb_port           = "443"
      lb_protocol       = "https"

      ssl_certificate_id = module.acm.acm_certificate_arn
    },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  tags = local.tags

  # ELB attachments
  number_of_instances = var.number_of_instances
  instances           = module.ec2_instances.id
}


module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 2.0"

  instance_count = var.number_of_instances

  name                        = "EC2 NGINX"
  ami                         = "ami-ebd02392"
  instance_type               = var.EC2_INSTANCE_SIZE
  vpc_security_group_ids      = [data.aws_security_group.default.id]
  subnet_id                   = element(tolist(module.vpc.public_subnets), 0)
  associate_public_ip_address = true
}


module "db" {
  source  = "terraform-aws-modules/rds/aws"
  version = "4.2.0"

  identifier = "mysql"

  # All available versions: http://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_MySQL.html#MySQL.Concepts.VersionMgmt
  engine               = "mysql"
  engine_version       = "8.0.27"
  family               = "mysql8.0" # DB parameter group
  major_engine_version = "8.0"      # DB option group
  instance_class       = var.MYSQL_INSTANCE_SIZE

  allocated_storage     = var.MYSQL_INSTANCE_SPACE
  max_allocated_storage = 100

  db_name  = var.MYSQL_DBNAME
  username = var.MYSQL_USERNAME
  password = var.MYSQL_PASSWORD
  port     = 3306

  multi_az               = true
  subnet_ids             = module.vpc.private_subnets
  vpc_security_group_ids = [module.mysql_security_group.security_group_id]

  maintenance_window              = "Mon:00:00-Mon:03:00"
  backup_window                   = "03:00-06:00"
  enabled_cloudwatch_logs_exports = ["general"]
  create_cloudwatch_log_group     = true

  backup_retention_period = 0
  skip_final_snapshot     = true
  deletion_protection     = false

  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  create_monitoring_role                = true
  monitoring_interval                   = 60

  parameters = [
    {
      name  = "character_set_client"
      value = "utf8mb4"
    },
    {
      name  = "character_set_server"
      value = "utf8mb4"
    }
  ]

  tags = local.tags
  db_instance_tags = {
    "Sensitive" = "high"
  }
  db_option_group_tags = {
    "Sensitive" = "low"
  }
  db_parameter_group_tags = {
    "Sensitive" = "low"
  }
  db_subnet_group_tags = {
    "Sensitive" = "high"
  }
}
