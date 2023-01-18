# private subnet group in which the rds will be located 
resource "aws_db_subnet_group" "subnet_group" {
  name       = var.name-subnet-group
  subnet_ids = var.SUBNETS
}
# db security group it will contains inbounded and outbounded rules for the database
resource "aws_security_group" "securitygroup" {
  name   = var.sg-name
  vpc_id = var.VPC_ID

  ingress {
    description = "Allow from Personal CIDR block"
    from_port   = var.PORT
    to_port     = var.PORT
    protocol    = "tcp"
    cidr_blocks = var.INGRESS_CIDR_BLOCKS
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "database aurora sg"
  }
}
resource "aws_kms_key" "kms" {
  description = "Encryption key for aurora"
}
resource "aws_rds_cluster" "aurora-cluster" {
  cluster_identifier = "aurora-cluster-demo"
  engine             = "aurora-postgresql"

  availability_zones      = var.availability_zones
  database_name           = "mydb"
  master_username         = var.db-username
  master_password         = var.db-password
  backup_retention_period = 5
  skip_final_snapshot     = true

  preferred_backup_window = "07:00-09:00"
  storage_encrypted       = true
  kms_key_id              = aws_kms_key.kms.arn
  vpc_security_group_ids  = [aws_security_group.securitygroup.id]
  db_subnet_group_name    = aws_db_subnet_group.subnet_group.name
}
resource "aws_rds_cluster_instance" "writer-cluster_instance" {

  identifier         = "aurora-cluster-demo-master"
  cluster_identifier = aws_rds_cluster.aurora-cluster.id
  instance_class     = var.db-instance-class

  engine = aws_rds_cluster.aurora-cluster.engine

  publicly_accessible = false

}

resource "aws_rds_cluster_instance" "reader-cluster_instance" {

  identifier         = "aurora-cluster-demo-reader"
  cluster_identifier = aws_rds_cluster.aurora-cluster.id
  instance_class     = var.db-instance-class

  engine = aws_rds_cluster.aurora-cluster.engine

  publicly_accessible = false

}
#create scaling target for aurora cluster
resource "aws_appautoscaling_target" "aurora-sacling" {
  service_namespace  = "rds"
  resource_id        = "cluster:${aws_rds_cluster.aurora-cluster.id}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  min_capacity       = 2
  max_capacity       = 4


}
# scale based on cpu
resource "aws_appautoscaling_policy" "scale-cpu" {
  name               = "aurora-autoscale-policy"
  service_namespace  = "rds"
  resource_id        = "cluster:${aws_rds_cluster.aurora-cluster.id}"
  scalable_dimension = "rds:cluster:ReadReplicaCount"
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value       = 75
    scale_out_cooldown = 300
    scale_in_cooldown  = 300

    predefined_metric_specification {
      predefined_metric_type = "RDSReaderAverageCPUUtilization"

    }
  }


}
#custopn endpoint for analytics teams need only reader instances
resource "aws_rds_cluster_endpoint" "dev" {
  cluster_identifier          = aws_rds_cluster.aurora-cluster.id
  cluster_endpoint_identifier = "reader"
  custom_endpoint_type        = "READER"

  excluded_members = [
    aws_rds_cluster_instance.reader-cluster_instance.id,

  ]
}
resource "aws_iam_role" "backup-role" {
  name               = "backup-role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "attach" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup-role.name
}
#specify resources to be included in the backup plan
resource "aws_backup_selection" "aurora-selection" {
  plan_id      = aws_backup_plan.daily-backup.id
  name         = "aurora-backup"
  iam_role_arn = aws_iam_role.backup-role.arn
  resources    = ["${aws_rds_cluster.aurora-cluster.arn}"]
}
# container for storing backups
resource "aws_backup_vault" "daily-backup-vault" {
  name        = "daily_backup_vault"
  kms_key_arn = aws_kms_key.kms.arn
}
#backup plan
resource "aws_backup_plan" "daily-backup" {
  name = "backup-plan"
  rule {
    rule_name         = "rule-aurora"
    target_vault_name = aws_backup_vault.daily-backup-vault.name
    schedule          = "cron(0 23 * * ? *)"
    lifecycle {
      delete_after = "30"
    }
  }
}

