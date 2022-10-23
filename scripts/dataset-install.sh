#!/bin/bash

if [ "$1" = "" ]; then
    echo "usage: $0 <dataset name>"
    exit
fi

DSNAME=$1

cd /compiler/dataset-new/ds

~hadoop/hadoop-current/bin/hadoop dfs -rmr /repcache/$DSNAME 2>/dev/null

~hadoop/hadoop-current/bin/hadoop dfs -mkdir /repcache/$DSNAME 2>/dev/null

~hadoop/hadoop-current/bin/hadoop dfs -put projects.seq /repcache/$DSNAME/projects.seq 2>/dev/null

~hadoop/hadoop-current/bin/hadoop dfs -mkdir /repcache/$DSNAME/commit 2>/dev/null
~hadoop/hadoop-current/bin/hadoop dfs -put commit/index /repcache/$DSNAME/commit/index 2>/dev/null
~hadoop/hadoop-current/bin/hadoop dfs -put commit/data /repcache/$DSNAME/commit/data 2>/dev/null

~hadoop/hadoop-current/bin/hadoop dfs -mkdir /repcache/$DSNAME/ast 2>/dev/null
~hadoop/hadoop-current/bin/hadoop dfs -put ast/index /repcache/$DSNAME/ast/index 2>/dev/null
~hadoop/hadoop-current/bin/hadoop dfs -put ast/data /repcache/$DSNAME/ast/data 2>/dev/null

echo "dataset installed into HDFS - be sure to add the dataset in the Drupal admin!"
