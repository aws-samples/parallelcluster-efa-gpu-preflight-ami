IMAGE=registry.gitlab.aws.dev/smml/benchmarking/tools/preflight
DEPLOY_IMAGE=deploy
container_build:
	docker build -t ${IMAGE} ./preflight
container_run:
	docker run --privileged --device=/dev/infiniband/uverbs0 --device=/dev/infiniband/uverbs1 --device=/dev/infiniband/uverbs2 --device=/dev/infiniband/uverbs3 --gpus=all ${IMAGE}
container: container_build container_run
ami_cpu:
	packer build -var aws_region=us-east-1 -var "ami_version=1" -var playbook_file=pcluster-cpu.yml packer-ami.pkr.hcl | tee cpu_ami.log
ami_gpu:
	packer build -var aws_region=us-east-1 -var "ami_version=1" -var playbook_file=pcluster-gpu.yml packer-ami.pkr.hcl | tee gpu_ami.log
ami_example:
	cd preflight/example_ami && packer build -color=true -var-file variables.json ami.json | tee log
deploy_build:
	docker build -t ${DEPLOY_IMAGE} ./test
deploy: deploy_build
	docker run -v ${HOME}/.aws:/root/.aws:ro -v ${shell pwd}/test:/tmp/test ${DEPLOY_IMAGE} pcluster create-cluster -n test-ami -r us-east-1 -c /tmp/test/cluster.yaml --rollback-on-failure false