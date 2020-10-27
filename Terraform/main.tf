resource "aws_security_group" "AirFlow_ServiceConnection_EC2_SG" {
  name        = "AirFlow_ServiceConnection_EC2_SG-${terraform.workspace}"
  description = "AirFlow_ServiceConnection_EC2_SG-${terraform.workspace}"
  vpc_id      = "${var.VPC}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    description = "EC2 Access"
    from_port   = "${var.MHAIP_Port}"
    to_port     = "${var.MHAIP_Port}"
    protocol    = "tcp"
    cidr_blocks = "${var.MHAIP}"
  }

  tags = "${var.TAGS}"
}

resource "aws_security_group" "AirFlow_ServiceConnection_EFS_SG" {
  name        = "AirFlow_ServiceConnection_EFS_SG-${terraform.workspace}"
  description = "AirFlow_ServiceConnection_EFS_SG-${terraform.workspace}"
  vpc_id      = "${var.VPC}"

  ingress {
    description = "EC2 Access"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    security_groups = [aws_security_group.AirFlow_ServiceConnection_EC2_SG.id]
  }

  tags = "${var.TAGS}"
}

resource "aws_security_group" "AirFlow_ServiceConnection_RDS_SG" {
  name        = "AirFlow_ServiceConnection_RDS_SG-${terraform.workspace}"
  description = "AirFlow_ServiceConnection_RDS_SG-${terraform.workspace}"
  vpc_id      = "${var.VPC}"

  ingress {
    description = "EC2 Access"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.AirFlow_ServiceConnection_EC2_SG.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${var.TAGS}"
}

resource "aws_instance" "AirFlow_EC2" {
  ami           = "${var.AMI}"
  instance_type = "${var.INSTANCE_TYPE}"
  security_groups = [aws_security_group.AirFlow_ServiceConnection_EC2_SG.name]
  key_name = "${var.KEY_NAME}"
  tags = "${var.TAGS}"
}

resource "aws_eip_association" "AirFlow_eip" {
  instance_id   = aws_instance.AirFlow_EC2.id
  allocation_id = "${var.EIP_ASSOCIATION}"
}

resource "aws_efs_file_system" "AirFlow_efs" {
  encrypted = true
  tags = "${var.TAGS}"
}

 resource "aws_efs_mount_target" "AirFlow_efs_mount_target" {
   file_system_id = aws_efs_file_system.AirFlow_efs.id
   subnet_id      = "${var.SUBNET}"
   security_groups = [aws_security_group.AirFlow_ServiceConnection_EFS_SG.id]
 }

resource "aws_db_subnet_group" "AirFlow_MySQL_Database_Subnet" {
  name       = "airflow_mysql_database_subnet-${terraform.workspace}"
  subnet_ids = "${var.RDS_SUBNET}"
  tags = "${var.TAGS}"
}

resource "aws_rds_cluster" "AirFlow_MySQL_Database" {
  
  cluster_identifier = "airflow-poc01-${terraform.workspace}"
  availability_zones = [
              "ap-southeast-1a",
              "ap-southeast-1b",
              "ap-southeast-1c"
            ]
   
  engine = "aurora"
  engine_mode = "serverless"
  engine_version = "5.6.10a"
  deletion_protection = "false"
  master_username = "${var.MASTER_USERNAME}"
  master_password = "${var.MASTER_PASSWORD}"
  database_name = "${var.DATABASE_NAME}"

  final_snapshot_identifier = "AirFlow-DB"

  backup_retention_period = "1"

  vpc_security_group_ids = [aws_security_group.AirFlow_ServiceConnection_RDS_SG.id]
  db_subnet_group_name = aws_db_subnet_group.AirFlow_MySQL_Database_Subnet.id

  scaling_configuration {
    auto_pause               = false
    max_capacity             = 2
    min_capacity             = 1
    seconds_until_auto_pause = 300
    timeout_action           = "RollbackCapacityChange"
  }
}


resource "aws_iam_user" "AirFlow_IAM_SQS" {
  name = "AirFlow_IAM_SQS-${terraform.workspace}"

  tags = "${var.TAGS}"
}

resource "aws_iam_access_key" "AirFlow_IAM_SQS" {
  user = aws_iam_user.AirFlow_IAM_SQS.name
}

resource "aws_iam_user_policy" "AirFlow_IAM_SQS" {
  name = "AirFlow_IAM_SQS_Policy-${terraform.workspace}"
  user = aws_iam_user.AirFlow_IAM_SQS.name

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "sqs:ListQueues",
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "sqs:*",
            "Resource": "arn:aws:sqs:${var.AWS_REGION}:${var.AWS_ACCOUNT}:${var.SQS_NAME}"
        }
    ]
}
EOF
}
