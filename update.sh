#!/bin/zsh

set -e # exit on first error

git checkout master && git pull upstream master && git push && git checkout ktj/v1.1 && git rebase master && git push --force-with-lease
