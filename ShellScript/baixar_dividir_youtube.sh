#!/bin/bash

URL_VIDEO=$1
DURACAO_PARTE=$2
if [ -z $DURACAO_PARTE ]; then
    DURACAO_PARTE=30
fi

function verificar_requisitos() {
    youtube-dl --version &>/dev/null
    RESULTADO=$(echo $?)
    if [ $RESULTADO -ne 0 ]; then
        echo "É necessário ter o youtube-dl instalado."
        exit
    fi

    ffmpeg -version &>/dev/null
    RESULTADO=$(echo $?)
    if [ $RESULTADO -ne 0 ]; then
        echo "É necessário ter o ffmpeg instalado."
        exit
    fi
}

function baixar_video() {
    if [ ! -d ./output ]; then
        mkdir output
    fi

    youtube-dl -q -o './output/%(id)s_%(duration)06d.%(ext)s' -f best $URL_VIDEO
}

function dividir_video() {
    ID_VIDEO=$(youtube-dl --get-id $URL_VIDEO)
    NOME_ARQUIVO_COMPLETO=$(ls ./output/${ID_VIDEO}_[0-9]*)
    DURACAO_TOTAL=$(expr $(echo $NOME_ARQUIVO_COMPLETO | cut -d"_" -f2 | cut -d"." -f1) + 0)
    EXTENSAO=$(echo $NOME_ARQUIVO_COMPLETO | cut -d"_" -f2 | cut -d"." -f2)
    DURACAO_RESTANTE=$DURACAO_TOTAL

    while [ $DURACAO_RESTANTE -gt 0 ]; do
        TEMPO_INICIAL=$(($DURACAO_TOTAL - $DURACAO_RESTANTE))
        DURACAO_RESTANTE=$(($DURACAO_RESTANTE - $DURACAO_PARTE))

        if [ $DURACAO_RESTANTE -gt 0 ]; then
            DURACAO=$DURACAO_PARTE
        else
            DURACAO=$(($DURACAO_PARTE + $DURACAO_RESTANTE))
        fi

        NOME_ARQUIVO_FINAL=./output/${ID_VIDEO}_parte_$(printf "%06d" $TEMPO_INICIAL).${EXTENSAO}
        ffmpeg -hide_banner -loglevel panic \
            -i $NOME_ARQUIVO_COMPLETO \
            -ss $TEMPO_INICIAL \
            -t $DURACAO \
            -y \
            -vcodec copy -acodec copy \
            $NOME_ARQUIVO_FINAL
    done
}

verificar_requisitos
baixar_video
dividir_video
