        .PHONY: tf-init tf-plan tf-apply tf-destroy helm-lint build-image

        TF_DIR=terraform/aws
        K8S_CONTEXT=arn:aws:eks:REGION:ACCOUNT_ID:cluster/CLUSTER_NAME

        tf-init:
	cd $(TF_DIR) && terraform init

        tf-plan:
	cd $(TF_DIR) && terraform plan

        tf-apply:
	cd $(TF_DIR) && terraform apply -auto-approve

        tf-destroy:
	cd $(TF_DIR) && terraform destroy -auto-approve

        helm-lint:
	helm lint charts/testapp

        build-image:
	docker build -t testapp:local app
