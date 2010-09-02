#!/bin/sh

PROJECT_ROOT=/path/to/project
HOYADIR=/path/to/Hoya
HOST=localhost
ENABLE_LOGGER=1


SITE_NAME=$1
SERVER_PORT=$2

PERL_VER=`env perl -e 'print "5." . join ".", map int($_), ($] =~ /(\d{3})(\d{3})$/);'`
echo "PERL_VER:    [32m$PERL_VER[m"

PLACK_ENV=development
CH1=`echo $SITE_NAME | cut -c1`
if [ "$CH1" = "+" ]; then
    PLACK_ENV=deployment
    SITE_NAME=`echo $SITE_NAME | cut -c2-`
fi
echo "PLACK_ENV:   [32m$PLACK_ENV[m"

if [ "$SITE_NAME" =  "" ]; then
    echo "[31m\$SITE_NAME is not specified. Set to 'default'.[m"
    SITE_NAME=default
    PSGI_FILE=${PROJECT_ROOT}/www/${SITE_NAME}.psgi
fi
echo "SITE_NAME:   [32m$SITE_NAME[m"

PSGI_FILE=${PROJECT_ROOT}/www/${SITE_NAME}.psgi
if [ ! -f $PSGI_FILE ]; then
    echo "[31mPSGI_FILE does not exist: ${PSGI_FILE}[m"
    exit 1
fi

if [ ! $SERVER_PORT ]; then
    echo "[31m\$SERVER_PORT is not specified. Set to '5000'.[m"
    SERVER_PORT=5000
fi

echo "SERVER_PORT: [32m$SERVER_PORT[m"
echo "SERVER_USER: [32m$USER[m"
echo "PSGI_FILE:   [32m$PSGI_FILE[m"

exec 2>&1
  cd $PROJECT_ROOT || exit 1
exec 2>&1 \
  env \
    HOYA_PROJECT_ROOT=${PROJECT_ROOT} \
    HOYA_SITE=${SITE_NAME} \
    HOYA_ENABLE_LOGGER=${ENABLE_LOGGER} \
  plackup \
    -E $PLACK_ENV \
    -R www,pl,lib,conf,$HOYADIR/lib,$HOYADIR/extlib \
    -s HTTP::Server::PSGI \
    --host=$HOST \
    --port=$SERVER_PORT \
    -I $HOYADIR/lib \
    -I $HOYADIR/extlib \
    -I lib \
  $PSGI_FILE

#    -I $HOME/local/lib/site_perl/$PERL_VER/darwin-2level \
#    --max-workers 16 \
#    --max-workers 32 \
#    -s HTTP::Server::PSGI \
#    -s Starman \
#    --socket=/tmp/plack-netps.sock \
#    --host=$HOST \
