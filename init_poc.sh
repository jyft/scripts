#!/bin/bash

# Variables
REMOTE_SERVER="dev-sc-1.dev.mimecast.lan"
TARGET_SERVER="ec2-3-10-173-205.eu-west-2.compute.amazonaws.com"
TARGET_USER="rocky"
REMOTE_DIRS=("/usr/local/mimecast/gs-file-scan/cfg" "/usr/local/mimecast/gs-file-scan/cache")
SSH_KEY="content-poc-ssh-key.pem"

# Get the current username
CURRENT_USER=$(whoami)
ZIP_FILE="/home/${CURRENT_USER}/service_fs.zip"

# Create the zip archive on the remote server, ignoring any file failures
ssh "${CURRENT_USER}@${REMOTE_SERVER}" "sudo zip -r ${ZIP_FILE} ${REMOTE_DIRS[@]} 2>/dev/null"
ssh "${CURRENT_USER}@${REMOTE_SERVER}" "sudo chmod 777 ${ZIP_FILE}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to create zip file on remote server."
    exit 1
fi

echo "Succesfully created ${ZIP_FILE} on ${REMOTE_SERVER}"

# Transfer the zip file to the local machine
echo "Moving ${ZIP_FILE} to local machine"
scp "${CURRENT_USER}@${REMOTE_SERVER}:${ZIP_FILE}" "${ZIP_FILE}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to transfer zip file to local machine."
    exit 1
fi

# Transfer the zip file to the target server
echo "Moving ${ZIP_FILE} to AWS server"
scp -i "${SSH_KEY}" "${CURRENT_USER}@${REMOTE_SERVER}:${ZIP_FILE}" "${TARGET_USER}@${TARGET_SERVER}:${ZIP_FILE}"
if [ $? -ne 0 ]; then
    echo "Error: Failed to transfer zip file to AWS server."
    exit 1
fi

# Clean up the zip file from the remote server
ssh "${CURRENT_USER}@${REMOTE_SERVER}" "rm -f ${ZIP_FILE}"
if [ $? -ne 0 ]; then
    echo "Warning: Failed to remove zip file from remote server."
fi

echo "Files from ${REMOTE_DIRS[@]} on ${REMOTE_SERVER} have been zipped and transferred to ${TARGET_SERVER} successfully."
