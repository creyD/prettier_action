#!/bin/bash
# e is for exiting the script automatically if a command fails, u is for exiting if a variable is not set
# x would be for showing the commands before they are executed
set -eu
shopt -s globstar

# FUNCTIONS
# Function for setting up git env in the docker container (copied from https://github.com/stefanzweifel/git-auto-commit-action/blob/master/entrypoint.sh)
_git_setup ( ) {
    cat <<- EOF > $HOME/.netrc
      machine github.com
      login $GITHUB_ACTOR
      password $INPUT_GITHUB_TOKEN
      machine api.github.com
      login $GITHUB_ACTOR
      password $INPUT_GITHUB_TOKEN
EOF
    chmod 600 $HOME/.netrc

    # If GIT_IDENTITY="actor"
    if [ "$INPUT_GIT_IDENTITY" = "author" ]; then
      git config --global user.name "$GITHUB_ACTOR"
      git config --global user.email "$GITHUB_ACTOR@@users.noreply.github.com"
    elif [ "$INPUT_GIT_IDENTITY" = "actions" ]; then
      git config --global user.email "actions@github.com"
      git config --global user.name "GitHub Action"
    else
      echo "GIT_IDENTITY must be either 'actor' or 'actions'";
      exit 1;
    fi;
}

# Checks if any files are changed
_git_changed() {
    [[ -n "$(git status -s)" ]]
}

(
# PROGRAM
# Changing to the directory
cd "$INPUT_WORKING_DIRECTORY"

echo "Installing prettier..."

npm install --silent prettier@$INPUT_PRETTIER_VERSION

# Install plugins
if [ -n "$INPUT_PRETTIER_PLUGINS" ]; then
    for plugin in $INPUT_PRETTIER_PLUGINS; do
        echo "Checking plugin: $plugin"
        # check regex against @prettier/xyz
        if ! echo "$plugin" | grep -Eq '(@prettier\/plugin-|(@[a-z\-]+\/)?prettier-plugin-){1}([a-z\-]+)'; then
            echo "$plugin does not seem to be a valid @prettier/plugin-x plugin. Exiting."
            exit 1
        fi
    done
    npm install --silent $INPUT_PRETTIER_PLUGINS
fi
)

PRETTIER_RESULT=0
echo "Prettifying files..."
echo "Files:"
prettier $INPUT_PRETTIER_OPTIONS \
  || { PRETTIER_RESULT=$?; echo "Problem running prettier with $INPUT_PRETTIER_OPTIONS"; exit 1; } >> $GITHUB_STEP_SUMMARY

echo "Prettier result: $PRETTIER_RESULT"

# Removing the node_modules folder, so it doesn't get committed if it is not added in gitignore
if $INPUT_CLEAN_NODE_FOLDER; then
  echo "Deleting node_modules/ folder..."
  if [ -d 'node_modules' ]; then
    rm -r node_modules/
  else
    echo "No node_modules/ folder."
  fi
fi

if [ -f 'package-lock.json' ]; then
  git checkout -- package-lock.json || echo "No package-lock.json file tracked by git."
else
  echo "No package-lock.json file."
fi

# If running under only_changed, reset every modified file that wasn't also modified in the last commit
# This allows only_changed and dry to work together, and simplified the non-dry logic below
if $INPUT_ONLY_CHANGED; then
  # list of all files changed in the previous commit
  git diff --name-only HEAD HEAD~1 > /tmp/prev.txt
  # list of all files with outstanding changes
  git diff --name-only HEAD > /tmp/cur.txt

  OLDIFS="$IFS"
  IFS=$'\n'
  # get all files that are in prev.txt that aren't also in cur.txt
  for file in $(comm -1 -3 /tmp/prev.txt /tmp/cur.txt)
  do
    echo "resetting: $file"
    git restore -- "$file"
  done
  IFS="$OLDIFS"
fi

# To keep runtime good, just continue if something was changed
if _git_changed; then
  # case when --write is used with dry-run so if something is unpretty there will always have _git_changed
  if $INPUT_DRY; then
    echo "Unpretty Files Changes:"
    git diff
    if $INPUT_NO_COMMIT; then
        echo "There are changes that won't be commited, you can use an external job to do so."
    else
        echo "Finishing dry-run. Exiting before committing."
        exit 1
    fi
  else
    # Calling method to configure the git environemnt
    _git_setup

    # Add changes to git
    git add "${INPUT_FILE_PATTERN}" || echo "Problem adding your files with pattern ${INPUT_FILE_PATTERN}"


    if $INPUT_NO_COMMIT; then
      echo "There are changes that won't be commited, you can use an external job to do so."
      exit 0
    fi

    # Commit and push changes back
    if $INPUT_SAME_COMMIT; then
      echo "Amending the current commit..."
      git pull
      git commit --amend --no-edit --allow-empty
      git push origin -f
    else
      if [ "$INPUT_COMMIT_DESCRIPTION" != "" ]; then
          git commit -m "$INPUT_COMMIT_MESSAGE" -m "$INPUT_COMMIT_DESCRIPTION" --author="$GITHUB_ACTOR <$GITHUB_ACTOR@users.noreply.github.com>" ${INPUT_COMMIT_OPTIONS:+"$INPUT_COMMIT_OPTIONS"} || echo "No files added to commit"
      else
          git commit -m "$INPUT_COMMIT_MESSAGE" --author="$GITHUB_ACTOR <$GITHUB_ACTOR@users.noreply.github.com>" ${INPUT_COMMIT_OPTIONS:+"$INPUT_COMMIT_OPTIONS"} || echo "No files added to commit"
      fi
      git push origin ${INPUT_PUSH_OPTIONS:-}
    fi
    echo "Changes pushed successfully."
  fi
else
  # case when --check is used so there will never have something to commit but there are unpretty files
  if [ "$PRETTIER_RESULT" -eq 1 ]; then
    echo "Prettier found unpretty files!"
    exit 1
  else
    echo "Finishing dry-run."
  fi
  echo "No unpretty files!"
  echo "Nothing to commit. Exiting."
fi
