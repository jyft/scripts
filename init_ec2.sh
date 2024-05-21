#!/bin/bash

# Variables
USERNAME="mcuser"
GROUPNAME="mcapp"
DIRECTORY="/usr/local/mimecast"

# Function to check if a command succeeded
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}

# Update the system
sudo dnf update -y
check_command "System update failed."

# Install wget if not already installed
sudo dnf install -y wget
check_command "Failed to install wget."

# Install nano if not already installed
sudo dnf install -y nano
check_command "Failed to install nano."

# Import the Amazon Corretto public key
sudo rpm --import https://yum.corretto.aws/corretto.key
check_command "Failed to import Amazon Corretto public key."

# Add the Corretto 11 repository to the list of repositories
sudo curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo
check_command "Failed to add Corretto repository."

# Install Amazon Corretto 11 (JDK 11)
sudo dnf install -y java-11-amazon-corretto-devel
check_command "Failed to install Amazon Corretto 11."

# Verify installations
echo "Verifying installations:"
java -version
check_command "Java installation verification failed."
nano --version
check_command "Nano installation verification failed."
wget --version
check_command "Wget installation verification failed."

echo "Installation of JDK 11, nano, and wget completed successfully."

# Create the group if it doesn't exist
if ! getent group "$GROUPNAME" > /dev/null; then
    sudo groupadd "$GROUPNAME"
    check_command "Failed to create group '$GROUPNAME'."
    echo "Group '$GROUPNAME' created."
else
    echo "Group '$GROUPNAME' already exists."
fi

# Create the user if it doesn't exist and add to the group
if ! id -u "$USERNAME" > /dev/null 2>&1; then
    sudo useradd -m -g "$GROUPNAME" "$USERNAME"
    check_command "Failed to create user '$USERNAME'."
    echo "User '$USERNAME' created and added to group '$GROUPNAME'."

    sudo usermod -a -G "$GROUPNAME" "rocky"
    check_command "Failed to add user 'rocky' to group '$GROUPNAME'."
else
    echo "User '$USERNAME' already exists."
    # Ensure the user is in the group
    sudo usermod -a -G "$GROUPNAME" "$USERNAME"
    check_command "Failed to add user '$USERNAME' to group '$GROUPNAME'."

    sudo usermod -a -G "$GROUPNAME" "rocky"
    check_command "Failed to add user 'rocky' to group '$GROUPNAME'."
    
    echo "User '$USERNAME' added to group '$GROUPNAME'."
fi

# Create the directory if it doesn't exist
if [ ! -d "$DIRECTORY" ]; then
    sudo mkdir -p "$DIRECTORY"
    check_command "Failed to create directory '$DIRECTORY'."
    echo "Directory '$DIRECTORY' created."
else
    echo "Directory '$DIRECTORY' already exists."
fi

# Change ownership of the directory to the user and group
sudo chown -R "$USERNAME:$GROUPNAME" "$DIRECTORY"
check_command "Failed to change ownership of '$DIRECTORY'."
echo "Changed ownership of '$DIRECTORY' to user '$USERNAME' and group '$GROUPNAME'."

# Grant full permissions to the user and group
sudo chmod -R 770 "$DIRECTORY"
check_command "Failed to change permissions of '$DIRECTORY'."
echo "Granted read, write, and execute permissions to user '$USERNAME' and group '$GROUPNAME' on '$DIRECTORY'."

echo "Script completed successfully."
