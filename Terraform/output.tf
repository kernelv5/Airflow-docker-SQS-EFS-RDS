output "Instance_Public_IP" {
    value = aws_eip_association.AirFlow_eip.public_ip
}

output "EFS" {
    value = aws_efs_file_system.AirFlow_efs.dns_name
}

output "RDS" {
    value = aws_rds_cluster.AirFlow_MySQL_Database.endpoint
    sensitive   = true
}

output "AccessKey" {
    value = aws_iam_access_key.AirFlow_IAM_SQS.id
    sensitive   = true
}

output "SecretKey" {
    value = aws_iam_access_key.AirFlow_IAM_SQS.secret
    sensitive   = true
}