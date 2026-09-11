# RDS (Postgres) in private subnets
#
# - RDS Subnet Group uses private subnets from the VPC module.
# - The DB instance is created in the private subnets and attached to the EKS
#   cluster's security group (so pods running on nodes can reach it).
# - All DB properties are parameterized.


# Subnet group (required for RDS in a VPC)
resource "aws_db_subnet_group" "rds_subnets" {
  name       = "${var.project_name}-${var.environment}-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}

#RDS Security group
resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow EKS nodes to access Postgres"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Postgres from EKS nodes"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [module.eks.node_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}


# RDS PostgreSQL instance
resource "aws_db_instance" "postgres" {
  identifier           = "${var.project_name}-${var.environment}-rds"
  engine               = "postgres"
  engine_version       = "16.11"
  instance_class       = var.rds_instance_type
  allocated_storage    = var.rds_allocated_storage
  db_name              = var.rds_dbname
  username             = var.rds_username
  password             = var.rds_password
  port                 = var.rds_port
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.rds_subnets.name

  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Project = var.project_name
    Env     = var.environment
  }
}
