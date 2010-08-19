#!/bin/zsh

OPTION=$1

HOYA_PROJECT_ROOT=/path/to/project_root
HOYA_ROOT=/path/to/hoya

HOYA_SITE=default
HOYA_SKIN=default

cd $HOYA_PROJECT_ROOT

env \
HOYA_PROJECT_ROOT=$HOYA_PROJECT_ROOT \
HOYA_ROOT=$HOYA_ROOT \
HOYA_SITE=$HOYA_SITE \
HOYA_SKIN=$HOYA_SKIN \
perl $OPTION $HOYA_PROJECT_ROOT/script/script.pl
