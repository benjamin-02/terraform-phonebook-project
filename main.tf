data "aws_vpc" "my_default_vpc" {
  default = true
}

data "aws_subnets" "my_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.my_default_vpc.id]
  }
}

data "aws_ami" "amazonlinux2-ami" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

resource "aws_launch_template" "asg-launch-template" {
  name                   = "phonebook-lt"
  image_id               = data.aws_ami.amazonlinux2-ami.id
  instance_type          = "t2.micro"
  key_name               = "keyone"
  vpc_security_group_ids = [aws_security_group.server-sg.id]
  user_data              = filebase64("user-data.sh")
  depends_on             = [github_repository_file.dbendpointfile]
  tag_specifications {
    resource_type = "instance"
    tags = {
      name = "Web Server of Phonebook App"
    }
  }
}

resource "aws_alb_target_group" "app-lb-tg" {
  name        = "phonebook-lb-tg"
  protocol    = "HTTP"
  port        = 80
  vpc_id      = data.aws_vpc.my_default_vpc.id
  target_type = "instance"
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

resource "aws_alb" "app-lb" {
  name               = "phonebook-applicationlb"
  ip_address_type    = "ipv4"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb-sg.id]
  # either  subnets  = data.aws_subnets.my_subnets.ids      OR
  subnets = [for subnetid in data.aws_subnets.my_subnets.ids : subnetid]
}

resource "aws_alb_listener" "alb-listener" {
  load_balancer_arn = aws_alb.app-lb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.app-lb-tg.arn
  }
}

resource "aws_autoscaling_group" "app-asg" {
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 2
  name                      = "phonebook-asg"
  health_check_grace_period = 300
  health_check_type         = "ELB"
  target_group_arns         = [aws_alb_target_group.app-lb-tg.arn]
  vpc_zone_identifier       = aws_alb.app-lb.subnets # data.aws_subnets.my_subnets.id were also possible
  launch_template {
    id      = aws_launch_template.asg-launch-template.id
    version = aws_launch_template.asg-launch-template.latest_version
  }
}

resource "aws_db_instance" "db-server" {
  instance_class              = "db.t2.micro"
  allocated_storage           = 20
  vpc_security_group_ids      = [aws_security_group.db-sg.id]
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  backup_retention_period     = 0
  identifier                  = "phonebook-app-db" # name of instance
  db_name                     = "phonebook"        # name of db ("name" is deprecated. use "db_name")
  engine                      = "mysql"
  engine_version              = "8.0.23"
  username                    = "admin"
  password                    = "Franklin_123"
  monitoring_interval         = 0 # 0 means disabled. so, dont monitor
  multi_az                    = false
  port                        = 3306
  publicly_accessible         = false
  skip_final_snapshot         = true # takes snapshot before terminating. not necessary in this project
}

resource "github_repository_file" "dbendpointfile" {
  content             = aws_db_instance.db-server.address # db-server.endpoint comes with :3306. we dont want this. thats why we use .address
  file                = "dbserver.endpointfile"
  repository          = "python-phonebook-app"
  overwrite_on_create = true
  branch              = "main"
}
