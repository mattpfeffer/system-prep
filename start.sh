#!/bin/bash
#
# System Prep entry script and splash screen
#
# Copyright (c) 2018 Matt Pfeffer & Other Contributors. Licenced under https://opensource.org/licenses/MIT
# 
# https://github.com/mattpfeffer/system-prep


### Configuration ###

# Check for existing logs
if [ -f /var/log/system-prep/build.log ]
then
    already_built=true
fi

# AWS or Other?
if [ $(whoami) == 'ubuntu' ]
then
    deploy_to='aws'
    sudo='sudo '
    user=$(whoami)
else
    deploy_to='generic'
    sudo=''
    user='ubuntu'
fi

# Terminal Colours
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
grey='\033[0;90m'
none='\033[0m'

red_bold='\033[1;31m'
green_bold='\033[1;32m'
yellow_bold='\033[1;33m'
grey_bold='\033[1;90m'


### Display splash ###

printf '\n'
cat logo.txt
printf '\n\nA collection of startup and build scripts for configuring a production ready LEMP stack\n\n'
printf 'Copyright (c) Matt Pfeffer & Other Contributors. Licenced under https://opensource.org/licenses/MIT\n\n'
printf 'https://github.com/mattpfeffer/system-prep\n\n'

# Choose action
printf "${green}What would you like to do?${none}\n\n"
printf "  ${yellow}[1]${none} Build server - Install required packages and dependencies on a bare server\n"
printf "  ${yellow}[2]${none} Configure server - Configure web server, database and certificates for your project\n"
printf "  ${yellow}[3]${none} Optimize server - Tweak server configuration for optimal performance\n\n"
printf "  ${grey}[ESC] Exit${none}\n\n"

read -n1 operation

interactive=true

case $operation in
    1 )
        # Run build script
        if [ $already_built ]
        then
            printf "\n\n${yellow_bold}Warning!${none}\n"
            printf "${yellow}This server has already been configured with the build script. Running it again\nmay have unintended consequences.${none}\n\n"
            printf "${green}Are you sure you want to continue? ${grey}(Y or N)${none}\n\n"
            read -n1 continue
            if [ $continue == 'Y' ] || [ $continue == 'y' ]
            then
                source build.sh
            else
                printf "\n\n${green}Bye!${none}\n\n"
                exit 0
            fi            
        else
            source build.sh
        fi
        ;;
    2 )
        # Run configure script
        if [ ! $already_built ]
        then
            printf "\n\n${yellow_bold}Warning!${none}\n"
            printf "${yellow}This server wasn't created with the System Prep build script. Running the configuration may have unintended\nconsequences.${none}\n\n"
            printf "${green}Are you sure you want to continue? ${grey}(Y or N)${none}\n\n"
            read -n1 continue
            if [ $continue == 'Y' ] || [ $continue == 'y' ]
            then
                source configure.sh
            else
                printf "\n\n${green}Bye!${none}\n\n"
                exit 0
            fi            
        else
            source configure.sh
        fi
        ;;
    3 )
        # Run optimize script
        printf "\n\n${red}This function isn't supported yet.${none}\n\n" ;;
    $'\e' )
        printf "\n\n${green}Bye!${none}\n\n"
        exit 0 ;;
    * )
        # Exit script
        printf "\n\n${red}That is not a valid option. Please try again.${none}\n\n" ;;
esac