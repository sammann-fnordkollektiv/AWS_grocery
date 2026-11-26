# AWS grocery

* This is a fork.
* Also it's an exercise in a masterschool.com learning journey.

## Infrastructure as Code (IaC) and tasks

* [x] OS
	* [x] [Debian 13](https://www.debian.org/download)
* [x] Git
	* [x] [direnv](https://direnv.net/)
	* [x] [Conventional Commit](https://www.conventionalcommits.org/en/v1.0.0/)
* [ ] [AWS CDK](https://aws.amazon.com/de/cdk/faqs/) (imperative), Python
	* [x] Installation (see below)
	* [x] Authentication (see below)
		* [x] TODO: Understand aws configure list output?
	* [x] Setup Amazon ECR (see below)
		* [ ] WARNING! Your credentials are stored unencrypted in '/home/user/.docker/config.json'.
Configure a credential helper to remove this warning. See
https://docs.docker.com/go/credential-store/
	* [ ] Define AWS ressources with AWS CDK
		* [x] 1st EC2 with Amazon Linux (latest)
		* [x] 1st subnet in VPC Public
		* [x] 2nd subnet in VPC Private, Isolated
		* [x] 1st RDS in private, isoldated subnet
			* [x] TODO: Init 
		* [x] Security groups
			* [x] TODO: Clean-up 
			* [x] ALB
				* [x] <- HTTP 0.0.0.0
			* [x] SG EC2[0]
				* [x] <- HTTP ALB-SG
			* [x] RDS
				* [x] -> RDS 5432
		* [x] Load balancer ELB -> 2 EC2 instances"
			* [ ] _do_after_launch.sh -> init_db!
		* [x] RDS, postgres
		* [x] 2nd EC2 with Amazon Linux (for Load Balancing) 
* [x] CloudFormation
	* [x] Synth via `cdk synth`
	* [x] Deploy via `cdk deploy` -> `_aws_deploy`
* [x] Python
	* [x] `pip install -r requirements.txt`
* [x] Github.com
	* [x] Have a SSH deploy key in Github.com -> all in cdk, no need anymore
* [x] Clean Up
	* [x] Diff with original repo and remove all unrequired

## Setup Amazon ECR

```
# Variables
EC_REPOSITORY=grocerymate-app
REGION=eu-central-1
ACCOUNT=$(aws sts get-caller-identity \
  --query Account --output text )
REPO_URI="$ACCOUNT.dkr.ecr.$REGION.amazonaws.com/$EC_REPOSITORY"
# Login to AWS ECR
aws ecr get-login-password \
  --region "$REGION" \
  | docker login --username AWS --password-stdin \
      "$ACCOUNT.dkr.ecr.$REGION.amazonaws.com"
```

Above is also saved in ./scripts/_aws_login

```
docker build -t $EC_REPOSITORY .
docker tag $EC_REPOSITORY:latest "$REPO_URI:latest"
docker push "$REPO_URI:latest"
```


## Authentication

### aws configure sso

1. Login to AWS account via [AWS Access Portal](https://masterschool.awsapps.com/start/#/)
	1. Click on `Account Name`
	2. Click on `Access keys`
	3. Window `Get credentials fro Administration Access` opens
2. In terminal:
```
aws configure sso [Enter]
SSO session name (Recommended): cedrik [Enter]
SSO start URL [None]: <1ee 1.3> [Enter]
SSO region [None]: <see 1.3> [Enter]
SSO registration scopes [sso:account:access]: <leave default> [Enter]
```
3. In browser:
	1. Login (authenticate `aws configure sso`)
	2. Click `allow access`
4. Test in browser:
    1. See
```
...
CLI profile name [<profile-name>]:
...
```
	2. Copy output in _not versioned_ _gitignored_ `env/stuff` for later
	3. Enter `aws sso login --profile <profile-name - see 3.3>`
	4. Enter `aws sts get-caller-identity --profile <profile-name - see 3.3>`
	5. Enter `aws s3 ls --profile <profile-name - see 3.3>`
	6. Enter `aws configure list`
	7. Enter `export AWS_PROFILE=<profile-name - see 3.3>`, Commands in 4.3-6 should work without `--profile ...` 

### [Failed] Clickops

1. Login to AWS account via [AWS Access Portal](https://masterschool.awsapps.com/start/#/)
2. Search for `IAM` and click
3. Click `IAM Users`
4. Click `Create User`
5. Enter `cedrik`
6. Click `Next`
7. Click `Set permissions`
8. Chose `Attach policies directly`
9. Click `AmazonRDSFullAccess`
10. Click `AmazonEC2FullAccess`
11. Click `IAMFullAccess`
12. Click `AmazonS3FullAccess`
13. Click `AmazonDynamoDBFullAccess`
14. Fail, masterschool.com disallows further users. Use your own user then.

### References

* Video https://www.youtube.com/watch?v=7xngnjfIlK4
* Text [Different methods to provide user access](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_identity-management.html?icmpid=docs_iam_console#AccessControlMethods)

## Development

* [x] Add aws profile to `./infrastructure/.envrc`
* [x] Useful commands
```
cdk diff # Look at diff
cdk deploy --require-approval=never # Make it so!
```
* [ ] ...  

## Installation

```
# System
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y python3 python3-venv python3-pip nodejs npm awscli
sudo apt autoremove -y
node --version # must be newer than 22!
## if `node --version` less than 22
sudo apt install curl
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash
exit # close and reopen terminal
nvm install --lts
nvm use --lts # user, not system wide.
node --version
npm --version
sudo npm install -g aws-cdk
cdk --version
aws --version
# Project
cd ~/Git/AWS_grovery/
mkdir infrastructure
cd infrastructure
cdk init app --language python
python3 -m venv .venv
echo 'source .venv/bin/activate' > .envrc
echo 'export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm use --silent default
' >> .envrc 
direnv allow
source .venv/bin/activate
python -m pip install -r requirements.txt
pip install --upgrade pip
python -m pip freeze > requirements.txt # later useful command
cdk ls
cdk synth
# Authentication
aws configure sso # see '# Authentication' '## aws configure sso'
cdk bootstrap
cdk diff
cdk synth
cdk deploy
```