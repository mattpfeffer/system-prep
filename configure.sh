#!/bin/bash
#
# Script for configuring a server built with System Prep
#
# Copyright (c) 2018 Matt Pfeffer & Other Contributors. Licenced under https://opensource.org/licenses/MIT
#
# https://github.com/mattpfeffer/system-prep


### Configuration ###

# Define project name
printf "\n\n${green}Choose a name for your project? ${grey}(Keep it brief, used for folder names and configuration files)${none}\n\n"
read project

project=$(echo $project | sed -r -e 's/\s/-/g' -e 's/.*/\L&/')

# Select target platform
printf "\n${green}What type of project are you configuring?${none}\n\n"
printf "  ${yellow}[1]${none} Generic\n"
printf "  ${yellow}[2]${none} Wordpress\n"
printf "  ${yellow}[3]${none} Laravel\n\n"
read -n1 platform

# Define domain
printf "\n\n${green}What will the primary domain be for this host? ${grey}(e.g. www.example.com)${none}\n\n"
read domain

# Define aliases
printf "\n${green}Will your project be accessible from any other aliases? ${grey}(e.g. example.com or www.otherdomain.com)${none}\n\n"
read alias


### Configure Script ###

# Start logging
{

    # Remove old site configuration
    ${sudo}rm /etc/nginx/sites-enabled/default
    ${sudo}rm /etc/nginx/sites-available/default

    # Setup web root
    ${sudo}mkdir -p /var/www/${project}
    echo "<h1><?= 'It\'s aliiiivvvee!!!' ?></h1>" | ${sudo}tee /var/www/${project}/index.php
    ${sudo}chown -R www-data:www-data /var/www/${project}

    # Copy configuration stubs
    ${sudo}cp conf/nginx/nginx.conf /etc/nginx/nginx.conf
    ${sudo}cp conf/nginx/snippets/cache-bypass.conf /etc/nginx/snippets/cache-bypass.conf
    ${sudo}cp conf/nginx/snippets/restrictions.conf /etc/nginx/snippets/restrictions.conf

    ${sudo}mkdir /etc/nginx/redirects

    case $platform in
        1 )
            ${sudo}cp conf/nginx/hosts/default.conf /etc/nginx/sites-available/${project}.conf ;;
        2 )
            ${sudo}cp conf/nginx/hosts/wordpress.conf /etc/nginx/sites-available/${project}.conf
            ${sudo}touch /etc/nginx/redirects/${project}.conf ;;
        3 )
            ${sudo}cp conf/nginx/hosts/laravel.conf /etc/nginx/sites-available/${project}.conf
            ${sudo}touch /etc/nginx/redirects/${project}.conf ;;
    esac

    # Configure worker processes and connections
    worker_processes=$(grep processor /proc/cpuinfo | wc -l)
    worker_connections=$(ulimit -n)

    ${sudo}sed -ri -e "s/\{\{worker_processes\}\}/${worker_processes}/" -e "s/\{\{worker_connections\}\}/${worker_connections}/" /etc/nginx/nginx.conf

    # Configure server block(s)
    ${sudo}sed -ri -e "s/\{\{name\}\}/${project}/g" -e "s/\{\{domain\}\}/${domain}/g" -e "s/\{\{alias\}\}/ ${alias}/g" /etc/nginx/sites-available/${project}.conf

    # Enable server and restart Nginx
    ${sudo}ln -s /etc/nginx/sites-available/${project}.conf /etc/nginx/sites-enabled/${project}.conf
    ${sudo}mkdir /var/cache/nginx
    ${sudo}systemctl restart nginx

    # Obtian certificate
    if [ -z "$alias" ]
    then
        ${sudo}certbot certonly -n --email 'support@orangedigital.com.au' --agree-tos --webroot -w /var/www/${project} -d $domain
    else
        ${sudo}certbot certonly -n --email 'support@orangedigital.com.au' --agree-tos --webroot -w /var/www/${project} -d $domain -d $alias
    fi

    # Generate strong DH params
    ${sudo}openssl dhparam -out /etc/ssl/dhparams.pem 2048

    # Enable SSL
    ${sudo}sed -ri '/### IF SSL ###/,/### END IF SSL ###/ s/^([^#]*)#\s/\1/' /etc/nginx/sites-available/${project}.conf
    ${sudo}sed -ri '/### IF !SSL ###/,/### END IF !SSL ###/d' /etc/nginx/sites-available/${project}.conf
    ${sudo}sed -ri '/### (END )?IF SSL ###|### (END )?IF \!SSL ###/d' /etc/nginx/sites-available/${project}.conf

    # Reload Nginx configuration
    ${sudo}systemctl reload nginx

    # Platform specific configuration
    case $platform in
        2 )
            # Install WP CLI
            ${sudo}wget -nv https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
            ${sudo}chmod +x wp-cli.phar
            ${sudo}mv wp-cli.phar /usr/local/bin/wp ;;
    esac

    printf "\n${green}All done! The server is configured and ready to use.${none}\n\n"

# Finish logging
} 2>&1 | ${sudo}tee /var/log/system-prep/configure.log
