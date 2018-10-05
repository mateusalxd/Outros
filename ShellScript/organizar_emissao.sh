#!/bin/bash

# Constantes de erro
readonly ERR_DIRETORIO_INVALIDO=2
readonly ERR_PARAMETRO_INVALIDO=3
readonly ERR_PARAMETRO_INEXISTENTE=4
readonly ERR_OPERACAO_INVALIDA=5
readonly ERR_PROCESSO_EXECUCAO=6

# Variáveis
DIR_ORIGEM=
DIR_DESTINO=
DIR_BACKUP=

function ajuda() {
    echo "NOME"
    echo  " ${0} - realiza a organização de XMLs emitidos de NF-es"
    echo -e "\nSINOPSE"
    echo "  ${0} [-h] -o diretório -d diretório -b diretório"
    echo -e "\nDESCRIÇÃO"
    echo "  Organiza os arquivos XMLs em diretórios"
    echo -e "\nOPÇÕES"
    echo "  -h  (opcional) exibe a ajuda do comando"
    echo "  -o  diretório de origem dos arquivos XMLs"
    echo "  -d  diretório de destino dos arquivos XMLs de NF-es"
    echo "  -b  diretório de backup dos arquivos XMLs de NF-es"
    echo -e "\nAUTOR"
    echo "  Mateus Alexandre"
}

function verificar_parametros() {
    # Verifica se não foi informado nenhum parâmetro
    # $# representa o número de parâmetros informados
    # -eq representa igual
    if [ $# -eq 0 ] ;
    then
        ajuda
        exit 0
    fi
    
    # Trata os parâmetros informados
    while getopts "ho:d:b:" PARAMETRO;
    do
        case ${PARAMETRO} in
            h)
                # Parâmetro de ajuda
                ajuda
                exit 0
            ;;
            o)
                # Parâmetro do diretório de origem
                # Verifica se diretório já foi informado
                # ! representa negação
                # -z representa verificação de texto nulo
                if [ ! -z "${DIR_ORIGEM}" ] ;
                then
                    echo "O parâmetro -${PARAMETRO} foi utilizado mais de uma vez."
                    exit ${ERR_PARAMETRO_INVALIDO}
                fi
                
                # Verifica se o diretório existe
                # OPTARG representa o valor do parâmetro
                # ! representa negação
                # -d representa verificação de diretório existente
                DIR_ORIGEM=${OPTARG}
                if [ ! -d ${DIR_ORIGEM} ] ;
                then
                    echo "Diretório inválido para o parâmetro -${PARAMETRO}."
                    exit ${ERR_DIRETORIO_INVALIDO}
                fi
            ;;
            d)
                # Parâmetro do diretório de destino
                # Verifica se diretório já foi informado
                # ! representa negação
                # -z representa verificação de texto nulo
                if [ ! -z "${DIR_DESTINO}" ] ;
                then
                    echo "O parâmetro -${PARAMETRO} foi utilizado mais de uma vez."
                    exit ${ERR_PARAMETRO_INVALIDO}
                fi
                
                # Verifica se o diretório existe
                # OPTARG representa o valor do parâmetro
                # ! representa negação
                # -d representa verificação de diretório existente
                DIR_DESTINO=${OPTARG}
                if [ ! -d ${DIR_DESTINO} ] ;
                then
                    echo "Diretório inválido para o parâmetro -${PARAMETRO}."
                    exit ${ERR_DIRETORIO_INVALIDO}
                fi
            ;;
            b)
                # Parâmetro do diretório de backup
                # Verifica se diretório já foi informado
                # ! representa negação
                # -z representa verificação de texto nulo
                if [ ! -z "${DIR_BACKUP}" ] ;
                then
                    echo "O parâmetro -${PARAMETRO} foi utilizado mais de uma vez."
                    exit ${ERR_PARAMETRO_INVALIDO}
                fi
                
                # Verifica se o diretório existe
                # OPTARG representa o valor do parâmetro
                # ! representa negação
                # -d representa verificação de diretório existente
                DIR_BACKUP=${OPTARG}
                if [ ! -d ${DIR_BACKUP} ] ;
                then
                    echo "Diretório inválido para o parâmetro -${PARAMETRO}."
                    exit ${ERR_DIRETORIO_INVALIDO}
                fi
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
    # ! representa negação
    # -z representa verificação de texto nulo
    if [ -z "${DIR_ORIGEM}" ] ;
    then
        echo "O diretório de origem deve ser informado."
        exit ${ERR_PARAMETRO_INEXISTENTE}
    fi
    
    # Verifica se o diretório de destino foi informado
    # ! representa negação
    # -z representa verificação de texto nulo
    if [ -z "${DIR_DESTINO}" ] ;
    then
        echo "O diretório de destino deve ser informado."
        exit ${ERR_PARAMETRO_INEXISTENTE}
    fi
    
    # Verifica se o diretório de backup foi informado
    # ! representa negação
    # -z representa verificação de texto nulo
    if [ -z "${DIR_BACKUP}" ] ;
    then
        echo "O diretório de backup deve ser informado."
        exit ${ERR_PARAMETRO_INEXISTENTE}
    fi
    
    # Verifica se o diretório de backup é igual ao de origem
    # -o representa operador OU
    # \ representa quebra de linha com o mesmo comando
    if [ "${DIR_ORIGEM}" = "${DIR_DESTINO}" -o \
    "${DIR_ORIGEM}" = "${DIR_BACKUP}" ] ;
    then
        echo "O diretório de destino e backup não devem ser iguais ao de origem."
        exit ${ERR_OPERACAO_INVALIDA}
    fi
}

function processar_arquivos(){
    # Verifica se o processo já está em execução
    # ! representa negação
    # -e representa verificação de arquivo existente
    if [ ! -e ${DIR_ORIGEM}/lock.lck ] ;
    then
        # Nomes dos diretórios
        local DIR_BKP_NFE=
        local DIR_BKP_NFE_EVT=
        local ANO_MES=
        local CNPJ=
        local PADRAO="[nN][fF][eE]_[0-9][0-9]*.[xX][mM][lL]"
        local PADRAO_EVT="[nN][fF][eE]_Evento_[0-9][0-9]*.[xX][mM][lL]"
        
        # Cria trava para execução do script
        touch ${DIR_ORIGEM}/lock.lck
        
        # Percorre todos os arquivo do diretório de origem que atendem o padrão
        for ARQUIVO_NFE in $(find ${DIR_ORIGEM} -name ${PADRAO} -type f) ;
        do
            # Montagem do diretório de backup
            ANO_MES=$(echo "$(basename ${ARQUIVO_NFE})" \
            | awk '{ print substr($1, 7, 4) }')
            CNPJ=$(echo "$(basename ${ARQUIVO_NFE})" \
            | awk '{ print substr($1, 11, 14) }')
            DIR_BKP_NFE=${DIR_BACKUP}/Emissao/NFE/${ANO_MES}/${CNPJ}
            
            # Cria diretório se não existir
            # ! representa negação
            # -d representa verificação de diretório existente
            # || representa a execução do comando seguinte caso o resultado do anterior seja 0
            test -d ${DIR_BKP_NFE} || mkdir -p ${DIR_BKP_NFE}
            
            # Copia arquivo xml para o diretório de backup
            cp "${ARQUIVO_NFE}" ${DIR_BKP_NFE}
            
            # Ajusta o arquivo XML para integração com a NDD
            perl -pi -e 's/IDOR\[/IDOR\|/g' "${ARQUIVO_NFE}"
            perl -pi -e 's/\]IDOR/\|IDOR/g' "${ARQUIVO_NFE}"
            perl -pi -e 's/(CXP[A-Z\_\-]*\.[0-9]+)(;)/\1\|/g' "${ARQUIVO_NFE}"
            
            # Move para o diretório de destino
            mv "${ARQUIVO_NFE}" ${DIR_DESTINO}
        done
        
        for ARQUIVO_NFE_EVT in $(find ${DIR_ORIGEM} -name ${PADRAO_EVT} -type f) ;
        do
            # Montagem do diretório de backup
            ANO_MES=$(echo "$(basename ${ARQUIVO_NFE_EVT})" \
            | awk '{ print substr($1, 14, 4) }')
            CNPJ=$(echo "$(basename ${ARQUIVO_NFE_EVT})" \
            | awk '{ print substr($1, 18, 14) }')
            DIR_BKP_NFE_EVT=${DIR_BACKUP}/Emissao/NFE/${ANO_MES}/${CNPJ}/Evento
            
            # Cria diretório se não existir
            # ! representa negação
            # -d representa verificação de diretório existente
            # || representa a execução do comando seguinte caso o resultado do anterior seja 0
            test -d ${DIR_BKP_NFE_EVT} || mkdir -p ${DIR_BKP_NFE_EVT}
            
            # Move arquivo xml para o diretório de backup
            mv "${ARQUIVO_NFE_EVT}" ${DIR_BKP_NFE_EVT}
        done
        
        # Remove trava para execução do script
        rm ${DIR_ORIGEM}/lock.lck
    else
        echo "O script já está em execução."
        exit ${ERR_PROCESSO_EXECUCAO}
    fi
}

# Altera o Internal Field Separator para considerar somente quebra de linha
IFS=$'\n'

verificar_parametros $@
validar_parametros
processar_arquivos
