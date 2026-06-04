# One-time AWS bootstrap for GitHub OIDC (no static keys)

GitHub Actions authenticates to AWS using OpenID Connect, so you never store
AWS access keys in GitHub. Run this **once** before using the pipeline.

## 1. Create the OIDC identity provider in AWS

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## 2. Create the CI role with a trust policy scoped to YOUR repo

Save as `trust.json` (replace `ORG/REPO`):

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
    "Action": "sts:AssumeRoleWithWebIdentity",
    "Condition": {
      "StringEquals": { "token.actions.githubusercontent.com:aud": "sts.amazonaws.com" },
      "StringLike": { "token.actions.githubusercontent.com:sub": "repo:ORG/REPO:*" }
    }
  }]
}
```

```bash
aws iam create-role --role-name github-ci-kafka-eks \
  --assume-role-policy-document file://trust.json
# Attach least-privilege policy needed for EKS/VPC/IAM/KMS (scope down in prod).
aws iam attach-role-policy --role-name github-ci-kafka-eks \
  --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
```

## 3. Add GitHub repository secrets

| Secret name              | Value                                                   |
|--------------------------|---------------------------------------------------------|
| `AWS_OIDC_ROLE_ARN`      | `arn:aws:iam::<ACCOUNT_ID>:role/github-ci-kafka-eks`    |
| `GRAFANA_ADMIN_PASSWORD` | a strong password for Grafana                           |

## 4. Create the Terraform state backend (S3 + DynamoDB)

```bash
aws s3 mb s3://<your>-tfstate-bucket
aws s3api put-bucket-versioning --bucket <your>-tfstate-bucket \
  --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name <your>-tf-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

Then update the `backend "s3"` block in `terraform/versions.tf` with these names.
