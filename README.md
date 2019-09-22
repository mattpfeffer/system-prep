# System Prep
A collection of startup and build scripts for configuring a production ready LEMP stack

## Requirements

- Ubuntu 18.04+ (May work on other Debian flavours but no promises)

## Features

### start.sh

Entry point when running in interactive mode; Steps the user through the process

### build.sh

Configures system info and access; installs any required packages

- Sets the system hostname
- Updates system, including distro
- Sets up a new user with passwordless sudo *(not required on AWS)*
- Adds the user's nominated key to *authorized_keys* *(not required on AWS)*
- Disables root login and password authentication *(not required on AWS)*
- Installs Fish and makes it the default shell
- Sets up unattended upgrades for updates (not just security updates)
- Downloads sources for Nginx, [ngx_cache_purge](https://github.com/FRiCKLE/ngx_cache_purge) module and any depenencies
- Compiles Nginx from source with ngx_cache_purge (used with Nginx FastCGI cache)
- Installs the compiled Nginx .deb package
- Installs MariaDB
- Installs PHP (FPM) and the following additional modules - MySQL, XML, Curl, GD, Mbstring
- Installs Certbot for working with [Lets Encrypt](https://letsencrypt.org/)

### configure.sh

Configures Nginx and sets up SSL

- Sets up the server document root
- Installs configuration stubs for Nginx including some useful Nginx defaults
- Configures server blocks, adding correct project info
- Obtains an SSL certificate from [Lets Encrypt](https://letsencrypt.org/) using Certbot
- Generates stronger Diffie-Hellman parameters
- Enables SSL and sets up canonical domain redirects

## Installation

1. `cd ~`
2. `wget https://github.com/mattpfeffer/system-prep/archive/v1.0.0.tar.gz`
3. `tar -xzf v1.1.tar.gz`
4. `mv system-prep-1.1 system-prep`
5. `chmod u+x system-prep/start.sh` 

## Usage

### Command Line

1. `cd ~/system-prep`
2. `./start.sh`
3. Follow the prompts

### Non-Interactive Startup Script

build.sh can be run as a startup script on platforms such as AWS, Digital Ocean and Vultr.

1. Change the values under 'Defaults' to reflect your use case
2. Save to the relevant area of your target platform (e.g. AWS)
3. Ensure you select the script when launching your instance