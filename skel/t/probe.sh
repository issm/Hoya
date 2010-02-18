#!/bin/sh
export HOYA_EXEC_ROOT=<?=$ROOTDIR;?>
export PERL5LIB=$HOYA_EXEC_ROOT/saba/lib:$HOYA_EXEC_ROOT/saba/extlib:$PERL5LIB

echo \$HOYA_EXEC_ROOT: $HOYA_EXEC_ROOT
echo \$PERL5LIB:       $PERL5LIB

echo Entering $HOYA_EXEC_ROOT
cd $HOYA_EXEC_ROOT
prove t/*.t t/*/*.t

echo
