# Deploying to a real AWS account

This repo is **plan-only / $0 by default**. Everything below is for when you
actually want to `apply` it to a live AWS account. Work top to bottom — the two
steps people most often skip are **Phase 1 (verify engine versions)** and the
**state backend decision (Phase 2)**.

> 💸 **Cost warning:** RDS for **Oracle has no free tier**. `make apply` creates
> billable resources within minutes. Start with the `dev` profile (single-AZ,
> smallest instances), capture what you need, and `make nuke`. Confirm current
> Oracle License Included pricing in the [AWS Pricing Calculator](https://calculator.aws)
> first.

---

## Phase 0 — Prerequisites (your machine)

- [ ] Terraform installed (`terraform version` → ≥ 1.6)
- [ ] AWS CLI installed (`aws --version`)
- [ ] AWS credentials configured:
  - `aws configure` (access key/secret), **or** `aws configure sso`
- [ ] Confirm you're pointed at the **right account**:
  ```bash
  aws sts get-caller-identity
  ```
- [ ] The IAM principal can create: **RDS, EC2/VPC, KMS, Secrets Manager, IAM
      roles, CloudWatch, SNS, Budgets.** (Personal account: `AdministratorAccess`
      is simplest. Org account: scope a least-privilege policy.)

---

## Phase 1 — Pre-flight validation (do NOT skip)

The `engine_version` and `instance_class` values in `environments/*.tfvars` are
**examples**. They change over time and vary by region — verify they exist
before applying, or `apply` will fail partway through.

- [ ] List valid Oracle SE2 versions in your region:
  ```bash
  aws rds describe-db-engine-versions --engine oracle-se2 \
    --region ap-northeast-1 \
    --query 'DBEngineVersions[].EngineVersion' --output table
  ```
- [ ] Confirm the instance class supports that version:
  ```bash
  aws rds describe-orderable-db-instance-options \
    --engine oracle-se2 --engine-version <CHOSEN_VERSION> \
    --region ap-northeast-1 \
    --query 'OrderableDBInstanceOptions[].DBInstanceClass' \
    --output text | tr '\t' '\n' | sort -u
  ```
- [ ] List valid Aurora MySQL versions:
  ```bash
  aws rds describe-db-engine-versions --engine aurora-mysql \
    --region ap-northeast-1 \
    --query 'DBEngineVersions[].EngineVersion' --output table
  ```
- [ ] If you change the Oracle version, **also** align the parameter group family
      in `modules/rds-oracle/main.tf` (currently `oracle-se2-19`).
- [ ] Update `environments/dev.tfvars` (and `prod.tfvars`) to match.

---

## Phase 2 — Choose your state backend

The committed config uses **local state** (the `backend "s3"` block in
`versions.tf` is commented out). Terraform state holds the generated DB password
(`random_password`) **in plaintext**.

- [ ] **Solo / short-lived test:** local state is fine. Never commit
      `terraform.tfstate` (already in `.gitignore`); keep the file safe.
- [ ] **Real / shared use:** set up an **encrypted S3 bucket + DynamoDB lock
      table first** (chicken-and-egg — they must exist before Terraform can store
      state in them), then uncomment and fill the `backend "s3"` block in
      `versions.tf` and re-run `terraform init`.

---

## Phase 3 — Configure the dev profile

Edit `environments/dev.tfvars`:

- [ ] Set `alarm_email` to a real address — otherwise the Budget and CloudWatch
      alarms are created with **no subscriber** (you get no alerts).
- [ ] (Optional) Set `pagerduty_endpoint` to a PagerDuty/Slack HTTPS endpoint.
- [ ] (Optional) Adjust `monthly_budget_usd` (default `5`).
- [ ] Keep `enable_nat_gateway = false` and `enable_interface_endpoints = false`
      in dev unless you specifically need them (both cost money).

---

## Phase 4 — Deploy

```bash
make init
make plan ENV=dev     # READ the plan — confirm resource count & no surprises
make apply ENV=dev    # << billing starts here; Oracle takes ~15–20 min
```

- [ ] `make init` succeeds
- [ ] `make plan ENV=dev` reviewed (nothing unexpected)
- [ ] `make apply ENV=dev` completes

---

## Phase 5 — Post-deploy verification

- [ ] **Confirm the SNS email subscription** — AWS sends a confirmation email;
      click the link or alarms can't reach you:
  ```bash
  aws sns list-subscriptions --region ap-northeast-1
  ```
- [ ] Grab the outputs:
  ```bash
  terraform output
  ```
- [ ] Retrieve credentials from Secrets Manager (note: `ppc-dev/...` prefix):
  ```bash
  aws secretsmanager get-secret-value \
    --secret-id ppc-dev/oracle/master --region ap-northeast-1 \
    --query SecretString --output text
  ```
- [ ] Connect to the DB **from inside the VPC** — the databases are in private
      subnets and are not publicly accessible (by design). Use a bastion/EC2 in
      the VPC, a VPN, or SSM port-forwarding.
- [ ] (Optional) Capture the screenshots listed in [`docs/README.md`](docs/README.md)
      and walk the [Failover & DR demo](README.md#failover--dr-demo).

---

## Phase 6 — Teardown (don't forget)

```bash
make nuke ENV=dev     # destroys everything for dev
```

- [ ] Confirm everything is gone:
  ```bash
  aws rds describe-db-instances --region ap-northeast-1 \
    --query "DBInstances[?starts_with(DBInstanceIdentifier, 'ppc-dev')].DBInstanceIdentifier"
  ```

> ⚠️ `prod.tfvars` sets `deletion_protection = true`, so `make nuke ENV=prod`
> will **refuse** to delete the databases until you disable that flag first.
> This is intentional — it prevents an accidental production wipe.

---

## TL;DR

1. Configure AWS creds → `aws sts get-caller-identity`
2. **Verify engine versions/instance classes exist in-region** → fix tfvars
3. Decide local vs S3 state (state contains the DB password)
4. Set `alarm_email` in `dev.tfvars`
5. `make plan ENV=dev` → `make apply ENV=dev` → test → `make nuke ENV=dev`
