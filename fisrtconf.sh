#!/bin/bash

getadd() {
    # Prompt user for domain or IP address
    read -p "Enter domain or IP address (leave blank for public IP): " address

    # Use public IP address if user enters nothing
    if [[ -z "$address" ]]; then
        # Retrieve public IP address from the internet
        public_ip=$(curl -s https://api.ipify.org)

        # Confirm public IP address with user
        read -p "Use public IP address $public_ip? (y/n): " confirm
        if [[ "$confirm" == "y" ]]; then
            address=$public_ip
        else
            echo "Please enter a domain or IP address."
            exit 1
        fi
    fi

    # Confirm address with user
    read -p "Use address $address? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo "Aborted."
        exit 1
    fi

    # Prompt user to select protocol type
    while true; do
        echo "Select protocol type:"
        echo "1. TCP"
        echo "2. UDP"
        read -p "Enter protocol number: " protocol_num

        # Check that protocol number is valid
        if [[ "$protocol_num" == "1" ]]; then
            protocol="tcp"
            break
        elif [[ "$protocol_num" == "2" ]]; then
            protocol="udp"
            break
        else
            echo "Invalid protocol number: $protocol_num"
            echo "Please enter 1 for TCP or 2 for UDP."
        fi
    done
}

genconfdocker() {
    #docker-compose run --rm openvpn ovpn_genconfig -u $protocol://$address
}

changeport() {
    # Prompt user for new port number, default is 1194
    read -p "Enter new port number (default is 1194): " new_port

    # Use default port number if user enters nothing
    if [[ -z "$new_port" ]]; then
        new_port=1194
    fi

    # Replace "1194" with new port number in docker-compose.yml
    sed -i "s/1194/$new_port/g" ./docker-compose.yml

    # Replace "1194" with new port number in openvpn.conf
    sed -i "s/1194/$new_port/g" ./openvpn-data/conf/openvpn.conf

    echo "Port number changed to $new_port"
}

#run
getadd
genconfdocker
changeport
