#!/bin/bash

# Check for inactive users and disable their access keys if they are inactive for more than 90 days

DAYS_INACTIVE=90

# Get list of all IAM users
users=$(aws iam list-users --query 'Users[*].UserName' --output text)

# Iterate over each user
for user in $users; do
    echo "Checking user: $user"

    # Get access keys for the user
    keys=$(aws iam list-access-keys --user-name $user --query 'AccessKeyMetadata[*].AccessKeyId' --output text)

    for key in $keys; do
        # Check the last used date for the access key
        last_used=$(aws iam get-access-key-last-used --access-key-id $key --query 'AccessKeyLastUsed.LastUsedDate' --output text)
        
        if [[ -z $last_used || $last_used == "None" ]]; then
            echo "Key $key for user $user has never been used. Deactivating it."
            aws iam update-access-key --user-name $user --access-key-id $key --status Inactive
            continue
        fi
        
        # Calculate the difference in days since the key was last used
        days_since_last_use=$(( ( $(date +%s) - $(date -d "$last_used" +%s) ) / 86400 ))

        # Deactivate the key if it has been inactive for more than the specified number of days
        if (( days_since_last_use > DAYS_INACTIVE )); then
            echo "Key $key for user $user has been inactive for $days_since_last_use days. Deactivating it."
            aws iam update-access-key --user-name $user --access-key-id $key --status Inactive
        else
            echo "Key $key for user $user is still active, last used $days_since_last_use days ago."
        fi
    done
done
