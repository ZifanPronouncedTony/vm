#!/bin/bash

# T&M Hansson IT AB © - 2020, https://www.hanssonit.se/

# shellcheck disable=2034,2059
true
# shellcheck source=lib.sh
. <(curl -sL https://raw.githubusercontent.com/nextcloud/vm/master/lib.sh)

# Check for errors + debug code and abort if something isn't right
# 1 = ON
# 0 = OFF
DEBUG=0
debug_mode

# Check if root
root_check

choice=$(whiptail --radiolist "This script lets you setup DynDNS by using the ddclient application.\nYou have to setup an account before you can start.\nPlease choose your DynDNS-Provider.\nSelect by pressing the spacebar and ENTER" "$WT_HEIGHT" "$WT_WIDTH" 4 \
"Strato" "" OFF 3>&1 1>&2 2>&3)

case "$choice" in
    "Strato")
        PROVIDER="Strato"
        PROTOCOL="dyndns2"
        SERVER="dyndns.strato.com"
        USE_SSL="yes"
    ;;
    *)
    ;;
esac

# Enter your Hostname
while true
do
    HOSTNAME=$(whiptail --inputbox "Please enter the Host that you want to configure DDNS for. E.g. 'example.com'" "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
    if [[ "no" == $(ask_yes_or_no "Is this correct? $HOSTNAME") ]]
    then
        print_text_in_color "$ICyan" "OK, please try again."
        sleep 1
    else
        if [ -z "$HOSTNAME" ]
        then
            print_text_in_color "$ICyan" "Please don't leave the Inputbox empty."
            sleep 1
        else
            break
        fi
    fi
done

# Enter your login
while true
do
    LOGIN=$(whiptail --inputbox "Please enter the login for your DDNS provider. It will be most likely the Domain, that you want to setup. E.g. 'example.com'\nIf you are not sure, please refer to the documentation of your DDNS provider." "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
    if [[ "no" == $(ask_yes_or_no "Is this correct? $LOGIN") ]]
    then
        print_text_in_color "$ICyan" "OK, please try again."
        sleep 1
    else
        if [ -z "$LOGIN" ]
        then
            print_text_in_color "$ICyan" "Please don't leave the Inputbox empty."
            sleep 1
        else
            break
        fi
    fi
done

# Enter your password
while true
do
    PASSWORD=$(whiptail --inputbox "Please enter the password that you've got for DynDNS from your DDNS provider.\nIf you are not sure, please refer to the documentation of your DDNS provider." "$WT_HEIGHT" "$WT_WIDTH" 3>&1 1>&2 2>&3)
    if [[ "no" == $(ask_yes_or_no "Is this correct? $PASSWORD") ]]
    then
        print_text_in_color "$ICyan" "OK, please try again."
        sleep 1
    else
        if [ -z "$PASSWORD" ]
        then
            print_text_in_color "$ICyan" "Please don't leave the Inputbox empty."
            sleep 1
        else
            break
        fi
    fi
done

# Get results and store in a variable:
RESULT="You will see now a list of all entered information. Please check that everything seems correct.\n\n"
RESULT+="Provider=$PROVIDER\n"
RESULT+="Host=$HOSTNAME\n"
RESULT+="login=$LOGIN\n"
RESULT+="password=$PASSWORD\n"

# Present what we gathered, if everything okay, write to file
msg_box "$RESULT"
if [[ "no" == $(ask_yes_or_no "Do you want to proceed?") ]]
then
    exit
fi

# Install ddclient
if ! is_this_installed ddclient
then
    print_text_in_color "$ICyan" "Installing ddclient..."
    # This creates a ddclient service, creates a /etc/default/ddclient file and a /etc/ddclient.conf file
    DEBIAN_FRONTEND=noninteractive apt install ddclient -y
fi

# Write information to ddclient.conf
cat << DDCLIENT_CONF > "/etc/ddclient.conf"
# Configuration file for ddclient generated by debconf
#
# /etc/ddclient.conf

# Default system settings
use=if, if=ens32
use=web, web=checkip.dyndns.com, web-skip='Current IP Address: '

# DDNS-service specific setting
# Provider="$PROVIDER"
protocol="$PROTOCOL"
server="$SERVER"
ssl="$USE_SSL"

# user specific setting
login=$LOGIN
password=$PASSWORD

# Hostname follows:
$HOSTNAME
DDCLIENT_CONF

# Test connection
msg_box "Everything is setup by now and we will check the connection."
clear
ddclient -verbose

# Inform user 
any_key "Please check the logs above if everything looks good. If not, just run this script again."
