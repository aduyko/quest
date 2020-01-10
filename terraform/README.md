# Infrastructure initialization for the Rearc Quest App

This terraform configuration will set up an entire AWS environment and run a web accessible Rearc Quest container in ECS. The full list of generated resources, from VPC to EC2, can be seen by running `terraform plan`.

## Dependencies
- Terraform v0.12.x
- AWS CLI configured with keys with enough access to do infrastucture work
- The dockerhub container "aduyko/rearc-quest:latest" (this can be substituted if desired)

## Execution

This terraform configuration can be executed as a dry run using `terraform plan` and executed in actuality using `terraform apply`. If the service is no longer required it can be eliminated with `terraform destroy`.
