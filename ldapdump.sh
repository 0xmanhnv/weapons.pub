#!/bin/bash

# Please enter your AD credential:
# Root domain: manhnv.com
# AD User: 0xmanhnv
# Passwd : 


# Create workspace
FOLDER=$(pwd)/ldapdump_$(date "+%Y_%m_%d")

printf "Creating $FOLDER \n"
mkdir -p $FOLDER
cd $FOLDER

# FILEs
FILE_DCs="$FOLDER/DCs.txt"
FILE_DC_IPs="$FOLDER/DC_IPs.txt"


# Please enter your AD credential:
printf "Please enter your AD credential:\n"
user_subdomain=""
read -p "Root domain: " domain
read -p "AD User: " user
read -p "Passwd : " -s pass

# -------------------------- HELPER
# Analysis user
user=$(echo $user | awk -F '@' '{print $1}')
user_subdomain=$(echo $user | awk -F '@' '{print $2}' | awk -F "$domain" '{print $1}' | sed 's/\.//g')

# printf "$user@$domain"
# ---------------------------------

function extract_DCs() {
    printf "\n==> Run extract Dns Root"

    # Domain to base search string dc
    dc_string=""
    for dc in $(echo $domain | tr "." "\n")
    do
        dc_string=$dc_string"dc=$dc,"
    done
    dc_string=`echo $dc_string | sed 's/,*$//g'`

    # List dns root
    ldapsearch -H ldap://$domain -D "$user@$domain" -w "$pass" -b "cn=Partitions,cn=Configuration,$dc_string" "dnsRoot" \
    | grep 'dnsRoot' | grep -E -wv 'DomainDnsZones|ForestDnsZones|requesting' | awk -F ' ' '{print $2}' | sort | uniq > $FILE_DCs

    # Dns root to ips DCs
    cat $FILE_DCs | xargs -I{} host {} | awk -F " " '{print $4}' | sort | uniq > $FILE_DC_IPs
}


function handle_ldapdomaindump() {
    folder_ldapdomaindump="$FOLDER/ldapdomaindump"
    mkdir -p "$folder_ldapdomaindump"

    cat "$FILE_DCs" | xargs -I{} -P5 ldapdomaindump -u $user_subdomain\\$user -p $pass -o $folder_ldapdomaindump/{} {}

    # Extract users
    cat "$FILE_DCs" | xargs -I{} -P5 sh -c "cat $folder_ldapdomaindump/{}/domain_users.grep | awk -F \"\t\" '{print \$3}' | sort | tee {}_users.txt"

    printf "\nUsers informations extracted\n"
}

function main() {
    extract_DCs
    handle_ldapdomaindump
}

# Execu main function
main
