# minecraft-evoker
A set of scripts for running a minecraft server on AWS spot instances.

## Purpose

This repository provides a way to create a cloudformation stack which creates:

- An s3 bucket for storing configuration files, server binaries, and world backups.
- An elastic ip address which can be used to connect to the minecraft server when it is running.
- An autoscaling group which automatically places spot bids in order to make sure that an ec2 instance is available.
- A launch configuration which helps bootstrap an instance, download relevant world backups and configuration files and brings the minecraft server online.

## Prerequisites

You must have an AWS account. On your computer, make sure that you have the AWS
cli installed and have configured it to use the credentials for the
aforementioned account by default. Currently, the helper scripts don't support
using other profiles, but that's trivially easy for you to add if you know what
you are doing.

Make sure that you create an [EC2 Key Pair](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws) for logging into the ec2 instance running the server.

## Usage

1. Copy `parameters.sample.json` to `parameters.json` and edit the values accordingly.
  - `ServerFilename` - the name of the minecraft server that you downloaded from mojang (or whatever you renamed it to)
  - `BucketName` - whatever you want to name your new s3 bucket
  - `ServerName` - some arbitrary, alphanumeric name for your server
  - `InstanceType` - the EC2 instance type which you want to provision and run your minecraft server on
  - `OperatorEMail` - your email address. This is used to notify you of autoscaling operations.
  - `KeyName` - This is the name of the EC2 Key Pair that you created as a prerequisite.
  - `SSHLocation` - This is the ip address of your home. It is used in a hacky way to lock down ssh access to just you.
  - `SpotBid` - The maximum amount of money that you are willing to pay for the ec2 instance, per hour. This does not account for all costs which will be incurred by the infrastructure created by using these scripts. Please see AWS documentation and read the code in this repository for details.

2. Run `create-stack.sh` (located in the `helpers` directory) to create the s3 bucket.

3. Run `upload-scripts.sh` to upload the bootstrap and subsystem scripts to the bucket.

4. Upload the server file that you downloaded from Mojang to the bucket you specified in `parameters.json`. It should be placed in the `/common/servers/` directory.

5. Upload any relevant minecraft configs to the bucket under `/servers/YOUR_SERVER_NAME/configs`. You must confirm the acceptance of the minecraft server eula by placing a properly configured `eula.txt` in that directory in order for the server to start.

6. Run `update-stack.sh` to update the existing stack and build a server.

7. Lookup the elastic IP that was created in the AWS console. You may use this to connect to your server.

If at any time, you want to delete the stack that you created, run `delete-stack.sh`. This does not guarantee that all resources will be deleted in AWS. You will need to do your due diligence to make sure that they are.

## Contributing

Pull requests welcome!
