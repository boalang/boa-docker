#!/bin/bash

cd /compiler

PROJECT="apache/rocketmq"
PROJID="75164823"

# dont change below
OUTPUTDIR="dataset-new"

JSONDIR="$OUTPUTDIR/json"
REPODIR="$OUTPUTDIR/git"
OUTDIR="$OUTPUTDIR/ds"

IDPREFIX="${PROJID:0:1}/${PROJID:1:1}"

changed="0"

if [ ! -f $JSONDIR/$IDPREFIX/$PROJID.json ] ; then
    mkdir -p $JSONDIR/$IDPREFIX
    /bin/echo -n "[" > $JSONDIR/$IDPREFIX/$PROJID.json
    wget -qO - "https://api.github.com/repos/$PROJECT" >> $JSONDIR/$IDPREFIX/$PROJID.json
    echo "]" >> $JSONDIR/$IDPREFIX/$PROJID.json
fi

if [ ! -f $REPODIR/$IDPREFIX/$PROJID/HEAD ] ; then
    mkdir -p $REPODIR/$IDPREFIX
    git clone --bare https://github.com/$PROJECT.git $REPODIR/$IDPREFIX/$PROJID
    changed="1"
else
    pushd .
    cd $REPODIR/$IDPREFIX/$PROJID
    HEAD=`cut -d' ' -f2 HEAD`
    if [ -f $HEAD ] ; then
        oldref=`cat refs/heads/main`
    else
        oldref=`grep "$HEAD" packed-refs`
    fi
    git fetch
    if [ -f $HEAD ] ; then
        newref=`cat refs/heads/main`
    else
        newref=`grep "$HEAD" packed-refs`
    fi
    popd
    if [[ "$newref" != "$oldref" ]] ; then
        changed="1"
    fi
fi

if [[ "$changed" == "1" ]] ; then
    rm -Rf $OUTDIR
    ./boa.sh -g -inputJson $JSONDIR -inputRepo $REPODIR -output $OUTDIR -debug
    echo "dataset was rebuilt - you need to reinstall it into HDFS. Run 'dataset-install.sh' next."
fi
