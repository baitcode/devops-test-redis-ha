.PHONY: help test buildbins

SHELL=/bin/bash
DOCKER_PREFIX=devops
DOCKER_APP_IMAGE_TAG=${DOCKER_PREFIX}/counter
DOCKER_TWEMPROXY_IMAGE_TAG=${DOCKER_PREFIX}/twemproxy

## Use make [command]:
##
## - help             Display this help
## - buildbinaries    Build 64-bit Linux binary. Binary is stored in build folder
help:
	@egrep "^##" Makefile | sed -e 's/##//'

# test:
#	mkdir -p ./test-results/junit/
#	gotestsum --junitfile ./test-results/junit/unit-tests.xml -- ./... -v --count=1 -p 1 pkg

buildbinaries:
	@(cd src && go get && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -gcflags "all=-N -l" -o ../build/counter ./main.go)

builddocker: buildbinaries
	docker build -f ./deployment/counter/docker/counter.Dockerfile ./build -t ${DOCKER_IMAGE_TAG}

push: builddocker
	docker push -t ${DOCKER_IMAGE_TAG}
	docker push -t ${DOCKER_TWEMPROXY_IMAGE_TAG}

refresh: builddocker
	kubectl -n counter delete --all pods

