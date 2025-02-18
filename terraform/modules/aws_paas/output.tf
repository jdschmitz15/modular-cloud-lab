output "aws_rds_instances" {
    value = { for k, v in aws_db_instance.db_instances : k => v.endpoint }
}