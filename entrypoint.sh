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

    git config --global user.email "actions@github.com"
    git config --global user.name "GitHub Action"
}

# Checks if any files are changed
_git_changed() {
    [[ -n "$(git status -s)" ]]
}

_git_changes() {
    git diff
}

(
# PROGRAM
# Changing to the directory
cd "$GITHUB_ACTION_PATH"

echo "Installing prettier..."

case $INPUT_WORKING_DIRECTORY in
    false)
        ;;
    *)
        cd $INPUT_WORKING_DIRECTORY
        ;;
esac

case $INPUT_PRETTIER_VERSION in
    false)
        npm install --silent prettier
        ;;
    *)
        npm install --silent prettier@$INPUT_PRETTIER_VERSION
        ;;
esac

# Install plugins
if [ -n "$INPUT_PRETTIER_PLUGINS" ]; then
    for plugin in $INPUT_PRETTIER_PLUGINS; do
        echo "Checking plugin: $plugin"
        # check regex against @prettier/xyz
        if ! echo "$plugin" | grep -Eq '(@prettier\/)+(plugin-[a-z\-]+)'; then
            echo "$plugin does not seem to be a valid @prettier/plugin-x plugin. Exiting."
            exit 1
        fi
    done
    npm install --silent --global $INPUT_PRETTIER_PLUGINS
fi
)

PRETTIER_RESULT=0
echo "Prettifying files..."
echo "Files:"
prettier $INPUT_PRETTIER_OPTIONS \
  || { PRETTIER_RESULT=$?; echo "Problem running prettier with $INPUT_PRETTIER_OPTIONS"; exit 1; }

# Ignore node modules and other action created files
if [ -d 'node_modules' ]; then
  rm -r node_modules/
else
  echo "No node_modules/ folder."
fi

if [ -f 'package-lock.json' ]; then
  git checkout -- package-lock.json
else
  echo "No package-lock.json file."
fi

# To keep runtime good, just continue if something was changed
if _git_changed; then
  # case when --write is used with dry-run so if something is unpretty there will always have _git_changed
  if $INPUT_DRY; then
    echo "Unpretty Files Changes:"
    _git_changes
    echo "Finishing dry-run. Exiting before committing."
    exit 1
  else
    # Calling method to configure the git environemnt
    _git_setup

    if $INPUT_ONLY_CHANGED; then
      # --diff-filter=d excludes deleted files
      OLDIFS="$IFS"
      IFS=$'\n'
      for file in $(git diff --name-only --diff-filter=d HEAD^..HEAD)
      do
        git add "$file"
      done
      IFS="$OLDIFS"
    else
      # Add changes to git
      git add "${INPUT_FILE_PATTERN}" || echo "Problem adding your files with pattern ${INPUT_FILE_PATTERN}"
    fi

    # Commit and push changes back
    if $INPUT_SAME_COMMIT; then
      echo "Amending the current commit..."
      git pull
      git commit --amend --no-edit
      git push origin -f
    else
      if [ "$INPUT_COMMIT_DESCRIPTION" != "" ]
      then
          git commit -m "$INPUT_COMMIT_MESSAGE" -m $INPUT_COMMIT_DESCRIPTION --author="$GITHUB_ACTOR <$GITHUB_ACTOR@users.noreply.github.com>" ${INPUT_COMMIT_OPTIONS:+"$INPUT_COMMIT_OPTIONS"} || echo "No files added to commit"
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
