# Boucan Deploy

This project holds the terraform + packer projects for Boucan

More documentation can be found here: [Boucan: A Bug Bounty Canary Platform](https://github.com/3lpsy/boucanpy)

## Building

This repo has two core "projects". One is a packer project, the other is a terraform project. They both assume you wish to deploy to AWS, have the appropriate IAM permissions. In addition, terraform assumes you have a domain in route53 that you wish to use.

### Packer

First, you will want to build the AMI in your account. Change into the directory and make sure all the environment variables are set:

```
$ cd packer
$ export PACKER_AWS_PROFILE_NAME=
$ export PACKER_REGION=
$ export PACKER_VPC_ID=
$ export PACKER_SUBNET_ID=
```

Once you have configured your environment (and assuming you have packer installed), you can build the AMI:

```
$ packer build -on-error=ask config.json
```

If it fails, you can try to SSH into the box and see why but hopefully it doesn't fail. Once it completes, take note of the AMI ID and save it. You'll need to use it for terraform.

### Terraform

Assuming you have a route53 domain name and have the AMI built, you'll first want to setup your environment. These can alternatively be placed in terraform.tfvars:

```
cd terraform
# IAM / AWS Credentials
export TF_VAR_aws_access_key=
export TF_VAR_aws_secret_access_key=
# the credentials you wish to setup in Boucan. These will be automatically created
export TF_VAR_admin_email=
export TF_VAR_admin_password
# will be the domain in route53
export TF_VAR_dns_root=
# will be 0.0.0.0/0 if actively using against targets or will be known cidrs you trust
export TF_VAR_internet_cidr_block=

# finally you'll want to setup the trusted_external_cidr_block, this is where you'll access the dashboard/api from
# because it is a list of strings, you can just set this in terraform.tfvars (inside the terraform directory)
echo 'trusted_external_cidr_block = ["x.x.x.x/32"]' >> terraform.tfvars
```

One last step, you need to set the AMI you built as the "ami" variable in variables.tf. Alternatively, you can set it in terraform.tfvars. It doesn't really matter.

```
echo 'ami="MYAMIROMPACKER"' >> terraform.tfvars
```

If you want valid ssl certs, modify the "acme_server_url" variable in variables.tf to use the production server url (non-staging).

Once everything is good to go, just build the project:

```
$ terraform plan
$ terraform apply
```

Hopefully everything works! If it doesn't, you can ssh in using the ssh key at data/key.pem and examine the "boucan-compose" systemd service.

### Limitations

Due to the need to setup nameservers in the registration page (api) and not the hosted zones page in route53, the use of AWS/Route53 (in the current implementation) force the use of a subdomain
