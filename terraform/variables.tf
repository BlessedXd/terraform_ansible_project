variable "vpc_cidr" {
  description = "CIDR блок для VPC"
  default     = "10.0.0.0/16"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR блоки для публічних підмереж"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR блоки для приватних підмереж"
  default = [ "10.0.11.0/24" ]
  type        = list(string)
}

variable "allow_ports" {
  description = "Порти, які будуть дозволені для доступу"
  default = ["80", "443", "3000"]
  type        = list(number)
}
# Змінна для середовища (наприклад, dev, prod).
# Використовується для іменування ресурсів відповідно до середовища.

variable "env" {
    default = "dev"  # Значення середовища для ресурсу.
}