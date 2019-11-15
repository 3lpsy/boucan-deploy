# This project holds the terraform + packer projects for Boucan

More documentation can be found here: [Boucan: A Bug Bounty Canary Platform](https://github.com/3lpsy/boucanpy)

## Limitations

Due to the need to setup nameservers in the registration page (api) and not the hosted zones page in route53, the use of AWS/Route53 (in the current implementation) force the use of a subdomain
