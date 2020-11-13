#!/bin/bash
#
# Script for building a robust LEMP stack on Ubuntu/Debian Systems
#
# Copyright (c) 2018 Matt Pfeffer & Other Contributors. Licenced under https://opensource.org/licenses/MIT
# 
# https://github.com/mattpfeffer/system-prep


### Defaults ###
fqdn=my.domain.com
user=myuser
publickey='ssh-rsa AAA....'


### Configuration ### 

# Specify distro and release
distro=$(lsb_release -i | sed -r 's/^.*:\t(.*)/\l\1/')
release=$(lsb_release -c | sed -r 's/^.*:\t(.*)/\l\1/')

distro_pretty=$(echo $distro | sed -r 's/.*/\u&/')
release_pretty=$(echo $release | sed -r 's/.*/\u&/')

if [ $interactive ]
then

    # Define Hostname
    printf "\n\n${green}What will this server's fully qualified domain name be? ${grey}(e.g. my.example.com)${none}\n\n"
    read fqdn

    # Define credentials for shell access
    if [ $deploy_to == 'generic' ]
    then

        printf "\n${green}Choose a username for shell access? ${grey}(can't be 'root', 'admin' etc)${none}\n\n"
        read user

        printf "\n${green}What is your public key? ${grey}(paste below)${none}\n\n"
        read publickey
    fi

    # Confirmation
    printf "\n${green}Are the following details correct? ${grey}(Y or N)${none}\n\n"
    if [ $deploy_to == 'aws' ]
    then
        printf "  ${yellow}Platform:${none}\tEC2 Instance (AWS)\n"
    else
        printf "  ${yellow}Platform:${none}\tGeneric Insatnce (Digital Ocean, Vultr etc)\n"
    fi
    printf "  ${yellow}Distribution:${none}\t${distro_pretty}\n"
    printf "  ${yellow}Release:${none}\t${release_pretty}\n"
    printf "  ${yellow}Domain:${none}\t${fqdn}\n"
    if [ $deploy_to == 'aws' ]
    then
        printf "  ${yellow}User:${none}\t\tubuntu\n"
    else
        printf "  ${yellow}User:${none}\t\t${user}\n"
    fi
    if [ $deploy_to == 'aws' ]
    then
        printf "  ${yellow}Key:${none}\t\tEC2 Key Pair\n\n"
    else
        printf "  ${yellow}Key:${none}\n  ${publickey}\n\n"
    fi

    read -n1 confirm

    if [ $confirm != 'Y' ] && [ $confirm != 'y' ]
    then
        printf "\n\n${red}Aborting build! Nothing to see here.${none}\n\n"
        exit 0
    else
        printf "\n\n${green}Starting build, here we go...${none}\n\n"
    fi 

fi


### Build Script ###

# Start logging
${sudo} mkdir -p /var/log/system-prep
{

    # Set hostname and FQDN
    echo -e "127.0.0.1 $fqdn" | ${sudo}tee -a /etc/hosts
    ${sudo}sed -i 's/.*/'"$fqdn"'/' /etc/hostname

    # Update server
    ${sudo}apt-get update -q
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get upgrade -yq
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get dist-upgrade -yq
    ${sudo}apt-get autoremove -yq

    if [ $deploy_to == 'generic' ]
    then

        # Create user with passwordless sudo
        adduser --disabled-password --gecos '' $user
        usermod -aG sudo $user
        sed -i '$a \\n'"$user"' ALL=NOPASSWD: ALL' /etc/sudoers
        mkdir -p /home/$user/.ssh
        echo  $publickey > /home/$user/.ssh/authorized_keys
        chmod -R 700 /home/$user/.ssh
        chown -R $user:$user /home/$user/.ssh

        # # Disable root login and password authentication
        sed -i 's/^PermitRootLogin\s.*$/PermitRootLogin no/' /etc/ssh/sshd_config
        sed -i 's/^#PasswordAuthentication\s.*$/PasswordAuthentication no/' /etc/ssh/sshd_config
        systemctl restart ssh

    fi

    # Install Fish and make default shell
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get install -yq fish
    ${sudo}chsh -s /usr/bin/fish $user

    # Setup unattended upgrades
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get install -yq unattended-upgrades             # Already installed on Ubuntu, usually
    ${sudo}sed -i '/^Unattended-Upgrade::Allowed-Origins\s{/,/};/ s/^\/\/\s*"${distro_id}:${distro_codename}-updates";/        "${distro_id}:${distro_codename}-updates";/' /etc/apt/apt.conf.d/50unattended-upgrades
    ${sudo}sed -i '/^Unattended-Upgrade::Package-Blacklist\s{/,/};/ c Unattended-Upgrade::Package-Blacklist {\n        "nginx";\n        "nginx-full";\n        "nginx-common";\n};' /etc/apt/apt.conf.d/50unattended-upgrades
    ${sudo}sed -i 's/^\/\/Unattended-Upgrade::Remove-Unused-Dependencies\s.*$/Unattended-Upgrade::Remove-Unused-Dependencies "true";/;s/^\/\/Unattended-Upgrade::Automatic-Reboot\s.*$/Unattended-Upgrade::Automatic-Reboot "true";/;s/^\/\/Unattended-Upgrade::Automatic-Reboot-Time\s.*$/Unattended-Upgrade::Automatic-Reboot-Time "02:00";/' /etc/apt/apt.conf.d/50unattended-upgrades
    ${sudo}sed -i 's/^APT::Periodic::Download-Upgradeable-Packages\s.*$/APT::Periodic::Download-Upgradeable-Packages "1";/;s/^APT::Periodic::AutocleanInterval\s.*$/APT::Periodic::AutocleanInterval "7";/;$a \APT::Periodic::Unattended-Upgrade "1";' /etc/apt/apt.conf.d/10periodic

    # Download Nginx sources, dependencies and modules
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get install -yq unzip

    ${sudo}mkdir -p /opt/nginx/modules
    cd /opt/nginx/modules
    ${sudo}wget -nv https://github.com/FRiCKLE/ngx_cache_purge/archive/master.zip
    ${sudo}unzip master.zip
    ${sudo}rm master.zip
    ${sudo}mv ngx_cache_purge-master/ ngx_cache_purge/

    ${sudo}add-apt-repository -y ppa:nginx/stable
    ${sudo}sed -ri 's/^#\s(deb-src.*main)$/\1/' /etc/apt/sources.list.d/nginx-${distro}-stable-${release}.list
    ${sudo}apt-get update -q
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get install -yq dpkg-dev
    ${sudo}mkdir -p /opt/nginx/rebuild
    cd /opt/nginx/rebuild
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get source -yq nginx
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get build-dep -yq nginx

    # Build Nginx
    ${sudo}sed -ri -e '/core_configure_flags\s:=/,/\w$/ !b; /\w$/ a \                        --add-module=/opt/nginx/modules/ngx_cache_purge' -e 's/(\w)$/\1 \\/' $(find . -regextype sed -regex '.*debian/rules$')
    cd $(find . -type d -name 'nginx-[0-9]*')
    ${sudo}dpkg-buildpackage -b

    # Install Nginx
    cd ..
    ${sudo}dpkg -i $(find . -name 'nginx-full_*')
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get install -fyq
    ${sudo}apt-mark hold nginx nginx-common nginx-full

    # Install MariaDB and PHP
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get install -yq mariadb-server php-fpm php-mysql php-xml php-curl php-gd php-mbstring php-zip

    # Install Certbot
    DEBIAN_FRONTEND=noninteractive ${sudo}apt-get install -yq certbot python3-certbot-nginx

    # Get System Prep scripts
    if [ ! $interactive ]
    then
        cd /home/$user
        wget -nv https://github.com/mattpfeffer/system-prep/archive/master.zip
        unzip master.zip
        rm master.zip
        mv system-prep-master system-prep/
        chown -R $user:$user system-prep
    fi

# Finish logging
} 2>&1 | ${sudo}tee /var/log/system-prep/build.log

# Reboot server
${sudo}shutdown -r now