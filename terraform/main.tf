#====================================================
# Author: Валерій Мануйлик
#====================================================
# Налаштування мережевої інфраструктури для AWS VPC
# Включає створення VPC, двох публічних підмереж, 
# NAT шлюзів, маршрутів, груп безпеки та EC2 інстансів 
# для тестового Django застосунку з базою даних
# GitHub: https://github.com/BlessedXd
#====================================================


# 🌐 Отримання списку доступних Availability Zones для використання при створенні підмереж.
data "aws_availability_zones" "available" {}

# 🐧 Отримання останнього доступного образу AMI для Ubuntu 20.04
data "aws_ami" "ubuntu" {
  most_recent = true  # Використовуємо останню версію образу
  owners      = ["099720109477"]  # Власник образу

  filter {
    name   = "name"  # Фільтр за назвою образу
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

# 🚀 Створення EC2 інстансів у публічних підмережах.
# Інстанси для застосунку та бази даних.
resource "aws_instance" "app_instance" {
  count         = 2  # Кількість інстансів для застосунку.
  ami           = data.aws_ami.ubuntu.id  # ID AMI, який буде використано для створення інстансу.
  instance_type = var.instance_type  # Тип інстансу (наприклад, t2.micro).
  subnet_id     = aws_subnet.public_subnets[count.index].id  # ID публічної підмережі.
  vpc_security_group_ids = [aws_security_group.dev_sg.id]  # Група безпеки для інстансу.

  tags = {
    Name = "${var.env} - app-instance-${count.index + 1}"  # Тег для ідентифікації інстансу.
  }
}

resource "aws_instance" "db_instance" {
  ami           = data.aws_ami.ubuntu.id  # ID AMI для бази даних.
  instance_type = var.instance_type  # Тип інстансу для бази даних.
  subnet_id     = aws_subnet.private_subnets[0].id  # ID приватної підмережі для БД.
  vpc_security_group_ids = [aws_security_group.dev_sg.id]  # Група безпеки для інстансу.

  tags = {
    Name = "${var.env} - db-instance"  # Тег для ідентифікації інстансу бази даних.
  }
}

# 🔧 Змінна для типу EC2 інстансу.
variable "instance_type" {
  description = "Тип EC2 інстансу"  
  default     = "t2.micro"  # Значення за замовчуванням.
  type        = string  # Тип змінної.
}

# 🏗️ Створення Virtual Private Cloud (VPC).
# Це головна мережа, в межах якої будуть розміщені всі інші ресурси.
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr  # CIDR блок для VPC.

  tags = {
    Name = "${var.env} - vpc"  # Тег для VPC.
  }
}

# 🌍 Створення Internet Gateway (IGW) для VPC.
# Це дозволяє EC2 інстансам у публічних підмережах підключатися до Інтернету.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # ID VPC, до якого буде прив'язано IGW.

  tags = {
    Name = "${var.env} - igw"  # Тег для IGW.
  }
}

# 🏢 Створення публічних підмереж у VPC.
# Кожна підмережа отримає публічну IP-адресу при запуску інстансу.
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)  # Кількість публічних підмереж.
  vpc_id = aws_vpc.main.id  # ID VPC, до якого будуть прив'язані підмережі.
  cidr_block = element(var.public_subnet_cidrs, count.index)  # CIDR блок для підмережі.
  availability_zone = data.aws_availability_zones.available.names[count.index]  # Availability Zone для підмережі.
  map_public_ip_on_launch = true  # Призначення публічної IP-адреси інстансам при запуску.

  tags = {
    Name = "${var.env} - public - ${count.index + 1}"  # Тег для кожної публічної підмережі.
  }
}

# 📡 Створення маршрутної таблиці для публічних підмереж.
# Це дозволяє всім інстансам у публічних підмережах мати доступ до Інтернету через IGW.
resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id  # ID VPC для маршрутної таблиці.

  route {
    cidr_block = "0.0.0.0/0"  # Маршрут для всього Інтернет-трафіку.
    gateway_id = aws_internet_gateway.main.id  # ID IGW для маршрутизації.
  }

  tags = {
    Name = "${var.env} - route-public-subnets"  # Тег для маршрутної таблиці.
  }
}

# 🔗 Асоціація публічних підмереж з маршрутною таблицею.
resource "aws_route_table_association" "public_routes" {
  count = length(aws_subnet.public_subnets[*].id)  # Кількість асоціацій для публічних підмереж.
  route_table_id = aws_route_table.public_subnets.id  # ID маршрутної таблиці.
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)  # ID публічної підмережі.
}

# 📦 Створення Elastic IP для NAT Gateways.
# Кожна NAT шлюз отримує свій Elastic IP.
resource "aws_eip" "nat" {
  count = length(var.private_subnet_cidrs)  # Кількість NAT шлюзів.
  domain = "vpc"  # Призначення EIP для VPC.

  tags = {
    Name = "${var.env} - nat-gw- ${count.index + 1}"  # Тег для кожного EIP.
  }
}

# 🌐 Створення NAT Gateway для кожної приватної підмережі.
# NAT шлюзи забезпечують вихід до Інтернету для інстансів у приватних підмережах.
resource "aws_nat_gateway" "nat" {
  count = length(var.private_subnet_cidrs)  # Кількість NAT шлюзів.
  allocation_id = aws_eip.nat[count.index].id  # ID EIP для NAT шлюзу.
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)  # ID публічної підмережі, де розміщується NAT шлюз.

  tags = {
    Name = "${var.env} - nat-gw - ${count.index + 1}"  # Тег для кожного NAT шлюзу.
  }
}

# 🕵️‍♂️ Створення приватних підмереж у VPC.
# Ці підмережі не мають прямого доступу до Інтернету.
resource "aws_subnet" "private_subnets" {
  count = length(var.private_subnet_cidrs)  # Кількість приватних підмереж.
  vpc_id = aws_vpc.main.id  # ID VPC, до якого будуть прив'язані підмережі.
  cidr_block = element(var.private_subnet_cidrs, count.index)  # CIDR блок для підмережі.
  availability_zone = data.aws_availability_zones.available.names[count.index]  # Availability Zone для підмережі.

  tags = {
    Name = "${var.env} - private - ${count.index + 1}"  # Тег для кожної приватної підмережі.
  }
}

# 📊 Створення маршрутної таблиці для приватних підмереж.
# Це дозволяє приватним підмережам використовувати NAT шлюзи для доступу до Інтернету.
resource "aws_route_table" "private_subnets" {
  count = length(var.private_subnet_cidrs)  # Кількість маршрутних таблиць.
  vpc_id = aws_vpc.main.id  # ID VPC для маршрутної таблиці.
  
  route {
    cidr_block = "0.0.0.0/0"  # Маршрут для всього Інтернет-трафіку.
    nat_gateway_id = aws_nat_gateway.nat[count.index].id  # ID NAT шлюзу для маршрутизації.
  }

  tags = {
    Name = "${var.env} - route-private-subnet- ${count.index + 1}"  # Тег для маршрутної таблиці.
  }
}

# 🔗 Асоціація приватних підмереж з маршрутною таблицею.
resource "aws_route_table_association" "private_routes" {
  count = length(aws_subnet.private_subnets[*].id)  # Кількість асоціацій для приватних підмереж.
  route_table_id = aws_route_table.private_subnets[count.index].id  # ID маршрутної таблиці.
  subnet_id = element(aws_subnet.private_subnets[*].id, count.index)  # ID приватної підмережі.
}

# 🔐 Створення Security Group для інстансів.
# Це забезпечує контроль доступу до інстансів.
resource "aws_security_group" "dev_sg" {
  vpc_id = aws_vpc.main.id  # ID VPC для групи безпеки.

  # Дозволити вхідні з'єднання на порт 80 (HTTP).
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Доступ з будь-якої IP-адреси.
  }

  # Дозволити вхідні з'єднання на порт 22 (SSH) лише з вашої IP-адреси.
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  #  cidr_blocks = [var.my_ip]  # Доступ лише з вашої IP-адреси.
  }

  # Дозволити вихідні з'єднання на всі порти.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Всі протоколи.
    cidr_blocks = ["0.0.0.0/0"]  # Доступ до всіх IP-адрес.
  }

  tags = {
    Name = "${var.env} - security-group"  # Тег для групи безпеки.
  }
}

# 🔄 Створення балансувальника навантаження (Application Load Balancer).
resource "aws_lb" "app_lb" {
  name               = "${var.env}-app-lb"  # Назва балансувальника.
  internal           = false  # Зовнішній балансувальник.
  load_balancer_type = "application"  # Тип балансувальника.
  security_groups    = [aws_security_group.dev_sg.id]  # Група безпеки для балансувальника.
  subnets            = aws_subnet.public_subnets[*].id  # ID публічних підмереж.

  enable_deletion_protection = false  # Вимкнути захист від видалення.

  tags = {
    Name = "${var.env} - app-lb"  # Тег для балансувальника.
  }
}

# 🔧 Створення цільової групи для EC2 інстансів.
resource "aws_lb_target_group" "app_tg" {
  name     = "${var.env}-app-tg"  # Назва цільової групи.
  port     = 80  # Порт, на якому будуть доступні інстанси.
  protocol = "HTTP"  # Протокол для цільової групи.
  vpc_id   = aws_vpc.main.id  # ID VPC для цільової групи.

  health_check {
    path                = "/"  # Шлях для перевірки здоров'я.
    interval            = 30  # Інтервал перевірки (в секундах).
    timeout             = 5  # Тайм-аут (в секундах).
    healthy_threshold   = 2  # Кількість успішних відповідей для здорового статусу.
    unhealthy_threshold = 2  # Кількість невдалих відповідей для нездорового статусу.
  }

  tags = {
    Name = "${var.env} - app-tg"  # Тег для цільової групи.
  }
}

# 🔄 Створення правила для перенаправлення трафіку до цільової групи.
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_lb.arn  # ARN балансувальника.
  port              = 80  # Порт для прослуховування.
  protocol          = "HTTP"  # Протокол для прослуховування.

  default_action {
    type = "forward"  # Дія за замовчуванням — перенаправлення.
    target_group_arn = aws_lb_target_group.app_tg.arn  # ARN цільової групи.
  }
}