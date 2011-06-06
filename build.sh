#!/bin/bash
SRC_PATH=src
PYTHON=python
ENDPYTHON=END_PYTHON
PYTHON_FILES=(slem.py ui.py)
VIM_FILES=(slem.vi_ bindings.vi_)
VIM_PYTHON_BEGIN=python
VIM_PYTHON_END=EOL
OUT_FILE=$1

echo "$PYTHON << $ENDPYTHON" > $OUT_FILE
grep -h ^import ${PYTHON_FILES[@]/#/$SRC_PATH/} | sort | uniq >> $OUT_FILE

for FILE in ${PYTHON_FILES[@]}
do
    grep -hv ^import $SRC_PATH/$FILE >> $OUT_FILE
done
echo $ENDPYTHON >> $OUT_FILE

for FILE in ${VIM_FILES[@]}
do
    sed -e "s/$VIM_PYTHON_BEGIN/$PYTHON/" \
        -e "s/$VIM_PYTHON_END/$ENDPYTHON/" \
        <$SRC_PATH/$FILE >> $OUT_FILE
done
