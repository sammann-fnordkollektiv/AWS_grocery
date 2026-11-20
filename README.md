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

## Installation

```
# System
sudo apt update -y
sudo apt upgrade -y
sudo apt install -y python3 python3-venv python3-pip nodejs npm
sudo apt autoremove -y
node --version # must be newer than 22!
# if `node --version` less than 22
sudo apt install curl
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.41.0/install.sh | bash
exit # close and reopen terminal
nvm install --lts
nvm use --lts # user, not system wide.
node --version
npm --version
sudo npm install -g aws-cdk
cdk --version
# Project
cd ~/Git/AWS_grovery/
mkdir infrastructure
cd infrastructure
cdk init app --language python
python3 -m venv .venv
echo 'source .venv/bin/activate' > .envrc
direnv allow
source .venv/bin/activate
python -m pip install -r requirements.txt
pip install --upgrade pip
python -m pip freeze > requirements.txt # later useful command
cdk ls
cdk synth
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
