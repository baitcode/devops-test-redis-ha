# Foreword

It's been 4 p.m. Sunday when I've started. I've been quite busy this week to properly understand and think about task, and now 
with a tiny bit of regret I acknowledge, that should've discussed couple of questions:

For this test I would love to omit Kubernetes cluster configutation in the cloud. I decided that cloud infrastructure should be out of scope of this service.
And treat this as I would treat a project repo. Thus it should contain everything needed to develop application locally, and when it comes to cloud deploy, 
only contain application deployment scripts as if infrastructure is already in place.

Key requirements:
- The entire solution should be able to run on an fresh ubuntu VM.
- High-availability
- No changes to application logic
- Redis has to be password protected
- Should run on Ubuntu 

So. First I decided to work on the application deployment. I decided to compile go code locally for simplicity (it will work on Ubuntu anyway), 
the better way would be to use docker to build the code.
I quickly discovered that gin version is quite old and code would not run. First I though on changing the code, but then I decided not to touch it as infrastructure my main consern.
Application itself is a stateless so I picked kubernetes_deployment to publish it. I've introduced replica count setting to control scaling and added LoadBalancer.
I've studied through github issues and found version where route handling based on priority was introduces. Updated go.mod and switched to redis deployment.
With redis I picked StatefulDeployment and created volume claims that locally reserve volumes on host path. In cloud those can be provisioned differently
First I tried to set up Redis cluster, but due docker port mapping functionality I was not able to achieve any sensible result, cluster node could not get MEET command (after completing this test task I think that I've most likely mistaken somewhere). 
Then I tried to deploy a twemproxy with several Redis servers backed by replicas behind it. But twemproxy connection and sharding model assumes that clients are not using passwords to authenticate, which conflicted with requirements.
By this point I've ran out of options and started working on Redis with Sentinel processes. That worked well. 

Cluster mode amd twemproxy approach are an overkill for this test task as they also give an ability to scale horisontally, which is not required.

# Assumptions

1. Locally developers run docker.app with kubernetes support
2. Developers have proper C++ compilers to compile Go (compilation can be done inside docker as well, but for some reason, I decided not to do that)
3. Supported clouds? later I've dropped cloud support due to time restrictions.

# Structure

* `src` - contains service code
* `deployment` - contains all needed to build (ikr) and deploy application
    * `docker` - contains dockerfiles needed
    * `terraform` - contains all terraform configs
        * `_modules` 
            * `counter` - go application deployemtn
            * `redis` - HA redis with sentinel deployment
        * `local` - terraform scripts to deploy to local cluster (local, because it creates all resources, cloud deployment assumes that cloud infrastructure is already prepared)

`build` - contains build artefacts (binaries), excluded from git

Makefile is a main entrypoint for developer

`make buildbinaries` - will produce go binary of the counter app and store it in `build` folder
`make builddocker` - will call buildbinaries first then produce docker image tagged devops/counter
`make refresh` - builds docker and restarts counter service. Used to quickly refresh code during local development

# Developer flow

Current solution was well tested using docker

# How to test solution on fresh Ubuntu

Due to short amount of time I wasn't able to automate and debug dependency configuration on Ubuntu VM. 

1) First you need to install kubernetes server. I would suggest using `minikube`. Installation instructions are here https://minikube.sigs.k8s.io/docs/start/.
2) Install docker. https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository. 
__IMPORTANT__ Check this section: https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user
3) Start minikube

```bash
minikube start 
# If you are using single core VM then add arguments:
#   --extra-config=kubeadm.ignore-preflight-errors=NumCPU --force --cpus=1
```

3) Setup docker cli.
```bash
eval $(minikube docker-env)
```

4) Clone this repo
```
git clone https://github.com/baitcode/devops-test-redis-ha.git
```

5) Install Make and golang
```
sudo apt install -y make golang
```

6) Install terraform (https://developer.hashicorp.com/terraform/downloads)
```
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```
7) Install kubectl. https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-using-native-package-management

8) Build docker and deploy
```
cd devops-test-redis-ha/
make deploy
```

9) Expose port.
```
kubectl -n counter port-forward --address 0.0.0.0 services/counter 8080:8080
```

# Points to improve

1) VM configuration scripts
2) Integration tests
3) Test that nodes connect back to cluster after going online
4) Build binaries with docker
5) Easy way to configure kubectl context name aliases
6) Cloud ready solution