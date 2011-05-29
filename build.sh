#!/bin/bash
SRC_PATH=src
PYTHON=python
ENDPYTHON=END_PYTHON
PYTHON_FILES=(slem.py)
VIM_FILES=(slem.vi_ bindings.vi_)
OUT_FILE=$1

echo "$PYTHON << $ENDPYTHON" > $OUT_FILE
for FILE in ${PYTHON_FILES[@]}
do
    cat $SRC_PATH/$FILE >> $OUT_FILE
done
echo $ENDPYTHON >> $OUT_FILE

for FILE in ${VIM_FILES[@]}
do
    cat $SRC_PATH/$FILE >> $OUT_FILE
done
