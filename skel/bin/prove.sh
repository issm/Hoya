#!/bin/sh

HOYA_ROOT=/pash/to/Hoya

HOYA_SITE=default
HOYA_SKIN=default

HOYA_PROJECT_ROOT=$(cd $(dirname $0)/../ && pwd)
PERL5LIB=$HOYA_PROJECT_ROOT/t:$HOYA_PROJECT_ROOT/lib:$HOYA_ROOT/lib:$HOYA_ROOT/extlib:$PERL5LIB

echo \$HOYA_ROOT: [32m$HOYA_ROOT[m
echo \$PERL5LIB:  [32m$PERL5LIB[m

echo Entering $HOYA_PROJECT_ROOT
cd $HOYA_PROJECT_ROOT

if [ $1 -a -e $1 ]
then
    PROVE_TARGET=$1
else
    PROVE_TARGET="t/*.t t/*/*.t"
fi


HOYA_PROJECT_TEST=1 \
HOYA_ROOT=$HOYA_ROOT \
HOYA_PROJECT_ROOT=$HOYA_PROJECT_ROOT \
HOYA_SITE=$HOYA_SITE \
HOYA_SKIN=$HOYA_SKIN \
PERL5LIB=$PERL5LIB \
prove $PROVE_TARGET

echo