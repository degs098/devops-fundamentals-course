main() {
  cloneRepository
  buildProject "${@}"
  compressBuild
}

# Clones the repository if it not exists and change the current folder
# to the cloned repository folder
cloneRepository() {
  if [ ! -d "./shop-angular-cloudfront" ]
  then
    echo "Clonning shop-angular-cloudfront repository..."
    git clone git@github.com:EPAM-JS-Competency-center/shop-angular-cloudfront.git
  else 
    echo "shop-angular-cloudfront repository already exists!"
  fi
  cd "./shop-angular-cloudfront"
}

# Install the dependencies and generates a build dist folder with the 
# specified environment (production|development)
buildProject() {
  echo "Starting building process!"

  echo "Installing project dependencies"
  npm i

  echo "Generating build package" 

  CONFIGURATION_VALUE="development"

  # Loop through each argument and check if the configuration flag is present
  while [ $# -gt 0 ]; do
    arg="$1"
    case $arg in
        --configuration)
          # Check if the next argument is "production"
          if [ "$2" = "production" ]; then
            CONFIGURATION_VALUE="production"
          fi
          shift
          ;;
        *)
          shift
          ;;
    esac
  done

  # Check if the configuration flag was present and get the value
  echo "Configuration flag is set to $CONFIGURATION_VALUE"
  
  echo "Running build"
  if [ "$CONFIGURATION_VALUE" = "production" ]
  then
    export ENV_CONFIGURATION=$CONFIGURATION_VALUE
    npm run build -- --configuration=$CONFIGURATION_VALUE
  else
    npm run build
  fi
}

# Compress the dist folder into a client-app.zip file
compressBuild() {
  ZIP_FILE="./client-app.zip"

  echo "Compressing build into a .zip file"

  # If client-app.zip exists, it should be removed so the script would
  # generate a new .zip file from a latest build version
  if [ -f "$ZIP_FILE" ]
  then
    echo "Removing current .zip file to generate a new one"
    rm -f $ZIP_FILE
  fi

  # Check if the dist folder exists, otherwise it kills the process
  if [ ! -d "./dist" ]
  then
    echo "dist folder not found, please re-run the build-client script to generate the folder"
    exit 0
  fi

  # Compressing the build dist folder with zip
  zip -r "client-app.zip" "./dist"

  # Checking that the .zip file was created
  if [ -f "$ZIP_FILE" ]
  then
    echo "dist folder successfully compressed into the client-app.zip file!"
  fi
}

main "${@}"
