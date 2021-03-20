CLUSTER_NAME						?= eks-cluster
AWS_PROFILE							?= default
AWS_REGION							?= ap-southeast-1
VPC_NETWORK_STACK                   ?= mnaustria-vpc-dev-stack
AWS_ACCOUNT_ID                      ?= $(shell aws sts get-caller-identity --query 'Account' --output text --profile $(AWS_PROFILE) --region $(AWS_REGION))
ALB_INGRESS_POLICY_ARN	            ?= arn:aws:iam::$(AWS_ACCOUNT_ID):policy/ALBIngressControllerIAMPolicy
VPC_ID							    ?= $(shell aws cloudformation describe-stacks --stack-name $(VPC_NETWORK_STACK) --query 'Stacks[0].Outputs[?OutputKey==`VpcId`].OutputValue' --output text --profile $(AWS_PROFILE) --region $(AWS_REGION))
PRIVATE_SUB_A						?= $(shell aws cloudformation describe-stacks --stack-name $(VPC_NETWORK_STACK) --query 'Stacks[0].Outputs[?OutputKey==`PrivateAZASubnet`].OutputValue' --output text --profile $(AWS_PROFILE) --region $(AWS_REGION))
PRIVATE_SUB_B						?= $(shell aws cloudformation describe-stacks --stack-name $(VPC_NETWORK_STACK) --query 'Stacks[0].Outputs[?OutputKey==`PrivateAZBSubnet`].OutputValue' --output text --profile $(AWS_PROFILE) --region $(AWS_REGION))
PUBLIC_SUB_A						?= $(shell aws cloudformation describe-stacks --stack-name $(VPC_NETWORK_STACK) --query 'Stacks[0].Outputs[?OutputKey==`PublicAZASubnet`].OutputValue' --output text --profile $(AWS_PROFILE) --region $(AWS_REGION))
PUBLIC_SUB_B						?= $(shell aws cloudformation describe-stacks --stack-name $(VPC_NETWORK_STACK) --query 'Stacks[0].Outputs[?OutputKey==`PublicAZBSubnet`].OutputValue' --output text --profile $(AWS_PROFILE) --region $(AWS_REGION))
KMS_ARN							    ?= $(shell aws kms describe-key  --key-id alias/eksworkshop --query 'KeyMetadata.Arn' --output text --profile $(AWS_PROFILE) --region $(AWS_REGION))
NODE_GROUP_CAP					    ?= 2
OS_NAME 						    := $(shell uname -s | tr A-Z a-z)
ENV									:= dev
OWNER                               := DevOps
TEAM                                := DevOps Team
PROJECT                             := sandbox

# Initialize Kubernetes Cluster
create-cluster:
ifeq ($(OS_NAME),darwin)
	gsed 's!config_cluster_name!$(CLUSTER_NAME)!; \
	s!config_aws_region!$(AWS_REGION)!; \
	s!config_tag_environment!$(ENV)!; \
	s!config_tag_owner!$(OWNER)!; \
	s!config_tag_team!$(TEAM)!; \
	s!config_tag_project!$(OWNER)!; \
	s!config_alb_policy_arn!$(ALB_INGRESS_POLICY_ARN)!; \
	s!config-sub_priv_a!$(PRIVATE_SUB_A)!; \
	s!config-sub_priv_b!$(PRIVATE_SUB_B)!; \
	s!config-sub_pub_a!$(PUBLIC_SUB_A)!; \
	s!config-sub_pub_b!$(PUBLIC_SUB_B)!; \
	s!config_ng_cap!$(NODE_GROUP_CAP)!; \
	s!config_kms_arn!$(KMS_ARN)!' kubernetes/cluster-config.yaml | eksctl create cluster -f - --profile $(AWS_PROFILE)
else
	sed 's!config-cluster-name!$(CLUSTER_NAME)!; \
	s!config_aws_region!$(AWS_REGION)!; \
	s!config_tag_environment!$(ENV)!; \
	s!config_tag_owner!$(OWNER)!; \
	s!config_tag_team!$(TEAM)!; \
	s!config_alb_policy_arn!$(ALB_INGRESS_POLICY_ARN)!; \
	s!config-sub_priv_a!$(PRIVATE_SUB_A)!; \
	s!config-sub_priv_b!$(PRIVATE_SUB_B)!; \
	s!config-sub_pub_a!$(PUBLIC_SUB_A)!; \
	s!config-sub_pub_b!$(PUBLIC_SUB_B)!; \
	s!config_ng_cap!$(NODE_GROUP_CAP)!; \
	s!config_kms_arn!$(KMS_ARN)!' kubernetes/cluster-config.yaml | eksctl create cluster -f - --profile $(AWS_PROFILE)
endif

# Create ALB RBAC Deployment
deploy-alb-rbac:
	kubectl apply -f kubernetes/ingress/alb-ingress-rbac.yaml

# CREATE ALB Ingress Deployment
deploy-alb-ingress:
	gsed 's!def-cluster-name!$(CLUSTER_NAME)!; \
	s!def-aws-region!$(AWS_REGION)!; \
	s!def-vpc-id!$(VPC_ID)!' kubernetes/ingress/alb-ingress-deployment.yaml | kubectl apply -f -