#!/bin/bash

DATA_FOLDER="../data"
USERS_DB="$DATA_FOLDER/users.db"

function main(){
  # Reads user action that will be perfomed
  ACTION=${1}

  case $ACTION in
    "add")
      addUsername
    ;;
    "help")
      dbHelp
    ;;
    "backup")
      createBackup
    ;;
    "find")
      userNameExists "${2}"
    ;;
    "list")
      listUsers "${2}"
    ;;
    "restore")
      restoreBackup
    ;;
    *)
      echo "Operation invalid."
      exit 0
    ;;
  esac
}

# Adds a new user entry into the users.db file
function addUsername() {
  echo "Adding a username"
  read -r -p "Enter user name: " USERNAME
  userNameExists "$USERNAME"
  isInputValid "$USERNAME"
  
  read -r -p "Enter user role: " ROLE
  isInputValid "$ROLE"

  local USER_ENTRY="$USERNAME, $ROLE"
  echo "$USER_ENTRY" >> $USERS_DB
  echo "The following entry has been added to the DB: $USER_ENTRY"
}

# Checks if the user name exists on the users.db
function userNameExists() {
  local USERNAME_VALUE
  USERNAME_VALUE=$(cat $USERS_DB | grep -w "${1}")
  
  # If the user exists on the users.db then kill the process 
  if [[ -n  "$USERNAME_VALUE" ]]
  then
    printf "User name matches:\n%s\n" "$USERNAME_VALUE"
    exit 0
  fi
 
  # If the performed operation was a 'find' then show the message
  # that the user does not exists
  if [[ $ACTION == "find" ]]
  then
    echo "User name not exists"
    exit 0
  fi
}

# It validates that the input is Latin letters only
function isInputValid() {
  local INPUT
  INPUT=${1}

  if [[ ! "$INPUT" =~ ^[a-zA-Z\ ]+$ ]]
  then
    echo "Input must be latin letters"
    exit 0
  fi
}

# It creates a backup from the users.db file
function createBackup() {
  echo "Creating database backup..."
  local DB_BACKUP_FILE
  DB_BACKUP_FILE=$(date +"%Y-%m-%d"-users.db.backup)

  cp $USERS_DB "$DATA_FOLDER/$DB_BACKUP_FILE"
  echo "Backup file created on $DATA_FOLDER/$DB_BACKUP_FILE"
}

# Restores the users.db file from the most recent backup file generated
function restoreBackup() {
  LAST_BACKUP_FILE_GENERATED=$(find $DATA_FOLDER -type f -name "*.backup" | sort -z | head -1)
  echo "Restoring database from " "$LAST_BACKUP_FILE_GENERATED"
  cat $LAST_BACKUP_FILE_GENERATED > $USERS_DB
  echo "Database restored"
}

# Displays the help menu for the db.sh available operations
function dbHelp() {
  echo "'$0' is intended for process operations with users database and supports next commands:"
  echo -e "\tadd -> add new entity to database;"
  echo -e "\thelp -> provide list of all available commands;"
  echo -e "\tbackup -> create a copy of current database;"
  echo -e "\trestore -> replaces database with its last created backup;"
  echo -e "\tfind -> found all entries in database by username;"
  echo -e "\tlist -> prints content of database and accepts optional 'inverse' param to print results in opposite order."
  exit 0
}

# List all the users base from the users.db file
function listUsers() {
  local INVERSE
  INVERSE=${1}
  local DB_CONTENT
  DB_CONTENT=$(cat $USERS_DB | awk '{ print NR". " $0 }')

  if [ -z "$INVERSE" ]
    then
      echo "$DB_CONTENT"
    else
      echo "$DB_CONTENT" | tail -r
  fi
}

main "${@}"


