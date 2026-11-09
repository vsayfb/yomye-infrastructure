# Yömye infrastructure

[Türkçe](./README.md) · English

This repository contains the cloud infrastructure for Yömye. Terraform is used to manage two separate environments:

- [AWS staging](./aws-infrastructure/), where changes are tested with real cloud services before release;
- [GCP production](./gcp-infrastructure/), where the live backend runs.

The environments use the same application contracts, but they do not share databases, queues, secrets, deployment files, identities, or Terraform state.

## Architecture

![Yömye application architecture](https://vsay.site/projects/yomye-me/44444b9a-a331-4203-8e9f-b610a8c895e5-yomye-architecture.png)

More details are available on the [Yömye project page](https://vsay.site/projects/yomye-me/).

## Repository layout

```text
.
├── aws-infrastructure/     AWS staging Terraform and operations scripts
│   ├── bootstrap/          Remote-state bucket setup
│   ├── environment/prod/   Staging environment root
│   ├── modules/            AWS network, data, compute, Lambda, and deploy modules
│   └── scripts/            Staging setup and operations tools
└── gcp-infrastructure/     GCP production Terraform and operations scripts
    ├── bootstrap/          Remote-state bucket setup
    └── scripts/            Production setup and database access tools
```

`aws-infrastructure/environment/prod` is the AWS staging Terraform root. Its application environment and GitHub environment are both `staging`.

## Environment comparison

| Area | AWS staging | GCP production |
| --- | --- | --- |
| Public entry | Application Load Balancer | Global HTTPS Load Balancer |
| Core and Chat | One private EC2 VM | One persistent Compute Engine VM |
| Worker | Separate private EC2 VM with Ollama | Separate persistent Compute Engine VM with Ollama |
| PostgreSQL | Amazon RDS | Cloud SQL |
| Events | SQS | Pub/Sub |
| Notification | AWS Lambda | Cloud Run |
| Configuration | Systems Manager Parameter Store | Parameter Manager |
| Secrets | AWS Secrets Manager and secure parameters | Secret Manager and manual parameter versions |
| Deployment storage | Private S3 buckets | Private GCS buckets and Artifact Registry |
| GitHub identity | AWS OIDC deployment role | Workload Identity Federation |

## AWS staging

AWS staging is managed from `aws-infrastructure/environment/prod`.

The main Terraform modules create:

- the VPC, public load-balancer subnets, private application subnet, and NAT instance;
- one Core/Chat EC2 VM and one Worker EC2 VM;
- private RDS PostgreSQL;
- category, chat, and notification SQS queues;
- the Notification Lambda;
- S3 deployment buckets;
- Parameter Store, Secrets Manager access, and workload IAM roles;
- the GitHub Actions OIDC deployment role;
- OpenTelemetry collector configuration for Grafana Cloud.

Common staging operations are provided through scripts:

| Script | Purpose |
| --- | --- |
| `scripts/populate-ssm-credentials.sh` | Requests and stores manually managed staging values |
| `scripts/staging-compute.sh` | Starts, stops, or reports the staging compute and database state |
| `scripts/connect_rds.sh` | Opens local access to private RDS through AWS Systems Manager |
| `scripts/rotate-rds-credentials.sh` | Rotates managed database credentials |
| `scripts/empty-environment-buckets.sh` | Empties deployment buckets before destroy |

## GCP production

GCP production is managed from `gcp-infrastructure`. Its detailed setup, architecture mapping, bootstrap flow, GitHub variables, and scaling notes are documented in the [GCP production guide](./gcp-infrastructure/README.md).

The production root creates:

- a private VPC, subnet, Cloud Router, and Cloud NAT;
- a global HTTPS load balancer and managed certificate;
- one protected Core/Chat VM and one protected Worker VM;
- private Cloud SQL PostgreSQL;
- Pub/Sub topics and subscriptions;
- the Notification Cloud Run service;
- private GCS deployment buckets and Artifact Registry;
- Parameter Manager and Secret Manager resources;
- service accounts and GitHub Workload Identity Federation.

The Core/Chat and Worker VMs are persistent hosts. Deletion protection and Terraform `prevent_destroy` are used so an ordinary infrastructure change cannot silently replace them.

Common production tools include:

| Script | Purpose |
| --- | --- |
| `scripts/populate-parameters.sh` | Requests local input and creates manual Parameter Manager versions |
| `scripts/connect-postgres.sh` | Opens an IAP tunnel from the local machine to Cloud SQL on port `5432` |
| `scripts/get-database-credentials.sh` | Reads the current Cloud SQL connection values from Parameter Manager and Secret Manager |

## Terraform state

AWS staging and GCP production have separate remote-state backends. Each `bootstrap` root creates the storage required by its main Terraform root. The backend is provisioned before the main root is initialized.

## Terraform commands

Example validation commands:

```bash
terraform fmt -recursive
terraform validate
terraform plan -out=environment.tfplan
```

The AWS root defines staging infrastructure, and the GCP root defines production infrastructure. The application deployment workflows deploy binaries or container revisions only. Terraform remains responsible for cloud resources.
