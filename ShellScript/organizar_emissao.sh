#!/bin/bash

# Constantes de erro
readonly ERR_DIRETORIO_INVALIDO=2
readonly ERR_PARAMETRO_INVALIDO=3
readonly ERR_PARAMETRO_INEXISTENTE=4
readonly ERR_OPERACAO_INVALIDA=5

# Variáveis
DIR_BACKUP=
DIR_ORIGEM=

function ajuda() {
  echo "NOME"
  echo  " ${0} - realiza a organização de XMLs emitidos de NF-es"
  echo -e "\nSINOPSE"
  echo "  ${0} [-h] -o diretório -b diretório"
  echo -e "\nDESCRIÇÃO"
  echo "  Move os arquivos XMLs para o diretório de backup"
  echo -e "\nOPÇÕES"
  echo "  -h  (opcional) exibe a ajuda do comando"
  echo "  -o  diretório de origem"
  echo "  -b  diretório de backup dos arquivos XMLs de NF-es"
  echo -e "\nAUTOR"
  echo "  Mateus Alexandre"
}

function verificar_parametros() {
  # Verifica se não foi informado nenhum parâmetro
  if [ $# -eq 0 ] ;
  then
    ajuda
    exit 0
  fi

  # Trata os parâmetros informados
  while getopts "o:b:h" PARAMETRO;
  do
    case ${PARAMETRO} in
      o)
        # Parâmetro do diretório de origem
        # Verifica se diretório já foi informado
        if [ ! -z "${DIR_ORIGEM}" ] ;
        then
          echo "O parâmetro -${PARAMETRO} foi utilizado mais de uma vez."
          exit ${ERR_PARAMETRO_INVALIDO}
        fi
        # Verifica se o diretório existe
        DIR_ORIGEM=$(readlink -f ${OPTARG})
        if [ ! -d ${DIR_ORIGEM} ] ;
        then
          echo "Diretório inválido para o parâmetro -${PARAMETRO}."
          exit ${ERR_DIRETORIO_INVALIDO}
        fi
        ;;
      b)
        # Parâmetro do diretório de backup
        # Verifica se diretório já foi informado
        if [ ! -z "${DIR_BACKUP}" ] ;
        then
          echo "O parâmetro -${PARAMETRO} foi utilizado mais de uma vez."
          exit ${ERR_PARAMETRO_INVALIDO}
        fi
        # Verifica se o diretório existe
        DIR_BACKUP=$(readlink -f ${OPTARG})
        if [ ! -d ${DIR_BACKUP} ] ;
        then
          echo "Diretório inválido para o parâmetro -${PARAMETRO}."
          exit ${ERR_DIRETORIO_INVALIDO}
        fi
        ;;
      h)
        # Parâmetro de ajuda
        ajuda
        exit 0
        ;;
      *)
        # Outros parâmetros
        echo ""
        ajuda
        exit ${ERR_PARAMETRO_INVALIDO}
        ;;
    esac
  done
}

function validar_parametros() {
  # Verifica se o diretório de origem foi informado
  if [ -z "${DIR_ORIGEM}" ] ;
  then
    echo "O diretório de origem deve ser informado."
    exit ${ERR_PARAMETRO_INEXISTENTE}
  fi

  # Verifica se o diretório de backup foi informado
  if [ -z "${DIR_BACKUP}" ] ;
  then
    echo "O diretório de backup deve ser informado."
    exit ${ERR_PARAMETRO_INEXISTENTE}
  fi

  # Verifica se o diretório de backup é igual ao de origem
  if [ "${DIR_ORIGEM}" = "${DIR_BACKUP}" ] ;
  then
    echo "O diretório de backup não deve ser igual ao de origem."
    exit ${ERR_OPERACAO_INVALIDA}
  fi
}

function processar_arquivos(){
  # Nomes dos diretórios
  local DIR_BKP_NFE=
  local ANO_MES=
  local CNPJ=
  local PADRAO="[nN][fF][eE]_[0-9][0-9]*.[xX][mM][lL]"

  for ARQUIVO_NFE in $(find ${DIR_ORIGEM} -maxdepth 1 -name ${PADRAO} -type f) ;
  do
    # Montagem do diretório de backup
    ANO_MES=$(echo "$(basename ${ARQUIVO_NFE})" \
                      | awk '{ print substr($1, 7, 4) }')
    CNPJ=$(echo "$(basename ${ARQUIVO_NFE})" \
                  | awk '{ print substr($1, 11, 14) }')
    DIR_BKP_NFE=${DIR_BACKUP}/Emissao/NFE/${ANO_MES}/${CNPJ}

    # Cria diretório se não existir
    test -d ${DIR_BKP_NFE} || mkdir -p ${DIR_BKP_NFE}

    # Move arquivo xml para o diretório de backup
    mv -t ${DIR_BKP_NFE} "${ARQUIVO_NFE}"
  done
}

# Altera o Internal Field Separator para considerar somente quebra de linha
IFS=$'\n'

verificar_parametros $@
validar_parametros
processar_arquivos
