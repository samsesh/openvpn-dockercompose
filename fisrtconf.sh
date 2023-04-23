#!/bin/bash

dockercheck() {
    # Check if Docker is already installed
    if ! command -v docker &>/dev/null; then
        echo $(tput setaf 2)Docker is not installed on this system. Installing Docker...$(tput sgr0)

        # Install Docker using the official Docker installation script
        curl -sSL https://get.docker.com | sudo sh

        # Add the current user to the docker group so you can run Docker commands without sudo
        sudo usermod -aG docker $USER

        # Start the Docker service
        sudo service docker start

        sleep 5
        clear
        echo $(tput setaf 2)Docker has been installed successfully!$(tput sgr0)
    else
        echo $(tput setaf 2)Docker is already installed on this system.$(tput sgr0)
    fi

    sleep 5
    clear
}

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
    # run docker for create config file
    docker compose run --rm openvpn ovpn_genconfig -u $protocol://$address
}

changeport() {
    # Check current port in docker-compose.yml file
    current_port=$(grep -oP '\d+:\d+\/udp' docker-compose.yml | cut -d':' -f1)
    while true; do
        read -p "Enter new port number (Current port is $current_port)Do you want to change it? (y/n): " confirm

        if [[ "$confirm" == "n" ]]; then
            new_port=$current_port
            break
        elif [[ "$confirm" == "y" ]]; then
            # Prompt user for new port number
            while true; do
                read -p "Enter new port number (10-65535): " new_port

                # Check that port number is valid
                if ! [[ "$new_port" =~ ^[0-9]+$ ]]; then
                    echo "Invalid port number: $new_port"
                elif ((new_port < 10)) || ((new_port > 65535)); then
                    echo "Invalid port number: $new_port (must be between 1024 and 65535)"
                else
                    break
                fi
            done
            break
        else
            echo "Invalid input. Please enter 'y' or 'n'."
        fi
    done
    # Replace "1194" with new port number in docker-compose.yml
    sed -i "s/$current_port:/$new_port:/" ./docker-compose.yml
    sed -i "s/^container_name:.*/container_name:$container_name_open/g" $file_location_open/docker-compose.yml
    # run docker for create config file
    genconfdocker
    # Replace "1194" with new port number in openvpn.conf
    sed -i "s/1194/$new_port/g" ./openvpn-data/conf/openvpn.conf
    sed -i "s/proto udp/proto $protocol/" ./openvpn-data/conf/openvpn.conf
    echo "Port number changed to $new_port"
}

#run
dockercheck
getadd
changeport
