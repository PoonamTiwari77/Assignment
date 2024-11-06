output "master_instance_id" {
  value = aws_instance.postgres_master.id
}

output "standby_instance_ids" {
  value = aws_instance.postgres_standby[*].id
}
