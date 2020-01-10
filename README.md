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

## Issues

Please report all bugs and feature request using the [GitHub issues function](https://github.com/creyD/prettier_action/issues/new).
