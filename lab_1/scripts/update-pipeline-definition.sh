main() {

  checkJSONFileArgument "${1}"

  checkJqInstallation

  createNewPipelineDefinitionVersion "${@}"
}

# Checks the JSON file existence and structure
checkJSONFileArgument() {
  JSON_FILE=$1

  # Check if the provided .json argument has the right extension
  if [[ ! "$JSON_FILE" =~ \.json$ ]]; then
    echo "The file $JSON_FILE does not have the .json extension or not file provided"
    exit 1
  fi

  HAS_PIPELINE_AND_METADATA=$(jq 'has("pipeline") and has("metadata")' "$JSON_FILE")
  if [[ $HAS_PIPELINE_AND_METADATA == "false" ]]
  then
    echo "Properties 'pipeline' and 'metadata' are missing"
    exit 1
  fi

  HAS_VERSION=$(jq '.pipeline | has("version")' "$JSON_FILE")
  if [[ $HAS_VERSION == "false" ]] # W: In POSIX sh, [[ ]] is undefined.
  then
    echo "Property 'pipeline.version' is missing"
    exit 1
  fi

  HAS_BUILD_CONFIGURATION_PROPERTIES=$(jq '.pipeline.stages[0].actions[0].configuration | has("Branch") and has("Owner") and has("PollForSourceChanges") and has("Repo")' "$JSON_FILE")
  if [[ $HAS_BUILD_CONFIGURATION_PROPERTIES == "false" ]]
  then
    echo "Some of the following properties are missing on the 'pipeline.stages[0].actions[0].configuration': 'Branch', 'Owner', 'PollForSourceChanges' and 'Repo'"
    exit 1
  fi

  CHECK_LINTING_STAGE_ENVIRONMENT_VARIABLES_PROPERTY=$(jq '.pipeline.stages[1].actions[0].configuration | has("EnvironmentVariables")' "$JSON_FILE")
  if [[ $CHECK_LINTING_STAGE_ENVIRONMENT_VARIABLES_PROPERTY == "false" ]]
  then
    echo "Linting and Unit Testing stage has the 'EnvironmentVariables' property missing"
    exit 1
  fi

  CHECK_BUILD_AND_DEPLOY_STAGE_ENVIRONMENT_VARIABLES_PROPERTY=$(jq '.pipeline.stages[3].actions[0].configuration | has("EnvironmentVariables")' "$JSON_FILE")
  if [[ $CHECK_BUILD_AND_DEPLOY_STAGE_ENVIRONMENT_VARIABLES_PROPERTY == "false" ]]
  then
   echo "Build and Deploy stage has the 'EnvironmentVariables' property missing"
   exit 1
  fi
}

# Validates if JQ is installed on the system
# otherwise it finishes the execution
checkJqInstallation() {
  if ! command -v jq &> /dev/null
  then
    echo "jq is not installed, please execute the following to install it: "
    echo "> Linux Debian and Ubuntu: sudo apt-get install jq"
    echo "> Linux Fedora: sudo dnf install jq"
    echo "> OS X: brew install jq"
    echo "> Windows: chocolatey install jq"
    echo "More information about jq installation in https://stedolan.github.io/jq/download/"
    exit 1
  fi

}

# Creates a new pipeline definition json file
createNewPipelineDefinitionVersion() {
  JQ_COMMAND="del(.metadata) | .pipeline.version += 1"
  NEW_PIPELINE_DEFINITION_FILE=$(date +"%Y-%m-%d"-pipeline.json)
  BRANCH="main"
  POLL_FOR_SOURCE=false

  # Loop through each argument looking for the --branch --configuration
  # --owner --poll-for-source-changes and --repo flags
  while [ $# -gt 0 ]; do
    arg="$1"
    case $arg in
        --branch)
          BRANCH="$2"
          BRANCH_CHANGES="| .pipeline.stages[0].actions[0].configuration.Branch = \"%s\""
          BRANCH_CHANGES=$(printf "$BRANCH_CHANGES" "$BRANCH")
          shift
          ;;
        --configuration)
          CONFIGURATION_VALUE="$2"
          ENVIRONMENT_VARIABLES_NEW_VALUE=$(printf '{"name": "BUILD_CONFIGURATION", "value": "%s", "type": "PLAINTEXT"}' "$CONFIGURATION_VALUE")
          ENVIRONMENT_VARIABLES_CHANGE="| .pipeline.stages |= map(.actions[0].configuration.EnvironmentVariables = %s)"
          
          ENVIRONMENT_VARIABLES_NEW_VALUE=$(echo "$ENVIRONMENT_VARIABLES_NEW_VALUE" | jq '.' -R)

          ENVIRONMENT_VARIABLES_CHANGE=$(printf "$ENVIRONMENT_VARIABLES_CHANGE" "$ENVIRONMENT_VARIABLES_NEW_VALUE")
          shift
          ;;
        --owner)
          OWNER="$2"
          OWNER_CHANGES="| .pipeline.stages[0].actions[0].configuration.Owner = \"%s\""
          OWNER_CHANGES=$(printf "$OWNER_CHANGES" "$OWNER")
          shift
          ;;
        --poll-for-source-changes)
          POLL_FOR_SOURCE="$2"
          POLL_FOR_SOURCE_CHANGES="| .pipeline.stages[0].actions[0].configuration.PollForSourceChanges = \"%s\""
          POLL_FOR_SOURCE_CHANGES=$(printf "$POLL_FOR_SOURCE_CHANGES" "$POLL_FOR_SOURCE")
          shift
          ;;
        --repo)
          REPO="$2"
          CHANGE_REPO="| .pipeline.stages[0].actions[0].configuration.Repo = \"%s\""
          CHANGE_REPO=$(printf "$CHANGE_REPO" "$REPO")
          shift
          ;;
        *)
          shift
          ;;
    esac
  done
  
  if [ -n "$POLL_FOR_SOURCE_CHANGES" ]
  then
    JQ_COMMAND="$JQ_COMMAND $POLL_FOR_SOURCE_CHANGES"
  fi

  if [ -n "$OWNER_CHANGES" ]
  then
    JQ_COMMAND="$JQ_COMMAND $OWNER_CHANGES"
  fi

  if [ -n "$CHANGE_REPO" ]
  then
    JQ_COMMAND="$JQ_COMMAND $CHANGE_REPO"
  fi

  if [ -n "$BRANCH_CHANGES" ]
  then
    JQ_COMMAND="$JQ_COMMAND $BRANCH_CHANGES"
  fi

  if [ -n "$ENVIRONMENT_VARIABLES_CHANGE" ]
  then
    JQ_COMMAND="$JQ_COMMAND $ENVIRONMENT_VARIABLES_CHANGE"
  fi

  JQ_COMMAND="jq '${JQ_COMMAND}'"

  echo "$JQ_COMMAND"

  # Checks if the current date json file exists and removes it
  if [[ -f "$NEW_PIPELINE_DEFINITION_FILE" ]]
  then
    rm "$NEW_PIPELINE_DEFINITION_FILE"
  fi

  # Creates a new json file
  touch "$NEW_PIPELINE_DEFINITION_FILE"
  

  # Executes the built jq command and writes the result on the new file
  eval "$JQ_COMMAND" ./pipeline.json >> "$NEW_PIPELINE_DEFINITION_FILE"
}

main "${@}"
