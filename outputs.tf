output "elb_dns_name" {
  value = module.elb.elb_dns_name
}

output "mysql_url" {
  value = module.db.db_instance_address
}

output "mysql_username" {
  value = module.db.db_instance_username
  sensitive = true
}

output "mysql_password" {
  value = module.db.db_instance_password
  sensitive = true
}