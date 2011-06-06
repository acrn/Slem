#!/bin/bash
SRC_PATH=src
PYTHON=python
ENDPYTHON=END_PYTHON
PYTHON_FILES=(slem.py ui.py)
VIM_FILES=(slem.vi_ bindings.vi_)
OUT_FILE=$1

echo "$PYTHON << $ENDPYTHON" > $OUT_FILE
grep -h import ${PYTHON_FILES[@]/#/$SRC_PATH/} | sort | uniq >> $OUT_FILE

for FILE in ${PYTHON_FILES[@]}
do
    grep -hv ^import $SRC_PATH/$FILE >> $OUT_FILE
done
echo $ENDPYTHON >> $OUT_FILE

for FILE in ${VIM_FILES[@]}
do
    cat $SRC_PATH/$FILE >> $OUT_FILE
done
