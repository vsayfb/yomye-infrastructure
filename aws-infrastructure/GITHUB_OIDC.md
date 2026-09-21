# GitHub Actions OIDC deployment

The deployment workflows use GitHub Actions OpenID Connect (OIDC) to assume the AWS role `yevmiye-github-actions-deploy`. No long-lived AWS access keys are stored in GitHub.

## Critical environment-name requirement

The GitHub Actions job environment and Terraform's `github_repo_env_name` must match exactly, including capitalization.

The staging configuration is:

```hcl
# environment/prod/terraform.tfvars
github_repo_env_name = "staging"
```

Each deployment workflow must therefore declare:

```yaml
permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    environment: staging
```

If Terraform says `production` while the workflow says `staging`, AWS rejects the token with:

```text
Could not assume role with OIDC:
Not authorized to perform sts:AssumeRoleWithWebIdentity
```

## Trusted repositories

The repositories allowed to assume the deployment role are configured by `github_repos` in `environment/prod/terraform.tfvars`:

```hcl
github_repos = [
  "yevmiye-core",
  "yevmiye-chat",
  "yevmiye-worker",
  "yevmiye-notification",
]
```

The trust policy in `modules/deploy/iam.tf` accepts GitHub's legacy and immutable repository subject formats. For Core, the expected legacy subject is:

```text
repo:vsayfb/yevmiye-core:environment:staging
```

The immutable format includes the GitHub owner and repository numeric IDs:

```text
repo:vsayfb@OWNER_ID/yevmiye-core@REPOSITORY_ID:environment:staging
```

Access remains limited to the configured repositories and the `staging` GitHub environment.

## Required GitHub environment variables

Configure these variables in the repository's `staging` GitHub environment:

- `DEPLOY_ROLE_ARN`: value of the Terraform output `github_actions_deploy_role_arn`.
- `AWS_REGION`: `eu-central-1`.
- `DEPLOY_BUCKET`: value of the Terraform output `app_deployments_bucket_name`.
- `INSTANCE_NAME_TAG`: `yevmiye-core-chat` for Core and Chat, or `yevmiye-worker` for Worker.

The workflow passes `DEPLOY_ROLE_ARN` to `aws-actions/configure-aws-credentials`:

```yaml
- name: Configure AWS credentials (OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ vars.DEPLOY_ROLE_ARN }}
    aws-region: ${{ vars.AWS_REGION }}
```

## Applying a trust-policy change

Changing `github_repo_env_name`, `github_repos`, or `modules/deploy/iam.tf` does not update AWS until the Terraform change is applied. After applying it, rerun the GitHub Actions workflow manually.

## Troubleshooting checklist

For `sts:AssumeRoleWithWebIdentity` authorization failures, check:

1. The workflow has `permissions: id-token: write`.
2. The job declares `environment: staging`.
3. `github_repo_env_name` is exactly `staging`.
4. The repository is present in `github_repos`.
5. `DEPLOY_ROLE_ARN` points to the role created by this Terraform stack.
6. The latest Terraform trust-policy changes have been applied to AWS.
7. The workflow is using the intended GitHub `staging` environment and its variables.

Do not solve OIDC failures by adding AWS access keys to GitHub secrets or by allowing wildcard repositories in the AWS trust policy.
