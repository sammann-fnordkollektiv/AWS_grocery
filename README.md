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
	* [ ] Authentication (see below)
		* [ ] TODO: Understand aws configure list output? 	
	* [ ] Define AWS ressources with AWS CDK
		* [ ] 2x EC2 with Amazon Linux (latest)
		* [ ] 3x subnets in VPC
			* [ ] 1x EC2[0] in subnet[0]
			* [ ] 1x EC2[0] in subnet[1]
			* [ ] 1x RDS in subnet[2]
		* [ ] Security groups
			* [ ] ALB
				* [ ] <- HTTP 0.0.0.0
			* [ ] SG EC2[0]
				* [ ] <- HTTP ALB-SG
			* [ ] RDS
				* [ ] -> RDS 5432
		* [ ] Load balancer ELB -> 2 EC2 instances"
			* [ ] _do_after_launch.sh -> ?
		* [ ] RDS, postgres
* [ ] CloudFormation
	* [ ] Synth via `cdk synth`
	* [ ] Deploy via `cdk deploy`
* [ ] Python
	* [ ] `pip install -r requirements.txt`
* [ ] Github.com
	* [ ] Have a SSH deploy key in Github.com
* [ ] Clean Up
	* [ ] Diff with original repo and remove all unrequired
	* [ ] Move this README to `infrastructure/`

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
aws configure sso # see # Authentication ## aws configure sso
cdk bootstrap
cdk diff
cdk deploy
```

# Welcome to your CDK Python project!

This is a blank project for CDK development with Python.

The `cdk.json` file tells the CDK Toolkit how to execute your app.

This project is set up like a standard Python project.  The initialization
process also creates a virtualenv within this project, stored under the `.venv`
directory.  To create the virtualenv it assumes that there is a `python3`
(or `python` for Windows) executable in your path with access to the `venv`
package. If for any reason the automatic creation of the virtualenv fails,
you can create the virtualenv manually.

To manually create a virtualenv on MacOS and Linux:

```
$ python3 -m venv .venv
```

After the init process completes and the virtualenv is created, you can use the following
step to activate your virtualenv.

```
$ source .venv/bin/activate
```

If you are a Windows platform, you would activate the virtualenv like this:

```
% .venv\Scripts\activate.bat
```

or if you are using PowerShell:

```
.\.venv\Scripts\Activate.ps1
```

Once the virtualenv is activated, you can install the required dependencies.

```
$ pip install -r requirements.txt
```

At this point you can now synthesize the CloudFormation template for this code.

```
$ cdk synth
```

To add additional dependencies, for example other CDK libraries, just add
them to your `requirements.txt` file and rerun the `python -m pip install -r requirements.txt`
command.

## Useful commands

 * `cdk ls`          list all stacks in the app
 * `cdk synth`       emits the synthesized CloudFormation template
 * `cdk deploy`      deploy this stack to your default AWS account/region
 * `cdk diff`        compare deployed stack with current state
 * `cdk docs`        open CDK documentation

Enjoy!
