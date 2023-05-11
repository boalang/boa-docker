#!/bin/bash

cd /compiler

PROJECTS=( "apache/rocketmq" "apache/logging-log4j1" )

# dont change below
OUTPUTDIR="dataset-new"

JSONDIR="$OUTPUTDIR/json"
REPODIR="$OUTPUTDIR/git"
OUTDIR="$OUTPUTDIR/ds"

changed="0"

for i in "${!PROJECTS[@]}"; do
    PROJECT=${PROJECTS[i]}
    PROJID=`wget -qO - "https://api.github.com/repos/$PROJECT" | jq '.id'`

    echo "========================="
    echo "updating $PROJECT ($PROJID)..."
    echo "========================="

    IDPREFIX="${PROJID:0:1}/${PROJID:1:1}"

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
        pushd . > /dev/null
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
        popd > /dev/null
        if [[ "$newref" != "$oldref" ]] ; then
            changed="1"
        fi
    fi
done

if [[ "$changed" == "1" ]] ; then
    rm -Rf $OUTDIR
    ./boa.sh -g -skip 0 -inputJson $JSONDIR -inputRepo $REPODIR -output $OUTDIR -debug
    echo ""
    echo "dataset was rebuilt - you need to reinstall it into HDFS. Run 'dataset-install.sh' next."
else
    echo ""
    echo "dataset was not updated - none of the input projects changed"
fi
