# 🌟 Terraform & Ansible Project

## 🚀 Project Overview
This project leverages **Terraform** and **Ansible** to automate the deployment of infrastructure and application setup. We will deploy a sample Django application that requires a PostgreSQL database.

## 🌐 Infrastructure Requirements
- **VPC** with public and private subnets
- **Three EC2 instances**: 
  - Two in the public subnet for the application
  - One in the private subnet for the database
- **Load Balancer** to distribute traffic between application instances
- Terraform should generate an **inventory file** for Ansible

## 🛠️ Ansible Roles
1. **Infrastructure Role**
   - Install PostgreSQL on the database instance
   - Create a user and database
   - Install necessary software and Nginx on application instances to route traffic to the Django application

2. **Deployment Role**
   - Update code from GitHub
   - Refresh configuration files with current database credentials
   - Execute database migrations

## 🌟 Sample Application
We will deploy the following sample Django application:
[Sample Django Application](https://github.com/digitalocean/sample-django)

## 🔧 Getting Started
### Prerequisites
- [Terraform](https://www.terraform.io/downloads.html)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- An AWS account with the necessary permissions

### 🚀 Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/BlessedXd/terraform_ansible_project
2. Navigate to the project directory:
   ```bash 
   cd terraform_ansible_project
3. Initialize Terraform:
   ```bash
   terraform init
4. Apply the Terraform configuration:
   ```bash
   terraform apply
5. Configure Ansible:
   Adjust inventory and configuration files as needed.


### 🎉 Deploy the Application

1. Run the Ansible playbook:
   ```bash
   ansible-playbook -i inventory deploy.yml

### 📜 License

This project is licensed under the MIT License.

### 🤝 Contributing

Contributions are welcome! Please open an issue or submit a pull request.

### 📬 Contact

For questions or feedback, please reach out at valera2004vich@gmail.com

### 🌟 Happy Coding! 🚀


Feel free to customize any part of the README to better fit your style or project specifics!



