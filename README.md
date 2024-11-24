# PostgreSQL Primary-Replica Automation API with Terraform and Ansible 🚀
This repository automates the setup and management of PostgreSQL clusters (Master + Read Replicas) on AWS using Terraform and Ansible. The solution ensures flexibility, security, modularity, and idempotency, making it easily extendable and maintainable.

## Table of Contents
* Overview
* Architecture
* Security Considerations
* Best Practices
* How to Use
* Configuration
* Error Handling & Edge Cases
* Future Use Cases
* Assumptions

# Overview
We deployed a highly available PostgreSQL database setup on AWS, consisting of:

* A Master node for handling writes.
* Multiple Read Replicas for high availability and load balancing of read operations.

Terraform is used to provision the infrastructure (EC2 instances, Security Groups, IAM roles, etc.), while Ansible handles configuration management (installation, configuration of PostgreSQL, and replication setup).


# Architecture

**EC2 Instances**: The solution provisions EC2 instances for the Master node and Read Replicas in private subnets, ensuring that the database instances are not exposed to the public internet.

**VPC**: A custom VPC setup is created with private subnets for enhanced security.

**IAM Roles**: Roles are created for EC2 instances to interact with AWS Systems Manager (SSM) and manage PostgreSQL configurations securely.

**Ansible**: Ansible is used to configure PostgreSQL on the EC2 instances, ensuring that configuration is idempotent and that any changes to the setup can be made without disrupting the database.

# Security Considerations

**IAM Policies:** Specific IAM roles are used with the least privilege principle, ensuring that EC2 instances only have the permissions required for their tasks.

**SSM and Bastion Hosts:** Communication with EC2 instances is secured through AWS Systems Manager (SSM), eliminating the need for SSH access. Alternatively, a Bastion host can be used to securely manage EC2 instances.

**VPC and Private Subnets:** PostgreSQL instances are deployed in private subnets to avoid direct exposure to the internet.
Secrets Management: AWS Secrets Manager is used to securely manage database credentials for replicas.

# Best Practices
### Code Modularity
**Modular Terraform Configurations:** The Terraform configurations are divided into multiple modules for resources like EC2 instances, IAM roles, VPC, and security groups. This makes it easy to extend and manage.

**Ansible Roles:** The Ansible configuration is split into different roles (install, configure_master, configure_replica, common_config) to separate concerns, making it reusable for different environments or changes.

**Idempotency**
* **Terraform**: Terraform configurations ensure that infrastructure is provisioned in an idempotent manner. Re-running terraform apply will only make changes if necessary, and no existing resources will be destroyed unless explicitly defined.
Ansible: Ansible tasks use the lineinfile and other idempotent modules to ensure that configuration changes only occur when necessary. Tasks like setting PostgreSQL parameters (listen_addresses, max_connections, etc.) ensure the configuration is only modified if the desired state differs.


# How to Use
### Clone the Repository

```
$ git clone https://github.com/yourusername/Assignment.git
$ cd Assignment
```
### Configure AWS Profile:
Run aws configure --profile aws-profile and provide your AWS credentials.

### Create Virtual Environment:
```
python3 -m venv venv
```

### Activate Virtual Environment:
```
Linux/Mac: source venv/bin/activate
Windows: venv\Scripts\activate
```

### Install Dependencies:
```
pip install -r requirements.txt boto3
```
### Create requirement.txt file

```
fastapi==0.68.0
uvicorn==0.15.0
```
## Running the API
### 1. Start the FastAPI Application
* Run your FastAPI app using Uvicorn:

```
uvicorn main:app --reload
```

### 2. API Endpoints
You can run the API using tools like curl or Postman. Run the API in Assignment folder.

### a. Set Up S3 Backend for Terraform
* You can setup bucket name unique in the code to avoid the error.
```
curl -X POST http://127.0.0.1:8000/terraform/setup-s3-backend/
```

### b. Initialize Terraform

```
curl -X POST http://127.0.0.1:8000/terraform/init/
```

### c. Plan Terraform Configuration
Pass parameters like instance type and number of replicas:
```
curl -X POST http://127.0.0.1:8000/terraform/plan/ \
-H "Content-Type: application/json" \
-d '{"instance_type": "t2.micro", "num_replicas": 2}'
```
### d. Apply Terraform Configuration

```
curl -X POST http://127.0.0.1:8000/terraform/apply/
```

### e. Setup Postgresql primary-replica using ansible configuration

```
curl -X POST http://127.0.0.1:8000/setup-config/ \
-H "Content-Type: application/json" \
-d '{
    "postgres_version": "14",
    "max_connections": 200,
    "shared_buffers": "256MB"
}'
```

# Setup Terraform Resources

* Provisioned one EC2 instance as the PostgreSQL **master node** and additional **read replicas** based on the replica count from the API. The setup includes a custom VPC with private subnets for security, isolating the instances from the internet. Security groups allow only internal communication for database replication and restricted access. This design ensures security and scalability, using Terraform's dynamic resources and input variables for flexibility.

* For the **multi-AZ deployment**, we use a dynamic subnet_id assignment to distribute replicas across available private subnets. The logic ensures replicas are placed in different availability zones or reuses subnets if there are fewer subnets than replicas.
    ```
    subnet_id = (count.index < length(var.private_subnet_ids) && var.standby_instance_count < length(var.private_subnet_ids)) ?  var.private_subnet_ids[count.index + 1] : var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
    ```
* We also created an SSM role and attached the necessary S3 bucket permissions to allow EC2 instances to interact with **AWS Systems Manager (SSM)** and use the S3 bucket for file storage, which is essential for Ansible automation.

# Setup Ansible configurations

* Install Ansible and AWS dependencies:

```
pip install ansible boto3 botocore
```

* Install the AWS collection:

```
ansible-galaxy collection install amazon.aws
```

## Why Use AWS SSM for PostgreSQL Setup
To securely connect to PostgreSQL on EC2 instances in private subnets, SSM offers a modern, secure alternative to traditional methods like bastion hosts:

### Bastion Host Approach:

* Provision 1 master + 2 replicas, set up a bastion host with Ansible, and install PostgreSQL.
* While secure, it adds complexity and operational overhead.
SSM Approach:

### Configure PostgreSQL directly via Ansible on private instances without SSH.

* Added SSM roles and S3 permissions for secure session management and file handling.
* **Implemented dynamic inventory with tag filters and key groups, and used Secrets Manager for replica credentials.**
* Benefits: Enhanced security, no direct SSH, simplified automation, and centralized secret storage.

## Directory Structure

```
ansible/
├── handlers/
│   └── main.yml
├── inventory/
│   └── dynamic_inventory_hosts_aws_ec2.yaml
├── playbooks/
│   └── playbook.yml
├── roles/
│   └── postgres/
│       ├── tasks/
│       │   ├── common_config.yml
│       │   ├── configure_master.yml
│       │   ├── configure_replica.yml
│       │   ├── install.yml
│       │   └── main.yml
│       ├── templates/
│       │   ├── postgresql.conf.j2
│       │   └── pg_hba.conf.j2
│       └── vars/
│           └── main.yml
├── ansible.cfg
└── README.md

```

### 1. inventory/dynamic_inventory_hosts_aws_ec2.yaml
* Configures dynamic inventory to retrieve EC2 instances from AWS using specific tags. It allows Ansible to target PostgreSQL master and replica nodes dynamically.
### 2. handlers/main.yml
* Contains handlers for restarting services (e.g., PostgreSQL) when certain changes occur, ensuring that updates like configuration changes are applied.
### 3. playbooks/playbook.yml
* The main playbook that runs the necessary roles and tasks to set up PostgreSQL on the master and replica nodes. It integrates roles, variables, and task files.
### 4. roles/postgres/tasks/common_config.yml
* Configures common PostgreSQL settings (e.g., max_connections, shared_buffers) for both the master and replica instances.
### 5. roles/postgres/tasks/configure_master.yml
* Defines tasks for setting up the PostgreSQL master node, including replication configurations in postgresql.conf and pg_hba.conf.
### 6. roles/postgres/tasks/configure_replica.yml
* Defines tasks for setting up the read-replica nodes, including replication user creation and syncing with the master node.
### 7. roles/postgres/tasks/install.yml
* Installs the specified PostgreSQL version on the target instances, ensuring that the correct version is used for both master and replica nodes.
### 8. roles/postgres/main.yml
* The entry point for the PostgreSQL role. This file includes other task files (e.g., common_config.yml, configure_master.yml, configure_replica.yml) and applies configurations and installations.
```
# roles/postgres/tasks/main.yml
---
- include_tasks: install.yml
- include_tasks: common_config.yml
- include_tasks: configure_master.yml 
- include_tasks: configure_replica.yml
```

### 9. vars/main.yml
* Holds all the configuration variables (e.g., postgres_version, max_connections, shared_buffers) used in the tasks and templates.

### 10. ansible.cfg
* The Ansible configuration file that defines global settings, including inventory file location, logging, and other options to configure Ansible's behavior.

# Error Handling

**Terraform:** Error handling is ensured by defining proper resource dependencies, using depends_on when necessary, and using error-catching mechanisms like try/catch in configurations.

**Ansible:** Ansible tasks are written to handle failures gracefully. Tasks include checks to ensure the state is correct before making changes, and ignore_errors: yes is used only where necessary for retryable or recoverable issues.

# Future Use Cases
**Multi-Region Setup:** The architecture can be extended to deploy PostgreSQL clusters across multiple AWS regions for disaster recovery and failover.

**Automated Backups:** Future additions can include automated backups using AWS services such as RDS or custom S3 backup scripts.

**Scaling:** The setup can be adapted to use containerized PostgreSQL clusters managed by Kubernetes for horizontal scaling.

# Assumptions
* The solution assumes that the user has basic knowledge of Terraform and Ansible.

* We designed for PostgreSQL, but it can be extended for other database systems with minimal changes.


Please let me know if any changes require.
