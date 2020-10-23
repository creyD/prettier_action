# GitHub Prettier Action

[![CodeFactor](https://www.codefactor.io/repository/github/creyd/prettier_action/badge/master)](https://www.codefactor.io/repository/github/creyd/prettier_action/overview/master)
[![code style: prettier](https://img.shields.io/badge/code_style-prettier-ff69b4.svg?style=flat-square)](https://github.com/prettier/prettier)
[![License MIT](https://img.shields.io/github/license/creyD/prettier_action)](https://github.com/creyD/prettier_action/blob/master/LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/creyD/prettier_action)](https://github.com/creyD/prettier_action/releases)
[![Contributors](https://img.shields.io/github/contributors-anon/creyD/prettier_action)](https://github.com/creyD/prettier_action/graphs/contributors)
[![Issues](https://img.shields.io/github/issues/creyD/prettier_action)](https://github.com/creyD/prettier_action/issues)


A GitHub action for styling files with [prettier](https://prettier.io).

## Usage

### Parameters

| Parameter | Required | Default | Description |
| - | :-: | :-: | - |
| dry | :x: | `false` | Runs the action in dry mode. Files wont get changed and the action fails if there are unprettified files. |
| prettier_version | :x: | `false` | Specific prettier version (by default use latest) |
| prettier_options | :x: | `"--write **/*.js"` | Prettier options (by default it applies to the whole repository) |
| commit_options | :x: | - | Custom git commit options |
| same_commit | :x: | `false` | Update the current commit instead of creating a new one, created by [Joren Broekema](https://github.com/jorenbroekema), this command works only with the checkout action set to fetch depth '0' (see example 2)  |
| commit_message | :x: | `"Prettified Code!"` | Custom git commit message, will be ignored if used with `same_commit` |
| file_pattern | :x: | `*` | Custom git add file pattern, can't be used with only_changed! |
| branch (depreciated with 3.0)| :white_check_mark: | - | Always set this to `${{ github.head_ref }}` in order to work both with pull requests and push events |
| only_changed | :x: | `false` | Only prettify changed files, can't be used with file_pattern! This command works only with the checkout action set to fetch depth '0' (see example 2)|

> Note: using the same_commit option may lead to problems if other actions are relying on the commit being the same before and after the prettier action has ran. Keep this in mind.

### Example Config

#### Example 1 (run on push in master)
```yaml
name: Continuous Integration

# This action works with pull requests and pushes
on:
  pull_request:
  push:
    branches:
    - master

jobs:
  prettier:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v2
      with:
        # Make sure the actual branch is checked out when running on pull requests
        ref: ${{ github.head_ref }}

    - name: Prettify code
      uses: creyD/prettier_action@v3.0
      with:
        # This part is also where you can pass other options, for example:
        prettier_options: --write **/*.{js,md}
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

#### Example 2 (using the only_changed or same_commit option on PR)
```yaml
name: Continuous Integration

on:
  pull_request:
    branches: [master]

jobs:
  prettier:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout
      uses: actions/checkout@v2
      with:
        # Make sure the actual branch is checked out when running on pull requests
        ref: ${{ github.head_ref }}
        # This is important to fetch the changes to the previous commit
        fetch-depth: 0

    - name: Prettify code
      uses: creyD/prettier_action@v3.0
      with:
        # This part is also where you can pass other options, for example:
        prettier_options: --write **/*.{js,md}
        only_changed: True
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

More documentation for writing a workflow can be found [here](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions).

## Issues

Please report all bugs and feature request using the [GitHub issues function](https://github.com/creyD/prettier_action/issues/new). Thanks!
