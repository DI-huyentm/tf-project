# Makefile for Terraform project
# Run with: make <target>

TF=terraform
TFVARS=terraform.tfvars

init:
	@$(TF) init

plan:
	@$(TF) plan -var-file=$(TFVARS)

apply:
	@$(TF) apply -var-file=$(TFVARS) -auto-approve

destroy:
	@$(TF) destroy -var-file=$(TFVARS) -auto-approve

validate:
	@$(TF) validate

format:
	@$(TF) fmt -recursive

clean:
	@rm -rf .terraform .terraform.lock.hcl

help:
	@echo "Makefile commands:"
	@echo "  init       - terraform init"
	@echo "  plan       - terraform plan with tfvars"
	@echo "  apply      - terraform apply with tfvars"
	@echo "  destroy    - terraform destroy with tfvars"
	@echo "  validate   - terraform validate"
	@echo "  format     - terraform fmt recursively"
	@echo "  clean      - remove .terraform and lock file"
