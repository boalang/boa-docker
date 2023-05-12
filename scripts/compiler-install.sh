#!/bin/bash

if [ "$1" = "" ]; then
    echo "usage: $0 <compiler name>"
    exit
fi

DEST=/home/hadoop/compiler/$1/dist/

ant clean
ant

mkdir -p $DEST
cp dist/*.jar $DEST
