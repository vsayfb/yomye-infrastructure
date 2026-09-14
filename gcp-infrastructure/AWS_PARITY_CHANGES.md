# AWS parity changes

This GCP root was adjusted to mirror the current AWS staging footprint rather than the previous larger/HA GCP design.

## Capacity and placement

- Environment remains `production`; only the infrastructure sizing mirrors the AWS staging footprint.
- Region remains Frankfurt (`europe-west3`).
- Added one explicit compute zone (`europe-west3-a`) to mirror AWS real compute in one AZ.
- Core/Chat changed from `e2-medium` to `e2-small`.
- Worker changed from `e2-standard-2` to `e2-small`.
- Core/Chat and Worker use fixed zonal Compute Engine instances protected from deletion and Terraform replacement. Core/Chat is attached to an unmanaged load-balancer instance group.
- Core/Chat boot disk changed from 20 GB to 10 GB balanced PD.
- Worker boot disk changed from 30 GB to 10 GB balanced PD.
- Worker still installs Ollama and `all-minilm:l12-v2`, matching the AWS worker bootstrap.

## PostgreSQL

- Cloud SQL changed from regional HA to zonal.
- Tier changed from `db-custom-1-3840` to `db-g1-small`, the closest small Cloud SQL memory footprint to AWS `db.t4g.micro` without dropping to 0.6 GiB.
- Explicit `edition = "ENTERPRISE"` added because PostgreSQL 16+ otherwise defaults to Enterprise Plus, which does not accept shared-core tiers.
- Storage remains 20 GB SSD and is fixed rather than auto-resizing, matching the fixed 20 GB AWS allocation.
- Backup retention reduced from seven retained backups to one.
- PITR transaction-log retention reduced to one day.
- Deletion protection disabled by default, matching AWS.
- Database username is generated with an AWS-style random suffix unless explicitly overridden.

## Networking and load balancing

- Managed Cloud NAT retained as the GCP-native equivalent of the AWS NAT instance.
- VPC flow logging is now opt-in and disabled by default.
- Cloud NAT logging is now opt-in and disabled by default.
- Load-balancer request logging is now opt-in and disabled by default.
- HTTPS/certificate resources removed from the parity baseline.
- The frontend now exposes one HTTP forwarding rule on port 80, matching the current AWS ALB listener.
- Core and Chat backend timeouts are 3600 seconds, matching the AWS ALB idle-timeout posture.

## Notification path

- Pub/Sub + Cloud Run remains the GCP-native equivalent of SQS + Lambda.
- Cloud Run still scales to zero and uses the existing 60-second request timeout.
- Cloud Run remains at 512 MiB because the current second-generation networking model uses that practical memory floor rather than the AWS Lambda's 256 MB setting.
- Notification deletion protection is disabled by default.

## Naming and deployment

- The GCP project is now explicitly treated as the environment boundary.
- Resource names use `yevmiye-*` rather than `yevmiye-production-*`, closer to the AWS naming convention.
- Service-account and Workload Identity names no longer hard-code `prod`.
- GitHub environment remains `production`.
- VM metadata carries the application environment, and remote deployment reads it rather than hard-coding production.
- Bootstrap state examples use the production project/bucket prefix.

## Validation performed

- Shell syntax checked for non-template deployment scripts.
- Checked all Terraform variable references against declarations.
- Checked Terraform resource/data references against declarations.
- Checked HCL delimiter balance across all Terraform and example tfvars files.
- Verified managed instance groups, managed-certificate, HTTPS-proxy, and regional Cloud SQL constructs are absent.

Terraform validation and an authenticated production plan were run for the persistent-VM migration.
