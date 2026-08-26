# Yevmiye production on Google Cloud

This directory is an independent Terraform root for the production environment. It does not import or depend on the AWS staging modules in the parent repository, and no Terraform command has been run against a Google Cloud project.

## Architecture

| AWS staging component | Google Cloud production component |
| --- | --- |
| VPC, private subnets, NAT EC2 | Custom VPC, private regional subnet, Cloud Router and Cloud NAT |
| Core and Chat EC2 host | Regional Compute Engine managed instance group, one VM running both services |
| Worker EC2 host | Regional Compute Engine managed instance group, one worker VM with Ollama bootstrap |
| Application Load Balancer | Global external Application Load Balancer with managed TLS |
| RDS PostgreSQL | Regional Cloud SQL for PostgreSQL 16, private IP, HA, PITR and deletion protection |
| SQS queues | Pub/Sub topics and durable subscriptions |
| Notification Lambda | Private Cloud Run v2 service invoked by authenticated Pub/Sub push |
| S3 deployment buckets | Private, versioned GCS deployment buckets retaining the latest two object versions |
| SSM Parameter Store | Parameter Manager with the same parameter suffix IDs |
| RDS managed master-user secret | Secret Manager, referenced by `rds-secret-arn` |
| GitHub AWS OIDC role | Workload Identity Federation and a dedicated deploy service account |

The Core path stays `/core/*`. `/core/health` and `/core/ready` are rewritten to `/health` and `/ready`. The Chat prefix is removed, so `/chat/foo` reaches Chat as `/foo`. HTTP redirects to HTTPS. Both application VMs have no public IP; administrative SSH goes through IAP.

## Before applying

You need an existing, billing-enabled Google Cloud project, Terraform, `gcloud`, and a production DNS name. The identity running Terraform needs permission to enable APIs, create the resources in this directory, and administer project IAM.

Create `terraform.tfvars` from `terraform.tfvars.example` and replace every placeholder. As in the AWS Terraform, the R2 access key values are Terraform-managed inputs and therefore enter Terraform state; keep `terraform.tfvars` uncommitted and restrict access to the state bucket.

The current application binaries use AWS SSM, SQS, and Lambda contracts. Before production traffic is sent here, the service repositories must support these GCP contracts:

- Parameter Manager using Application Default Credentials. Parameter IDs match the existing AWS SSM suffix constants exactly; for example, `/yevmiye/staging/db-host` becomes the GCP parameter `db-host` in the dedicated production project.
- Secret Manager only for the generated PostgreSQL connection JSON. The `rds-secret-arn` parameter contains that GCP Secret Manager resource name, preserving the existing two-step lookup.
- Pub/Sub instead of SQS. The worker pulls `category_worker`; Core publishes category or notification events.
- The notification container accepts the standard wrapped Pub/Sub HTTP push envelope and returns a successful HTTP status only after processing.
- Core and Chat continue to expose `/ready` on ports 8080 and 8081 respectively.

The load balancer will report unhealthy backends until Core and Chat have been deployed to the VM. Terraform creates Cloud Run with Google's public hello image as a harmless bootstrap, ignores later image changes, and initially leaves the notification subscription in pull mode. Deploy the real notification image first, then set `notification_delivery_enabled = true`; this prevents the placeholder from acknowledging and dropping notification events.

## Remote state bootstrap

The state bucket is deliberately a separate root because a backend cannot create the bucket that stores its own state.

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform apply
terraform output -raw backend_bucket
cd ..
cp backend.hcl.example backend.hcl
# Put the output bucket name in backend.hcl.
terraform init -backend-config=backend.hcl
```

The state bucket is private, versioned, protected from Terraform destruction, and its lifecycle retains the live object plus one older version.

## Provision and populate credentials

Review a saved plan before applying:

```bash
cp terraform.tfvars.example terraform.tfvars
terraform fmt -recursive
terraform validate
terraform plan -out=production.tfplan
terraform apply production.tfplan
```

Terraform creates every Parameter Manager container. It adds versions for the same values managed by the AWS Terraform and leaves the parameters represented by AWS `data "aws_ssm_parameter"` lookups empty for manual population. Populate those after the first apply:

```bash
./scripts/populate-parameters.sh YOUR_GCP_PROJECT_ID
```

The script asks for each value with hidden input. Firebase credentials are read from a validated JSON file path. Typed values are passed through stdin and never put on the command line; these manually created versions never enter Terraform state. Parameter Manager uses Google-managed encryption keys by default.

Terraform generates the PostgreSQL password and stores its connection JSON in the only application Secret Manager secret, exposed through the `database_credentials_secret` output. That generated password and the Terraform-managed R2 credentials are necessarily present as sensitive data in Terraform state, so access to the bootstrap bucket must remain tightly restricted.

Parameter Manager and Secret Manager have separate usage-based pricing on GCP. This layout preserves the AWS storage split and the backend's existing parameter names; it does not imply that Parameter Manager is free.

## DNS and TLS

After apply, create A records for every entry in `managed_certificate_domains` pointing to `load_balancer_ip`. Google-managed certificate issuance begins only after DNS resolves to the load balancer and can take time.

## GitHub Actions identity

Set these GitHub production environment variables from Terraform outputs:

- `GCP_WORKLOAD_IDENTITY_PROVIDER` from `github_workload_identity_provider`
- `GCP_DEPLOY_SERVICE_ACCOUNT` from `github_deploy_service_account`
- `GCP_PROJECT_ID` to the project ID
- `GCP_REGION` to the selected region
- `GCS_DEPLOY_BUCKET` from `app_deployments_bucket`

Every deployment job must declare `environment: production` and `permissions: { id-token: write, contents: read }`. The provider rejects tokens from another GitHub owner, another environment, or a repository not listed in `github_repos`.

VM deployments upload binaries to the deployment bucket, connect to the managed VM through IAP, and invoke `/opt/deploy/remote-deploy.sh` with `SERVICE_NAME`, `BINARY_NAME`, `GCS_BUCKET`, and `GCS_OBJECT`. Notification deployments push an image to the output Artifact Registry repository and update the Cloud Run service image.

## Destruction safeguards

Cloud SQL and Cloud Run have deletion protection enabled, the state bucket has `prevent_destroy`, and application buckets refuse deletion while nonempty. These are intentional production safeguards. Set `db_deletion_protection` and `notification_deletion_protection` to `false`, remove the state bucket's `prevent_destroy` only during final decommissioning, and empty all object versions before destroying buckets.
