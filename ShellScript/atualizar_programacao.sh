#!/bin/bash

# Recupera data referente ao dia anterior
# https://unix.stackexchange.com/questions/48101/how-can-i-have-date-output-the-time-from-a-different-timezone
DATA=`TZ=EST+24 date +%Y-%m-%d`
DE="lastExecution=\"\d{4}\-\d{2}\-\d{2}"
PARA="lastExecution=\"${DATA}"

# substitui os valores de acordo com DE-PARA
function substituir {
    perl -pi -e s/$DE/$PARA/g $1
}

# percorre os parâmetros informados
for arquivo in "$@"
do
    substituir $arquivo
done