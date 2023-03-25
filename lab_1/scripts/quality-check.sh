main() {
  cloneRepository
  cd "./shop-angular-cloudfront"
  runQualityCheck
}

# Clones the repository if it not exists
cloneRepository() {
  if [ ! -d "./shop-angular-cloudfront" ]
  then
    echo "Clonning shop-angular-cloudfront repository..."
    git clone git@github.com:EPAM-JS-Competency-center/shop-angular-cloudfront.git
  else
    echo "shop-angular-cloudfront repository already exists!"
  fi
}

# Runs the quality checks from the project repository (linter, unit tests and e2e)
runQualityCheck() {
  echo "Running quality checks (linter, unit tests, e2e)"

  #Running npm audit
  npm audit
  
  # Running linter
  npm run lint

  # Running unit tests
  npm run test

  # Running e2e tests
  npm run e2e
}

main 
