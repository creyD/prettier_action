# GitHub Prettier Action

A GitHub action for styling files with [prettier](prettier.io).

## Usage

### Parameters

| Parameter | Required | Default | Description |
| - | - | - | - |
| prettier_options | :white_check_mark: | - | Prettier options |
| commit_options | :x: | - | Custom git commit options |
| commit_message | :x: | 'Prettified Code!' | Custom git commit message |
| file_pattern | :x: | '*' | Custom git add file pattern |
| branch | :white_check_mark: | - | Custom git publish branch, use ${{ github.head_ref }} if used in pull requests |

### Example Config

This is a small example of what your `action.yml` could look like:

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
      uses: creyD/prettier_action@v1.0
      with:
        prettier_options: '--no-semi --write src/**/*.js'
        branch: ${{ github.head_ref }}
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

This simple example executes `prettier --no-semi --write src/**/*.js` after someone created a Pull Request on your repository. More documentation can be found [here](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions).

## Issues

Please report all bugs and feature request using the [GitHub issues function](https://github.com/creyD/prettier_action/issues/new).
