[travis]: https://travis-ci.org/nando/tacoma

# Tacoma

[![Build Status](https://travis-ci.org/nando/tacoma.svg?branch=master)][travis]

Simple command-line tool for managing AWS credentials across different projects and tools.

## Installation

    $ gem install tacoma

## Usage

Tacoma needs a special file `.tacoma.yml` in your home directory.  It can create a sample for you with

     tacoma install

The format of the `.tacoma.yml` file is pretty straighforward

     project:
       aws_identity_file: "/path/to/pem/file/my_project.pem"
       aws_secret_access_key: "YOURSECRETACCESSKEY"
       aws_access_key_id: "YOURACCESSKEYID"
       region: "REGION"
       repo: "$HOME/projects/my_project"
	 another_project:
       aws_identity_file: "/path/to/another_pem.pem"
       aws_secret_access_key: "ANOTHERECRETACCESSKEY"
       aws_access_key_id: "ANOTHERACCESSKEYID"
       region: "REGION"
       repo: "$HOME/projects/another_project"

Once setup with a file like this, you can run

     tacoma list

And it will list all the configured entries.  Running

     tacoma switch project

Will add the specified identity file into the SSH agent, and will generate configuration files for the supported tools, which at this time are

- [Fog](https://github.com/fog/fog), which should work with Capistrano's capify-ec2.
- [Boto](https://github.com/boto/boto)
- [s3cmd](https://github.com/s3tools/s3cmd)
- [route53](https://github.com/pcorliss/ruby_route_53)
- [aws cli](https://github.com/aws/aws-cli)

Running `tacoma switch` with the `--with-exports` option will also echo shell export sentences for the most common incarnations of the AWS env vars.

     tacoma version

Will display the current tacoma version and list all available configuration templates (providers).

     tacoma current
     
Will display the currently active tacoma environment.

If you don't indicate a specific region, tacoma will use the "eu-west-1" region by default.

## Bash Completion

There's an user contributed script for bash completion feature. To use it simply get from the `/contrib/` path and source it in your bash session (after rbenv gets sourced if it is there)

## TODO

- Check for errors in the `tacoma.yml` file
- Add other AWS tool providers (Knife, AWS cli, ...)
- Honor the different optional environment vars for the different config files (i.e `FOG_RC`)


## THANKS

This tool is shamelessly inspired in Raul Murciano's [rack-generator](https://github.com/raul/rack-generator)
