# GitHub Prettier Action

[![CodeFactor](https://www.codefactor.io/repository/github/creyd/prettier_action/badge/master)](https://www.codefactor.io/repository/github/creyd/prettier_action/overview/master)
[![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg?style=flat-square)](https://github.com/prettier/prettier)

A GitHub action for styling files with [prettier](https://prettier.io).

## Usage

### Parameters

| Parameter | Required | Default | Description |
| - | :-: | :-: | - |
| dry | :x: | False | Runs the action in dry mode. Files wont get changed and the action fails if there are unprettified files. |
| prettier_options | :x: | `--write **/*.js` | Prettier options (by default it applies to the whole repository) |
| commit_options | :x: | - | Custom git commit options |
| commit_message | :x: | Prettified Code! | Custom git commit message |
| file_pattern | :x: | * | Custom git add file pattern |
| branch | :white_check_mark: | - | There are two types of action triggers in GitHub: on pull request and on push. The branch needs to be defined for both, but in case of the pull request trigger it should have `${{ github.head_ref }}` and on push it should have the branch the trigger is designed for. |

### Example Config

#### Example - On Pull Request

This is a small example of what your `action.yml` could look like (on pull request mode):

```yaml
name: Prettier for JS Code

on: [pull_request]

jobs:
  cleanup_tasks:
    runs-on: ubuntu-latest

    steps:
    - name: Cloning the repository
      uses: actions/checkout@v1
      with:
        fetch-depth: 1
    - name: Prettify the JS Code
      uses: creyD/prettier_action@v2.1
      with:
        prettier_options: '--no-semi --write *.js'
        branch: ${{ github.head_ref }}
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Example - On Push

```yaml
name: Prettier for JS Code

on:
  push:
    branches: [master]

jobs:
  cleanup_tasks:
    runs-on: ubuntu-latest

    steps:
    - name: Cloning the repository
      uses: actions/checkout@v1
      with:
        fetch-depth: 1
    - name: Prettify the JS Code
      uses: creyD/prettier_action@v2.1
      with:
        prettier_options: '--no-semi --write *.js'
        branch: master
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

More documentation for writing a workflow can be found [here](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions).

## Issues

Please report all bugs and feature request using the [GitHub issues function](https://github.com/creyD/prettier_action/issues/new). Thanks!
