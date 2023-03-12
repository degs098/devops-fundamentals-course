#!/bin/bash

# Set default threshold value
THRESHOLD=${1:-10}

echo $THRESHOLD

while true
do
    # Get available disk space in GB
    FREE_SPACE=$(df -h / | awk 'NR==2 {print $4}' | cut -d'G' -f1)

    echo 'Free disk space in GB' $FREE_SPACE
    # Compare available disk space with threshold value
    if [ "$FREE_SPACE" -lt "$THRESHOLD" ]
    then
        # Send warning message
        echo "Warning: Free disk space is below $THRESHOLD GB"
    fi

    # Wait for 5 minutes before checking again
    sleep 300
done