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

# Pushes to the according upstream (origin or input branch)
_git_push() {
    if [ -z "$INPUT_BRANCH" ]
    then
        git push origin
    else
        git push --set-upstream origin "HEAD:$INPUT_BRANCH"
    fi
}

# PROGRAM
echo "Installing prettier..."
if $INPUT_PRETTIER_VERSION; then
  npm install --silent --global prettier@$INPUT_PRETTIER_VERSION
else
  npm install --silent --global prettier
fi

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
    # Switch to the actual branch
    git checkout $INPUT_BRANCH || echo "Problem checking out the specified branch: $INPUT_BRANCH"
    # Add changes to git
    git add "${INPUT_FILE_PATTERN}" || echo "Problem adding your files with pattern ${INPUT_FILE_PATTERN}"
    # Commit and push changes back
    git commit -m "$INPUT_COMMIT_MESSAGE" --author="$GITHUB_ACTOR <$GITHUB_ACTOR@users.noreply.github.com>" ${INPUT_COMMIT_OPTIONS:+"$INPUT_COMMIT_OPTIONS"}
    _git_push
    echo "Changes pushed successfully."
  fi
else
  echo "Nothing to commit. Exiting."
fi
