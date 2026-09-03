# Yevmiye on Google Cloud — AWS-parity baseline

This Terraform root deploys Yevmiye's production environment on Google Cloud. Its initial sizing mirrors the current AWS staging footprint as closely as practical, while using GCP-native services where preferable. No Terraform command has been run against a Google Cloud project by this package.

## Architecture mapping

| Current AWS component | Google Cloud equivalent in this root |
| --- | --- |
| VPC + private application subnets | Custom VPC + private regional subnet |
| `t3.micro` self-managed NAT instance | Cloud Router + managed Cloud NAT |
| Core + Chat `t3.small`, 8 GB gp3 | One `e2-small`, 10 GB balanced PD |
| Worker `t3.small`, 8 GB gp3 | One `e2-small`, 10 GB balanced PD |
| Both application hosts in one compute AZ | Both application hosts in one GCP zone |
| HTTP Application Load Balancer | Global external HTTP Application Load Balancer |
| RDS PostgreSQL 16 `db.t4g.micro`, Single-AZ | Cloud SQL PostgreSQL 16 `db-g1-small`, zonal |
| RDS 20 GB gp3 | Cloud SQL 20 GB SSD |
| 1-day automated backup retention | One retained backup + one day of PITR logs |
| SQS queues | Pub/Sub topics and durable subscriptions |
| 256 MB / 60 second notification Lambda | Scale-to-zero Cloud Run notification service, 512 MiB / 60 seconds |
| S3 deployment buckets | Private, versioned GCS deployment buckets retaining two object versions |
| SSM Parameter Store | Parameter Manager with matching parameter suffix IDs |
| RDS managed master-user secret | Secret Manager connection JSON referenced by `rds-secret-arn` |
| GitHub AWS OIDC role | Workload Identity Federation + deploy service account |

Cloud Run remains at 512 MiB because that is the practical/default second-generation service memory floor for this networking model; it still scales to zero, so there is no fixed idle instance cost.

The GCP project is treated as the environment boundary. Resource names therefore use the same `yevmiye-*` style as AWS rather than repeating `production` in every resource name. The `environment` label and application environment are fixed to `production`, which activates the services' GCP configuration loaders.

## Deliberate differences from AWS

Cloud NAT is retained instead of creating a NAT VM. It provides the same outbound-only role for the private application hosts without OS patching or a single-purpose VM. At this small footprint it is generally the better GCP implementation; NAT data processing remains usage-based.

Compute Engine uses zonal managed instance groups with a target size of one rather than standalone instances. This preserves the single-instance AWS footprint while keeping the existing deployment and replacement workflow. It does not create active-active HA.

The load balancer is HTTP-only by default because the current AWS ALB has one HTTP listener. Add managed TLS later when the public DNS name is settled; doing so is intentionally outside this parity baseline.

VPC flow logs, Cloud NAT logs, and load-balancer request logs are disabled by default because the current AWS Terraform does not enable equivalent access/flow logging. They can be turned on independently with variables when needed.

## Important application compatibility

The service binaries must support the GCP contracts before traffic is moved from AWS:

- Parameter Manager through Application Default Credentials. Parameter IDs match the existing AWS SSM suffix constants; for example `/yevmiye/staging/db-host` maps to the GCP parameter `db-host` in the production project.
- Secret Manager for the generated PostgreSQL connection JSON. The `rds-secret-arn` parameter contains the GCP Secret Manager resource name, preserving the existing two-step lookup pattern.
- Pub/Sub instead of SQS. Worker pulls the category subscription; Core and Worker publish the appropriate events.
- The notification container accepts the standard wrapped Pub/Sub HTTP push envelope and returns success only after processing.
- Core and Chat continue to expose `/ready` on ports 8080 and 8081.

The load balancer keeps the current routing contract: `/core/*` routes to Core, `/core/health` and `/core/ready` are rewritten to `/health` and `/ready`, and `/chat`/`/chat/*` route to Chat with the `/chat` prefix removed.

## Remote state bootstrap

The state bucket is a separate Terraform root because a backend cannot create the bucket that stores its own state.

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

The state bucket is private, versioned, protected from Terraform destruction, and retains the live object plus one previous version.

## Configure and apply

Start from the AWS-parity example:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Replace the project ID and every credential/configuration placeholder. In particular, confirm `ws_allowed_origins`, OAuth configuration, Grafana endpoints, R2 configuration, GitHub organization/repositories, and application model endpoints.

Then review a saved plan before applying:

```bash
terraform fmt -recursive
terraform validate
terraform plan -out=production.tfplan
terraform apply production.tfplan
```

Terraform creates every Parameter Manager container. It adds versions for values managed by Terraform and leaves the manually supplied secret-like parameters empty for population after the first apply:

```bash
./scripts/populate-parameters.sh YOUR_GCP_PROJECT_ID
```

The script reads typed secrets from stdin rather than placing them on the command line. Firebase credentials are loaded from a validated JSON file path. These manually created versions do not enter Terraform state.

Terraform generates the PostgreSQL password and stores its connection JSON in Secret Manager. The generated password and Terraform-managed R2 credentials are sensitive values in Terraform state; restrict access to the state bucket accordingly.

## Notification deployment

Terraform creates the Cloud Run service with Google's public hello image as a bootstrap and initially leaves notification delivery disabled. Deploy the real notification container first, then set:

```hcl
notification_delivery_enabled = true
```

and apply again. This avoids the placeholder image acknowledging and dropping notification events.

## GitHub Actions identity

Set the production GitHub environment variables from Terraform outputs:

- `GCP_WORKLOAD_IDENTITY_PROVIDER` = `github_workload_identity_provider`
- `GCP_DEPLOY_SERVICE_ACCOUNT` = `github_deploy_service_account`
- `GCP_PROJECT_ID` = the production project ID
- `GCP_REGION` = the selected region
- `GCP_ZONE` = `compute_zone`
- `GCP_CORE_CHAT_INSTANCE_GROUP` = `core_chat_instance_group`
- `GCS_DEPLOY_BUCKET` = `app_deployments_bucket`

Deployment jobs should declare the environment configured in `github_environment` (default `production`) and request `id-token: write` plus `contents: read` permissions.

## Scaling up later

This production baseline intentionally starts with the current small AWS staging sizing rather than a highly available design. Before sending production traffic, reassess at least these settings:

- move Core/Chat and Worker to larger machine types as observed load requires;
- move Cloud SQL from shared-core zonal to a dedicated-core regional HA tier;
- consider multi-zone application capacity;
- enable HTTPS and a managed certificate;
- enable deletion protection;
- increase database backup/PITR retention;
- enable the logging signals needed for incident response and audit requirements.
