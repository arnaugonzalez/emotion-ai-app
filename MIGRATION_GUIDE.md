# AWS Migration Guide for EmotionAI Backend

## Quick Start Migration Steps

### Phase 1: Preparation (1-2 days)
1. **Containerize your FastAPI app**
   ```dockerfile
   FROM python:3.11-slim
   WORKDIR /app
   COPY requirements.txt .
   RUN pip install -r requirements.txt
   COPY . .
   CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
   ```

2. **Set up AWS Account**
   - Create AWS account and configure billing alerts
   - Set up IAM user with appropriate permissions
   - Install AWS CLI and configure credentials

3. **Prepare Database Migration**
   ```python
   # alembic/env.py
   from sqlalchemy import create_engine
   from app.database import Base
   
   # Configure for PostgreSQL
   SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")
   ```

### Phase 2: AWS Infrastructure Setup (1 day)

1. **Create VPC and Networking**
   ```bash
   # Using AWS CLI
   aws ec2 create-vpc --cidr-block 10.0.0.0/16
   aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
   aws ec2 create-subnet --vpc-id <vpc-id> --cidr-block 10.0.2.0/24 --availability-zone us-east-1b
   ```

2. **Set up RDS PostgreSQL**
   - Use AWS Console or Terraform
   - Enable automated backups
   - Configure security groups
   - Enable Multi-AZ for production

3. **Launch EC2 Instances**
   ```bash
   # Create key pair
   aws ec2 create-key-pair --key-name emotion-ai-key --query 'KeyMaterial' --output text > emotion-ai-key.pem
   chmod 400 emotion-ai-key.pem
   
   # Launch EC2 instance
   aws ec2 run-instances \
     --image-id ami-0c94855ba95b798c7 \  # Ubuntu 22.04 LTS
     --instance-type t3.small \
     --key-name emotion-ai-key \
     --security-group-ids sg-xxxxxxxxx \
     --subnet-id subnet-xxxxxxxxx \
     --user-data file://user-data.sh
   ```

4. **Set up Auto Scaling Group**
   - Create Launch Template
   - Configure Auto Scaling Group with 2-4 instances
   - Set up Application Load Balancer
   - Configure health checks

### Phase 3: Configuration (1 day)

1. **EC2 User Data Script** (`user-data.sh`)
   ```bash
   #!/bin/bash
   apt update
   apt install -y python3-pip nginx supervisor awscli
   
   # Install your FastAPI app
   cd /opt
   git clone https://github.com/your-repo/emotion-ai-api.git
   cd emotion-ai-api
   pip3 install -r requirements.txt
   
   # Get secrets from AWS Secrets Manager
   aws secretsmanager get-secret-value --secret-id emotion-ai/database --query SecretString --output text > /opt/secrets.json
   
   # Create systemd service
   cat > /etc/systemd/system/emotion-ai.service << EOF
   [Unit]
   Description=EmotionAI FastAPI
   After=network.target
   
   [Service]
   Type=simple
   User=ubuntu
   WorkingDirectory=/opt/emotion-ai-api
   Environment=DATABASE_URL=$(jq -r .database_url /opt/secrets.json)
   Environment=REDIS_URL=$(jq -r .redis_url /opt/secrets.json)
   Environment=JWT_SECRET=$(jq -r .jwt_secret /opt/secrets.json)
   ExecStart=/usr/local/bin/uvicorn main:app --host 0.0.0.0 --port 8000 --workers 2
   Restart=always
   
   [Install]
   WantedBy=multi-user.target
   EOF
   
   systemctl enable emotion-ai
   systemctl start emotion-ai
   ```

2. **Set up Application Load Balancer**
   - Configure health checks for `/health/`
   - Set up SSL certificate from ACM
   - Configure target groups pointing to EC2 instances
   - Enable sticky sessions if needed

3. **Configure Auto Scaling**
   - CPU-based scaling (scale out at 70% CPU)
   - Target tracking scaling policy
   - Minimum 2 instances, maximum 10 instances

### Phase 4: Testing & Deployment (1-2 days)

1. **Deploy to Staging**
   - Point staging-api.emotionai.app to ALB
   - Test all endpoints
   - Monitor CloudWatch logs

2. **Load Testing**
   ```bash
   # Using k6
   k6 run --vus 100 --duration 30s load-test.js
   ```

3. **Production Deployment**
   - Blue-green deployment recommended
   - Update api.emotionai.app DNS
   - Monitor for 24 hours

## Terraform Configuration (Infrastructure as Code)

```hcl
# main.tf
provider "aws" {
  region = "us-east-1"
}

# VPC Configuration
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name = "emotion-ai-vpc"
  cidr = "10.0.0.0/16"
  
  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]
  
  enable_nat_gateway = true
  enable_vpn_gateway = true
}

# Security Groups
resource "aws_security_group" "alb" {
  name_prefix = "emotion-ai-alb-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ec2" {
  name_prefix = "emotion-ai-ec2-"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]  # Only from VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# RDS Database
resource "aws_db_instance" "postgres" {
  identifier = "emotion-ai-db"
  engine     = "postgres"
  engine_version = "15.3"
  instance_class = "db.t4g.small"
  
  allocated_storage = 20
  storage_encrypted = true
  
  db_name  = "emotionai"
  username = "emotionai"
  password = random_password.db_password.result
  
  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.main.name
  
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  multi_az               = true  # High availability
  
  skip_final_snapshot = false
  final_snapshot_identifier = "emotionai-final-snapshot-${formatdate("YYYY-MM-DD", timestamp())}"
}

# Launch Template for EC2 instances
resource "aws_launch_template" "emotion_ai" {
  name_prefix   = "emotion-ai-"
  image_id      = "ami-0c94855ba95b798c7"  # Ubuntu 22.04 LTS
  instance_type = "t3.small"
  key_name      = aws_key_pair.main.key_name
  
  vpc_security_group_ids = [aws_security_group.ec2.id]
  
  user_data = base64encode(templatefile("user-data.sh", {
    database_url = "postgresql://${aws_db_instance.postgres.username}:${random_password.db_password.result}@${aws_db_instance.postgres.endpoint}:5432/${aws_db_instance.postgres.db_name}"
  }))
  
  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "EmotionAI-Backend"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "emotion_ai" {
  name                = "emotion-ai-asg"
  vpc_zone_identifier = module.vpc.public_subnets
  target_group_arns   = [aws_lb_target_group.emotion_ai.arn]
  health_check_type   = "ELB"
  health_check_grace_period = 300
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 2
  
  launch_template {
    id      = aws_launch_template.emotion_ai.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value              = "EmotionAI-ASG"
    propagate_at_launch = true
  }
}

# Application Load Balancer
resource "aws_lb" "emotion_ai" {
  name               = "emotion-ai-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets           = module.vpc.public_subnets
  
  enable_deletion_protection = false
}

resource "aws_lb_target_group" "emotion_ai" {
  name     = "emotion-ai-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id
  
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval           = 30
    matcher            = "200"
    path               = "/health/"
    port               = "traffic-port"
    protocol           = "HTTP"
    timeout            = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "emotion_ai" {
  load_balancer_arn = aws_lb.emotion_ai.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = aws_acm_certificate.emotion_ai.arn
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.emotion_ai.arn
  }
}
```

## Monitoring & Alerts

1. **CloudWatch Dashboards**
   - API response times
   - Error rates
   - Database connections
   - Memory/CPU usage

2. **Alerts to Configure**
   - High error rate (> 1%)
   - Slow response times (> 1s)
   - Database connection failures
   - High memory usage (> 80%)

## Security Best Practices

1. **Secrets Management**
   - Use AWS Secrets Manager for API keys
   - Rotate database passwords regularly
   - Enable AWS KMS for encryption

2. **Network Security**
   - Keep RDS in private subnets
   - Use security groups restrictively
   - Enable AWS WAF for API protection

3. **Compliance**
   - Enable AWS CloudTrail
   - Configure S3 bucket policies
   - Implement data retention policies

## Post-Migration Checklist

- [ ] All endpoints responding correctly
- [ ] Database migrations completed
- [ ] SSL certificates working
- [ ] Monitoring dashboards active
- [ ] Backup procedures tested
- [ ] Disaster recovery plan documented
- [ ] Cost alerts configured
- [ ] Performance benchmarks met