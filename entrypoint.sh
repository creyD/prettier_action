#!/bin/sh
# e is for exiting the script automatically if a command fails, u is for exiting if a variable is not set, x is for showing the commands before they are executed
set -eux

# Function for setting up git env in the docker container (copied from https://github.com/stefanzweifel/git-auto-commit-action/blob/master/entrypoint.sh)
git_setup ( ) {
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
    git config --global user.name "GitHub Actions"
}

echo "Installing prettier..."
npm install --silent --global prettier
echo "Prettifing files..."
prettier $INPUT_PRETTIER_OPTIONS || echo "Problem while prettifying your files!"

if ! git diff --quiet
then
  echo "Commiting and pushing changes..."
  # Calling method to configure the git environemnt
  git_setup
  # Switch to the actual branch
  git checkout $INPUT_BRANCH
  # Add changes to git
  git add "${INPUT_FILE_PATTERN}"
  # Commit and push changes back
  git commit -m "$INPUT_COMMIT_MESSAGE" --author="$GITHUB_ACTOR <$GITHUB_ACTOR@users.noreply.github.com>" ${INPUT_COMMIT_OPTIONS:+"$INPUT_COMMIT_OPTIONS"}
  git push --set-upstream origin "HEAD:$INPUT_BRANCH"
  echo "Changes pushed successfully."
else
  echo "Nothing to commit. Exiting."
fi
