Tasks:

    Create a vpc with a cidr 10.0.0.0/16

    Create 3 subnets within the VPC in different AZ's , demonstrate basic AWS security principles.

    Elastic load balancer with port 80 and 443 exposed and a public ip address.

    Create a domain in route 53 (any will do, private won't need registration) and get a cert for the domain to apply to the ELB.

    An EC2 instance with nginx installed (automatically), in the private subnet, and only accessible via SSM.

    Mysql instance with configurable DB name, username and password accessible by the vpc only, in the private subnet.

    Output the ELB IP, mysql url, username and password at end of run

    ec2 instance size and root block size aswell as mysql dbname, username, password, instance size and space configurable with a TF vars file or Cloudformation attributes.

    If using Terraform state file, it can be saved to an s3 bucket
