#!/bin/bash

# Constantes de erro
readonly ERR_DIRETORIO_INVALIDO=2
readonly ERR_PARAMETRO_INVALIDO=3
readonly ERR_PARAMETRO_INEXISTENTE=4
readonly ERR_OPERACAO_INVALIDA=5

# Variáveis
ANO=$(date '+%y')
ANO_ANTERIOR=$[${ANO} - 1]
DATA=$(date '+%d%m%Y_%H%M%S')
DIR_BACKUP=
DIR_CTE=
DIR_NFE=
DIR_ORIGEM=
IND_SIMULACAO=0

function ajuda() {
  echo "NOME"
  echo  " ${0} - realiza a organização de XMLs recepcionados de CT-es e NF-es"
  echo -e "\nSINOPSE"
  echo "  ${0} [-s][-h] -o diretório -c diretório -n diretório [-b diretório]"
  echo -e "\nDESCRIÇÃO"
  echo "  Copia os arquivos XMLs para os diretórios de destino e de backup, "
  echo "  caso informado, em seguida remove os arquivos do diretório de origem."
  echo "  Para ambos os casos, são considerados os arquivos XMLs do ano atual e "
  echo "  do ano anterior, verificando esta informação no nome do arquivo. Para "
  echo "  os arquivos de NF-es, somente são considerados os que são destinados "
  echo "  ao CNPJ que começa com 2077056600"
  echo -e "\nOPÇÕES"
  echo "  -s  (opcional) realiza a simulação do processo"
  echo "  -h  (opcional) exibe a ajuda do comando"
  echo "  -o  diretório de origem"
  echo "  -c  diretório de destino dos arquivos XMLs de CT-es"
  echo "  -n  diretório de destino dos arquivos XMLs de NF-es"
  echo "  -b  (opcional) diretório de backup dos arquivos XMLs de CT-es e NF-es"
  echo -e "\nAUTOR"
  echo "  Mateus Alexandre"
}

function listar_cte() {
  # Padrão para os nomes dos arquivos XML
  local PDR_ATUAL="[cC][tT][eE]_[0-9][0-9]${ANO}*.[xX][mM][lL]"
  local PDR_ANTERIOR="[cC][tT][eE]_[0-9][0-9]${ANO_ANTERIOR}*.[xX][mM][lL]"
  local PDR_GERAL="[cC][tT][eE]_[0-9][0-9]*.[xX][mM][lL]"

  # Localiza os arquivos que devem ser processados
  find ${DIR_ORIGEM} -maxdepth 1 \
                     -name "${PDR_ATUAL}" \
                     -type f \
                     >> ${DIR_ORIGEM}/lote_cte_${DATA}.txt
  find ${DIR_ORIGEM} -maxdepth 1 \
                     -name "${PDR_ANTERIOR}" \
                     -type f \
                     >> ${DIR_ORIGEM}/lote_cte_${DATA}.txt

  # Localiza os arquivos que não devem ser processados
  find ${DIR_ORIGEM} -maxdepth 1 \
                     -name "${PDR_GERAL}" \
                     -not -name "${PDR_ATUAL}" \
                     -not -name "${PDR_ANTERIOR}" \
                     -type f \
                     >> ${DIR_ORIGEM}/lote_cte_remover_${DATA}.txt
}

function listar_nfe() {
  # Padrão para os nomes dos arquivos XML
  local PDR_ATUAL="[nN][fF][eE]_[0-9][0-9]${ANO}*.[xX][mM][lL]"
  local PDR_ANTERIOR="[nN][fF][eE]_[0-9][0-9]${ANO_ANTERIOR}*.[xX][mM][lL]"
  local PDR_GERAL="[nN][fF][eE]_[0-9][0-9]*.[xX][mM][lL]"

  # Localiza os arquivos que devem ser processados
  local ARQ_ATUAL=$(find ${DIR_ORIGEM} -maxdepth 1 \
                                       -name "${PDR_ATUAL}" \
                                       -type f)
  local ARQ_ANTERIOR=$(find ${DIR_ORIGEM} -maxdepth 1 \
                                          -name "${PDR_ANTERIOR}" \
                                          -type f)

  # Localiza os arquivos que não devem ser processados
  find ${DIR_ORIGEM} -maxdepth 1 \
                     -name "${PDR_GERAL}" \
                     -not -name "${PDR_ATUAL}" \
                     -not -name "${PDR_ANTERIOR}" \
                     -type f \
                      >> ${DIR_ORIGEM}/lote_nfe_remover_${DATA}.txt

  # Padrão de pesquisa no conteúdo dos arquivos
  local PADRAO="<dest>*<cnpj>2077056600....</cnpj>.*</dest>"

  # Cria arquivos
  touch ${DIR_ORIGEM}/lote_nfe_${DATA}.txt
  touch ${DIR_ORIGEM}/lote_nfe_outros_${DATA}.txt

  # Lista os arquivos XMLs com o padrão esperado
  test ! -z "${ARQ_ATUAL}" \
          && egrep -i -l -e ${PADRAO} ${ARQ_ATUAL} \
          >> ${DIR_ORIGEM}/lote_nfe_${DATA}.txt
  test ! -z "${ARQ_ANTERIOR}" \
          && egrep -i -l -e ${PADRAO} ${ARQ_ANTERIOR} \
          >> ${DIR_ORIGEM}/lote_nfe_${DATA}.txt

  # Lista os arquivos XML sem o padrão esperado
  test ! -z "${ARQ_ATUAL}" \
          && egrep -i -L -e ${PADRAO} ${ARQ_ATUAL} \
          >> ${DIR_ORIGEM}/lote_nfe_outros_${DATA}.txt
  test ! -z "${ARQ_ANTERIOR}" \
          && egrep -i -L -e ${PADRAO} ${ARQ_ANTERIOR} \
          >> ${DIR_ORIGEM}/lote_nfe_outros_${DATA}.txt
}

function verificar_parametros() {
  # Verifica se não foi informado nenhum parâmetro
  if [ $# -eq 0 ] ;
  then
    ajuda
    exit 0
  fi

  # Trata os parâmetros informados
  while getopts "o:c:n:b:sh" PARAMETRO;
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
      c)
        # Parâmetro do diretório de destino dos CT-es
        # Verifica se diretório já foi informado
        if [ ! -z "${DIR_CTE}" ] ;
        then
          echo "O parâmetro -${PARAMETRO} foi utilizado mais de uma vez."
          exit ${ERR_PARAMETRO_INVALIDO}
        fi
        # Verifica se o diretório existe
        DIR_CTE=$(readlink -f ${OPTARG})
        if [ ! -d ${DIR_CTE} ] ;
        then
          echo "Diretório inválido para o parâmetro -${PARAMETRO}."
          exit ${ERR_DIRETORIO_INVALIDO}
        fi
        ;;
      n)
        # Parâmetro do diretório de destino das NF-es
        # Verifica se diretório já foi informado
        if [ ! -z "${DIR_NFE}" ] ;
        then
          echo "O parâmetro -${PARAMETRO} foi utilizado mais de uma vez."
          exit ${ERR_PARAMETRO_INVALIDO}
        fi
        # Verifica se o diretório existe
        DIR_NFE=$(readlink -f ${OPTARG})
        if [ ! -d ${DIR_NFE} ] ;
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
      s)
        IND_SIMULACAO=1
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

  # Verifica se o diretório de CT-e foi informado
  if [ -z "${DIR_CTE}" ] ;
  then
    echo "O diretório de destino de CT-e deve ser informado."
    exit ${ERR_PARAMETRO_INEXISTENTE}
  fi

  # Verifica se o diretório de NF-e foi informado
  if [ -z "${DIR_NFE}" ] ;
  then
    echo "O diretório de destino de NF-e deve ser informado."
    exit ${ERR_PARAMETRO_INEXISTENTE}
  fi

  # Verifica se os diretórios de backup e destino são iguais ao de origem
  if [ "${DIR_ORIGEM}" = "${DIR_CTE}" -o \
       "${DIR_ORIGEM}" = "${DIR_NFE}" -o \
       "${DIR_ORIGEM}" = "${DIR_BACKUP}" ] ;
  then
    echo "Os diretórios de backup e destino (CT-e e NF-e) não devem ser iguais ao de origem."
    exit ${ERR_OPERACAO_INVALIDA}
  fi
}

function processar_arquivos(){
  # Nomes dos diretórios
  local DIR_BKP_CTE=
  local DIR_BKP_NFE=
  local ANO_MES=
  local CNPJ=

  # Verifica se não é uma simulação
  if [ ${IND_SIMULACAO} -eq 0 ] ;
  then
    # Copia os arquivos para os diretórios de destino, caso existam
    test -s ${DIR_ORIGEM}/lote_cte_${DATA}.txt \
            && cp -u -t ${DIR_CTE} $(cat ${DIR_ORIGEM}/lote_cte_${DATA}.txt)
    test -s ${DIR_ORIGEM}/lote_nfe_${DATA}.txt \
            && cp -u -t ${DIR_NFE} $(cat ${DIR_ORIGEM}/lote_nfe_${DATA}.txt)

    # Verifica se foi informado o diretório de backup
    if [ ! -z "${DIR_BACKUP}" ] ;
    then
      for ARQUIVO_CTE in $(cat ${DIR_ORIGEM}/lote_cte_${DATA}.txt) ;
      do
        # Montagem do diretório de backup
        ANO_MES=$(echo "$(basename ${ARQUIVO_CTE})" \
                          | awk '{ print substr($1, 7, 4) }')
        CNPJ=$(echo "$(basename ${ARQUIVO_CTE})" \
                      | awk '{ print substr($1, 11, 14) }')
        DIR_BKP_CTE=${DIR_BACKUP}/Recepcao/CTE/${ANO_MES}/${CNPJ}

        # Cria diretório se não existir
        test -d ${DIR_BKP_CTE} || mkdir -p ${DIR_BKP_CTE}

        # Copia arquivo xml para o diretório de backup
        cp -u -t ${DIR_BKP_CTE} "${ARQUIVO_CTE}"
      done

      for ARQUIVO_NFE in $(cat ${DIR_ORIGEM}/lote_nfe_${DATA}.txt \
                               ${DIR_ORIGEM}/lote_nfe_outros_${DATA}.txt) ;
      do
        # Montagem do diretório de backup
        ANO_MES=$(echo "$(basename ${ARQUIVO_NFE})" \
                          | awk '{ print substr($1, 7, 4) }')
        CNPJ=$(echo "$(basename ${ARQUIVO_NFE})" \
                      | awk '{ print substr($1, 11, 14) }')
        DIR_BKP_NFE=${DIR_BACKUP}/Recepcao/NFE/${ANO_MES}/${CNPJ}

        # Cria diretório se não existir
        test -d ${DIR_BKP_NFE} || mkdir -p ${DIR_BKP_NFE}

        # Copia arquivo xml para o diretório de backup
        cp -u -t ${DIR_BKP_NFE} "${ARQUIVO_NFE}"
      done
    fi

    # Remove os arquivos fora do padrão, caso exista
    test -s ${DIR_ORIGEM}/lote_cte_remover_${DATA}.txt \
            && rm $(cat ${DIR_ORIGEM}/lote_cte_remover_${DATA}.txt)
    test -s ${DIR_ORIGEM}/lote_nfe_remover_${DATA}.txt \
            && rm $(cat ${DIR_ORIGEM}/lote_nfe_remover_${DATA}.txt)

    # Remove os arquivos copiados, caso exista
    test -s ${DIR_ORIGEM}/lote_cte_${DATA}.txt \
            && rm $(cat ${DIR_ORIGEM}/lote_cte_${DATA}.txt)
    test -s ${DIR_ORIGEM}/lote_nfe_${DATA}.txt \
            && rm $(cat ${DIR_ORIGEM}/lote_nfe_${DATA}.txt)
    test -s ${DIR_ORIGEM}/lote_nfe_outros_${DATA}.txt \
            && rm $(cat ${DIR_ORIGEM}/lote_nfe_outros_${DATA}.txt)

    # Remove os arquivos de lote, caso existam
    test -f ${DIR_ORIGEM}/lote_cte_${DATA}.txt \
            && rm ${DIR_ORIGEM}/lote_cte_${DATA}.txt
    test -f ${DIR_ORIGEM}/lote_nfe_${DATA}.txt \
            && rm ${DIR_ORIGEM}/lote_nfe_${DATA}.txt
    test -f ${DIR_ORIGEM}/lote_nfe_outros_${DATA}.txt \
            && rm ${DIR_ORIGEM}/lote_nfe_outros_${DATA}.txt
    test -f ${DIR_ORIGEM}/lote_cte_remover_${DATA}.txt \
            && rm ${DIR_ORIGEM}/lote_cte_remover_${DATA}.txt
    test -f ${DIR_ORIGEM}/lote_nfe_remover_${DATA}.txt \
            && rm ${DIR_ORIGEM}/lote_nfe_remover_${DATA}.txt
  fi
}

# Altera o Internal Field Separator para considerar somente quebra de linha
IFS=$'\n'

verificar_parametros $@
validar_parametros
listar_cte
listar_nfe
processar_arquivos
