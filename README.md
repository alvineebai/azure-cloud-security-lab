# azure-cloud-security-lab

## Overview

This project is a hands-on Azure cloud security lab designed to simulate a small production-style application environment.

The goal was to build a secure, segmented Azure environment using Infrastructure as Code (Terraform), while applying real-world cloud security principles such as:

- Network segmentation
- Zero-trust access principles
- Least-privilege IAM
- Private database connectivity
- Web Application Firewall protection
- Network Security Groups
- Azure Firewall
- Managed Identities
- Azure Key Vault
- Microsoft Defender for Cloud
- Log Analytics
- Secure administrative access through Azure Bastion
- Infrastructure as Code with Terraform

The environment represents a three-tier application:

```text
                         INTERNET
                            |
                            v
                +-----------------------+
                | Azure Application     |
                | Gateway + WAF         |
                +-----------+-----------+
                            |
                            | HTTP/HTTPS
                            v
              +-----------------------------+
              |        SPOKE VNET           |
              |        10.0.0.0/16          |
              |                             |
              |  +-----------------------+  |
              |  | Web Subnet            |  |
              |  | 10.0.1.0/24           |  |
              |  | Web VM + NSG           |  |
              |  +-----------+-----------+  |
              |              |              |
              |  +-----------v-----------+  |
              |  | App Subnet            |  |
              |  | 10.0.2.0/24           |  |
              |  | App VM + NSG          |  |
              |  +-----------+-----------+  |
              |              |              |
              |  +-----------v-----------+  |
              |  | DB Subnet             |  |
              |  | 10.0.3.0/24           |  |
              |  | Private Endpoint      |  |
              |  +-----------+-----------+  |
              +--------------|--------------+
                             |
                             v
                       Azure SQL Database
                       Private Connectivity

              +-----------------------------+
              |          HUB VNET            |
              |          10.10.0.0/16        |
              |                             |
              |  Azure Firewall             |
              |  Azure Bastion              |
              |  VNet Peering               |
              +-----------------------------+

       Identity & Secrets
       ------------------
       Microsoft Entra ID
              |
              v
       Managed Identity
              |
              v
       Azure Key Vault
              |
              v
       Application secrets
```

---

# 1. Project Objectives

The primary objective was to design and deploy an Azure environment where a compromise of one application component does not automatically provide access to the rest of the environment.

The project specifically addresses the following security requirements:

1. Application workloads should not require public IP addresses.
2. Administrative access should occur through Azure Bastion.
3. Internet traffic should enter through a controlled application gateway.
4. Web traffic should be inspected by a Web Application Firewall.
5. Network segments should be isolated using subnets and NSGs.
6. Outbound traffic should be controlled through Azure Firewall.
7. The database should not be directly accessible from the Internet.
8. Database connectivity should use a Private Endpoint.
9. Application secrets should not be stored directly in application configuration.
10. Azure Managed Identity should be used instead of hard-coded credentials.
11. Key Vault access should use Azure RBAC.
12. Security monitoring should be incorporated through Microsoft Defender for Cloud and Log Analytics.
13. Infrastructure should be reproducible using Terraform.

---

# 2. Azure Services Used

| Service | Purpose |
|---|---|
| Azure Resource Group | Logical container for project resources |
| Azure Virtual Network | Network isolation and segmentation |
| Subnets | Separate web, application, database, and gateway workloads |
| Network Security Groups | Layer-4 network access control |
| Azure Application Gateway | Public application entry point |
| Application Gateway WAF | Web application protection |
| Azure Firewall | Centralized network traffic and egress control |
| Azure Bastion | Secure administrative access to private VMs |
| Azure Virtual Machines | Web and application workloads |
| Azure SQL Database | Application database |
| Private Endpoint | Private connectivity to Azure SQL |
| Private DNS Zone | Private name resolution for Azure SQL |
| Managed Identity | Passwordless Azure resource authentication |
| Azure Key Vault | Secure secret storage |
| Azure RBAC | Least-privilege resource access |
| Microsoft Defender for Cloud | Cloud security posture and threat protection |
| Log Analytics Workspace | Centralized security and operational logging |
| Terraform | Infrastructure as Code |

---

# 3. Network Architecture

The environment uses a **hub-and-spoke network architecture**.

## Hub VNet

```text
secure-network-dev-hub-vnet
10.10.0.0/16
```

The hub contains shared security and management services:

- Azure Firewall
- Azure Bastion
- VNet peering

### Hub subnets

| Subnet | Address |
|---|---|
| AzureFirewallSubnet | `10.10.1.0/26` |
| AzureBastionSubnet | `10.10.2.0/26` |

---

## Spoke VNet

```text
secure-network-dev-vnet
10.0.0.0/16
```

The spoke contains the application workloads.

### Spoke subnets

| Subnet | Address | Purpose |
|---|---|---|
| Web | `10.0.1.0/24` | Web workload |
| App | `10.0.2.0/24` | Application workload |
| Database | `10.0.3.0/24` | Private database connectivity |
| Application Gateway | `10.0.4.0/24` | Application Gateway |

The separation of workloads limits lateral movement if an individual workload is compromised.

---

# 4. Internet Traffic Flow

Internet traffic follows this path:

```text
Internet
   |
   v
Application Gateway
   |
   v
Web VM
   |
   v
Application Layer
   |
   v
Private Azure SQL
```

The Application Gateway serves as the controlled public entry point.

The backend VMs do **not** have public IP addresses.

This design reduces the attack surface by preventing direct Internet access to the workloads.

---

# 5. Web Application Firewall

Azure Application Gateway WAF provides protection at the application layer.

The WAF is positioned at the Internet-facing boundary:

```text
Internet
    |
    v
Application Gateway
    |
    +--> WAF inspection
    |
    v
Backend Web VM
```

The WAF helps protect against common web attacks such as:

- SQL injection
- Cross-site scripting
- Malicious HTTP requests
- Common OWASP attack patterns

The WAF is configured as part of the Application Gateway deployment.

---

# 6. Network Security Groups

Network Security Groups provide subnet-level and network-interface-level traffic filtering.

Separate NSGs were created for:

- Web
- Application
- Database

For example, the web tier allows the required HTTPS traffic while administrative SSH access is restricted to the Azure Bastion subnet.

```text
Internet
   |
   v
Application Gateway
   |
   v
Web NSG
   |
   v
Web VM
```

Administrative access:

```text
Administrator
      |
      v
Azure Bastion
      |
      v
Web/App VM
```

This avoids exposing SSH directly to the Internet.

---

# 7. Azure Firewall

Azure Firewall provides centralized network traffic control within the hub network.

Application workloads route outbound traffic through the firewall.

```text
Application VM
      |
      v
Route Table
      |
      v
Azure Firewall
      |
      v
Internet
```

Firewall application rules were configured to allow required Ubuntu package repository traffic so that the VMs could perform operations such as:

```bash
apt update
```

This demonstrates the principle of controlling outbound traffic rather than allowing unrestricted Internet access.

---

# 8. Azure Bastion

Azure Bastion provides secure administrative access to private virtual machines.

The VMs do not require public IP addresses.

Administrative traffic follows:

```text
Administrator
      |
      v
Azure Bastion
      |
      v
Private VM
```

This reduces exposure of management protocols such as SSH.

---

# 9. Azure SQL Security

The database layer was intentionally designed to remain private.

Azure SQL Server:

```text
secure-network-dev-sql-server
```

Database:

```text
secure-network-dev-db
```

The SQL server has public network access disabled.

Connectivity is provided through an Azure Private Endpoint:

```text
Application VM
      |
      v
Private Endpoint
      |
      v
Azure SQL
```

Private DNS is used for name resolution through:

```text
privatelink.database.windows.net
```

The result is that the application can communicate with Azure SQL without requiring the database to be exposed through a public endpoint.

---

# 10. Why Private Endpoints Matter

A major security principle demonstrated by this project is:

> A database should not need to be publicly reachable simply because an application needs to access it.

Without private connectivity:

```text
Internet
   |
   v
Public Database Endpoint
```

With the architecture used in this project:

```text
Application
    |
    v
Private Network
    |
    v
Private Endpoint
    |
    v
Azure SQL
```

This significantly reduces the database's Internet attack surface.

---

# 11. Managed Identity

The application VM uses a **User-Assigned Managed Identity**.

```text
App VM
   |
   v
User-Assigned Managed Identity
   |
   v
Azure Resources
```

This avoids placing Azure credentials directly inside the VM or application code.

Instead of storing something like:

```text
AZURE_CLIENT_SECRET=...
```

the application can authenticate using Azure's identity platform.

This follows the principle:

> Do not manage credentials when Azure can manage the identity for you.

---

# 12. Azure Key Vault

Azure Key Vault was deployed to store application secrets.

Example secret:

```text
app-test-secret
```

The Key Vault uses Azure RBAC rather than traditional Key Vault access policies.

The application identity was granted:

```text
Key Vault Secrets User
```

This provides the application with the ability to retrieve secrets without granting unnecessary administrative permissions.

Architecture:

```text
Application VM
      |
      v
Managed Identity
      |
      v
Azure RBAC
      |
      v
Key Vault
      |
      v
Secret
```

---

# 13. Least Privilege

The project applies least-privilege principles throughout the environment.

Examples include:

- Application identity receives only the required Key Vault role.
- Database is isolated from the public Internet.
- Administrative SSH is restricted to Bastion.
- Web, application, and database workloads use separate network segments.
- NSGs restrict traffic between network layers.
- Azure Firewall controls outbound traffic.
- Secrets are stored in Key Vault rather than source code.

The objective is to reduce the impact of a compromised identity or workload.

---

# 14. Microsoft Defender for Cloud

Microsoft Defender for Cloud was enabled with Defender for Servers Plan 1.

Defender for Cloud provides security capabilities such as:

- Security posture management
- Security recommendations
- Threat detection
- Workload protection
- Security alerts

The project uses Defender as part of the security monitoring layer rather than relying exclusively on network controls.

---

# 15. Log Analytics

A Log Analytics Workspace was created:

```text
secure-network-dev-law
```

Log Analytics provides a centralized location for collecting and analyzing telemetry.

This creates the foundation for additional security operations capabilities such as:

- Microsoft Sentinel
- KQL queries
- Detection rules
- Security investigations
- Alert analysis
- Incident response

---

# 16. Infrastructure as Code

The entire environment is deployed using Terraform.

Terraform provides:

- Repeatable infrastructure
- Version-controlled infrastructure changes
- Consistent environments
- Infrastructure documentation through code
- Easier teardown and recreation
- Reviewable infrastructure changes

Typical workflow:

```text
Terraform Code
      |
      v
terraform init
      |
      v
terraform validate
      |
      v
terraform plan
      |
      v
terraform apply
      |
      v
Azure Infrastructure
```

---

# 17. Terraform Provider

The project uses the AzureRM Terraform provider.

Provider version:

```text
azurerm 5.7.0
```

Terraform version requirement:

```text
>= 1.5.0
```

---

# 18. Repository Structure

The repository contains the Terraform configuration and project documentation.

Example structure:

```text
azure-cloud-security-lab/
│
├── README.md
├── .gitignore
│
├── main.tf
├── providers.tf
├── variables.tf
│
├── network.tf
├── security.tf
├── compute.tf
├── database.tf
├── keyvault.tf
│
└── other Terraform configuration files
```

The exact filenames may vary depending on how the Terraform configuration is organized.

Terraform state files and sensitive local configuration are intentionally excluded from Git.

---

# 19. Git Security

The repository includes a `.gitignore` to prevent sensitive Terraform artifacts from being committed.

Ignored files include:

```text
.terraform/
*.tfstate
*.tfstate.*
*.tfvars
*.tfvars.json
*.pem
*.key
```

This is important because Terraform state can contain sensitive infrastructure information and, depending on configuration, secret values.

Sensitive values should never be committed directly to a public repository.

---

# 20. Deployment

Clone the repository:

```bash
git clone https://github.com/alvineebai/azure-cloud-security-lab.git
cd azure-cloud-security-lab
```

Initialize Terraform:

```bash
terraform init
```

Validate the configuration:

```bash
terraform validate
```

Review the deployment:

```bash
terraform plan
```

Deploy:

```bash
terraform apply
```

When finished with a temporary lab environment:

```bash
terraform destroy
```

> Production environments should use appropriate state management, approvals, CI/CD controls, secret management, and change-management processes rather than blindly running `terraform destroy`.

---

# 21. Validation and Testing

Several security and connectivity checks were performed during deployment.

### Web server

Nginx was installed on the Web VM.

Local validation:

```bash
curl http://127.0.0.1
```

The VM returned the Nginx welcome page.

### Application Gateway

The Application Gateway backend was verified as healthy.

Internet traffic was successfully routed through the Application Gateway to the backend web workload.

### Azure SQL

Connectivity to Azure SQL was tested from the application VM:

```bash
nc -zv secure-network-dev-sql-server.database.windows.net 1433
```

The connection succeeded through the private connectivity architecture.

### VM Public Exposure

The Web and App VMs were deployed without public IP addresses.

Administrative access was performed through Azure Bastion.

### Firewall

Outbound package repository access was validated using:

```bash
apt update
```

This demonstrated that required outbound traffic could pass through the firewall.

---

# 22. Security Design Decisions

## Why no public IP on the VMs?

A public IP increases the attack surface.

Instead:

```text
Internet
   |
   v
Application Gateway/WAF
   |
   v
Private VM
```

---

## Why use Bastion?

SSH should not be directly exposed to the Internet.

Bastion provides a controlled administrative entry point.

---

## Why use a WAF?

NSGs and firewalls primarily control network traffic.

A WAF provides application-layer inspection for HTTP/HTTPS traffic.

---

## Why use Azure Firewall?

NSGs provide distributed network filtering.

Azure Firewall provides centralized network security and outbound traffic control.

They solve different problems and can be used together.

---

## Why use Managed Identity?

Hard-coded credentials create a major security risk.

Managed Identity removes the need to store long-lived Azure credentials on the VM.

---

## Why use Key Vault?

Secrets should not be embedded in:

- Source code
- Terraform files
- VM configuration
- Application configuration files
- Git repositories

Key Vault provides a centralized secure location for secrets.

---

## Why use a Private Endpoint for SQL?

The database should not require public Internet exposure.

Private Endpoint allows the application to communicate with Azure SQL through private networking.

---

# 23. Threat Model

The architecture was designed around several realistic attack scenarios.

### Scenario 1 — Web VM compromise

If an attacker compromises the web VM:

```text
Attacker
   |
   v
Web VM
```

Network segmentation, NSGs, firewall controls, identity permissions, and private database access reduce the attacker's ability to move laterally.

---

### Scenario 2 — Stolen application credentials

The application does not rely on hard-coded Azure credentials.

Managed Identity reduces the risk associated with long-lived service credentials.

---

### Scenario 3 — Database attack

The database is not directly exposed to the Internet.

```text
Internet
   X
   |
   X--> Azure SQL
```

Access is through the private network path.

---

### Scenario 4 — Malicious outbound traffic

The workload's outbound traffic can be routed through Azure Firewall.

This provides a centralized enforcement point for egress control.

---

# 24. Current Security Operations Roadmap

The infrastructure layer establishes the foundation for a broader cloud security operations environment.

Future enhancements include:

- Microsoft Sentinel SIEM
- KQL security queries
- Custom Sentinel analytics rules
- Incident creation and investigation
- Defender endpoint detection
- Vulnerability management
- Automated incident response
- Azure Policy governance
- Conditional Access
- Microsoft Entra security controls
- Device management with Intune
- Security alert simulation
- Incident response playbooks
- Disaster recovery testing

The next major phase is to move from **building secure infrastructure** to **operating and defending it**.

---

# 25. Skills Demonstrated

This project demonstrates practical experience with:

### Cloud

- Microsoft Azure
- Azure networking
- Azure compute
- Azure SQL
- Private networking
- Azure security services

### DevOps

- Terraform
- Infrastructure as Code
- Git
- GitHub
- Repeatable deployments
- Infrastructure version control

### Cloud Security

- Network segmentation
- NSGs
- Azure Firewall
- WAF
- Private Endpoints
- Managed Identity
- Key Vault
- RBAC
- Defender for Cloud
- Security monitoring

### Troubleshooting

The project also involved real Azure troubleshooting, including:

- VM SKU/capacity constraints
- Azure quota limitations
- Terraform provider schema differences
- Key Vault RBAC configuration
- Azure tenant configuration
- Private Endpoint configuration
- Terraform state management
- Azure resource naming restrictions
- Network connectivity testing

These troubleshooting experiences are an important part of real-world cloud engineering.

---
