#!/bin/sh
# e is for exiting the script automatically if a command fails, u is for exiting if a variable is not set
# x would be for showing the commands before they are executed
set -eu

# FUNCTIONS
# Function for setting up git env in the docker container (copied from https://github.com/stefanzweifel/git-auto-commit-action/blob/master/entrypoint.sh)
_git_setup ( ) {
    cat <<- EOF > $HOME/.netrc
      machine github.com
      login $GITHUB_ACTOR
      password $GITHUB_TOKEN
      machine api.github.com
      login $GITHUB_ACTOR
      password $GITHUB_TOKEN
EOF
    chmod 600 $HOME/.netrc

    git config --global user.email "actions@github.com"
    git config --global user.name "GitHub Action"
}

# Checks if any files are changed
_git_changed() {
    [[ -n "$(git status -s)" ]]
}

# PROGRAM
echo "Installing prettier..."
case $INPUT_PRETTIER_VERSION in
    false)
        npm install --silent --global prettier @prettier/plugin-xml
        ;;
    *)
        npm install --silent --global prettier@$INPUT_PRETTIER_VERSION @prettier/plugin-xml
        ;;
esac

echo "Prettifing files..."
echo "Files:"
prettier $INPUT_PRETTIER_OPTIONS || echo "Problem running prettier with $INPUT_PRETTIER_OPTIONS"

# To keep runtime good, just continue if something was changed
if _git_changed;
then
  if $INPUT_DRY; then
    echo "Prettier found unpretty files!"
    exit 1
  else
    # Calling method to configure the git environemnt
    _git_setup
    echo "Commiting and pushing changes..."
    # Add changes to git
    git add "${INPUT_FILE_PATTERN}" || echo "Problem adding your files with pattern ${INPUT_FILE_PATTERN}"
    # Commit and push changes back
    git commit -m "$INPUT_COMMIT_MESSAGE" --author="$GITHUB_ACTOR <$GITHUB_ACTOR@users.noreply.github.com>" ${INPUT_COMMIT_OPTIONS:+"$INPUT_COMMIT_OPTIONS"}
    git push origin
    echo "Changes pushed successfully."
  fi
else
  echo "Nothing to commit. Exiting."
fi
