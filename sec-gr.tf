resource "aws_security_group" "alb-sg" {
  name   = "ALBSecurityGroup"
  vpc_id = data.aws_vpc.my_default_vpc.id

  ingress {
    description = "ingress for load balancer http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TF_ALBSecurityGroup"
  }
}

resource "aws_security_group" "server-sg" {
  name   = "WebServerSecurityGroup"
  vpc_id = data.aws_vpc.my_default_vpc.id
  tags = {
    Name = "TF_WebServerSecurityGroup"
  }

  ingress {
    from_port       = 80
    protocol        = "tcp"
    to_port         = 80
    security_groups = [aws_security_group.alb-sg.id]
  }
  ingress {
    description = "ingress for webservers ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}

resource "aws_security_group" "db-sg" {
  name   = "MySQLDBSecurityGroup"
  vpc_id = data.aws_vpc.my_default_vpc.id
  tags = {
    Name = "MySQLDBSecurityGroup"
  }

  ingress {
    from_port       = 3306
    protocol        = "tcp"
    to_port         = 3306
    security_groups = [aws_security_group.server-sg.id]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }
}