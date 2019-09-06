# -*- coding: utf-8 -*-


from os.path import join
from getopt import getopt, GetoptError
from sys import argv
from os import path, makedirs, sep, remove
from datetime import datetime
from shutil import copy2
from re import sub, search, IGNORECASE
from traceback import format_exc
from time import sleep


configuracoes = [{'padrao': r'\bnfe_[0-9][0-9].*.xml\b', 'diretorio_base': '', 'pos_ano_mes': (6, 10), 'pos_cnpj': (10, 24), 'documento': 'nfe'},
                 {'padrao': r'\bnfe_evento_[0-9][0-9].*.xml\b', 'diretorio_base': 'Evento', 'pos_ano_mes': (13, 17), 'pos_cnpj': (17, 31), 'documento': 'nfe'},
                 {'padrao': r'\bcte_[0-9][0-9].*.xml\b', 'diretorio_base': '', 'pos_ano_mes': (6, 10), 'pos_cnpj': (10, 24), 'documento': 'cte'}]
data_hora = datetime.now()
formato = '%Y%m%d%H%M%S'
formato_completo = '%d/%m/%Y %H:%M:%S'


#######################################################################################
################################## Início da Classe ###################################
#######################################################################################


class ArquivoXML(object):
    """ Classe com as informações dos arquivos XMLs """

    def __init__(self, diretorio_origem, arquivo, diretorio_base, cnpj, ano_mes, documento):
        self.__diretorio_origem = diretorio_origem
        self.__arquivo = arquivo
        self.__diretorio_base = diretorio_base
        self.__cnpj = cnpj
        self.__ano = str(datetime.strptime(ano_mes, '%y%m').year)
        self.__mes = ano_mes[2:4]
        self.__documento = documento

    def __repr__(self):
        return '{0},{1},{2},{3},{4},{5},{6};'.format(self.diretorio_origem, self.arquivo, self.diretorio_base, self.cnpj, self.ano, self.mes, self.documento)

    def __str__(self):
        return '{0},{1},{2},{3},{4},{5},{6};'.format(self.diretorio_origem, self.arquivo, self.diretorio_base, self.cnpj, self.ano, self.mes, self.documento)

    @property
    def arquivo(self):
        return self.__arquivo

    @arquivo.setter
    def arquivo(self, valor):
        self.__arquivo = valor

    @property
    def ano(self):
        return self.__ano

    @ano.setter
    def ano(self, valor):
        self.__ano = valor

    @property
    def mes(self):
        return self.__mes

    @mes.setter
    def mes(self, valor):
        self.__mes = valor

    @property
    def cnpj(self):
        return self.__cnpj

    @cnpj.setter
    def cnpj(self, valor):
        self.__cnpj = valor

    @property
    def documento(self):
        return self.__documento

    @documento.setter
    def documento(self, valor):
        self.__documento = valor

    @property
    def diretorio_base(self):
        return self.__diretorio_base

    @diretorio_base.setter
    def diretorio_base(self, valor):
        self.__diretorio_base = valor

    @property
    def diretorio_origem(self):
        return self.__diretorio_origem

    @diretorio_origem.setter
    def diretorio_origem(self, valor):
        self.__diretorio_origem = valor

    def arquivo_completo(self):
        return join(self.__diretorio_origem, self.__arquivo)


#######################################################################################
#################################### Fim da Classe ####################################
#######################################################################################


def contem_padrao(nome_arquivo, padrao):
    """ Verifica se o arquivo contém o padrão especificado """

    with open(nome_arquivo, 'r') as arquivo:
        return bool(search(padrao, arquivo.read(), IGNORECASE))


def gerar_bloqueio(nome):
    """ Gera bloqueio para impedir execução simultânea """

    try:
        with open(nome, 'w') as arquivo:
            arquivo.write('lock')
    except:
        print(format_exc())
        exit(2)


def liberar_bloqueio(nome):
    """ Libera bloqueio """

    try:
        remove(nome)
    except:
        print(format_exc())
        exit(2)


def gerar_log(diretorio, nome_arquivo, mensagem):
    """ Gera arquivo de log """

    try:
        with open(diretorio + nome_arquivo, 'a') as arquivo:
            arquivo.write(mensagem + '\n')
    except:
        print(mensagem)


def listar_arquivos(diretorio):
    """ Lista os arquivos existentes no diretório informado """

    from os import listdir
    from re import match, IGNORECASE

    lista_arquivos = []

    for arquivo in listdir(diretorio):
        for configuracao in configuracoes:
            if match(configuracao['padrao'], arquivo, IGNORECASE):
                pos_cnpj = configuracao['pos_cnpj']
                pos_ano_mes = configuracao['pos_ano_mes']
                lista_arquivos.append(ArquivoXML(
                    diretorio,
                    arquivo,
                    configuracao['diretorio_base'],
                    arquivo[pos_cnpj[0]:pos_cnpj[1]],
                    arquivo[pos_ano_mes[0]:pos_ano_mes[1]],
                    configuracao['documento']
                ))
                break

    return lista_arquivos


def gerar_xml_com_pipe(arquivo_origem, arquivo_destino):
    """ Gera arquivo com pipe """

    with open(arquivo_origem, 'r') as entrada:
        conteudo = entrada.read()

    with open(arquivo_destino, 'w') as saida:
        saida.write(sub(r'(CXP[A-Z_-]*\.[0-9]+)(;)', r'\1|',
                        sub(r'\]IDOR', r'|IDOR',
                            sub(r'IDOR\[', r'IDOR|', conteudo)
                            )
                        )
                    )


def recuperar_parametros():
    """ Recupera os parâmetros informados
    e - emissão
    r - recepção
    1 - origem
    2 - backup
    3 - fen
    4 - ndd ou otm
    5 - documento (cte ou nfe)
    """

    try:
        argumentos = getopt(argv[1:], 'er1:2:3:4:5:', ['emissao', 'recepcao'])
        parametros = {}
        for parametro, valor in argumentos[0]:
            if parametro == '-1':
                if not path.exists(valor):
                    raise Exception('Diretorio de origem invalido')
                parametros['origem'] = valor if valor.endswith(
                    sep) else valor + sep
            elif parametro == '-2':
                if not path.exists(valor):
                    raise Exception('Diretorio de backup invalido')
                parametros['backup'] = valor if valor.endswith(
                    sep) else valor + sep
            elif parametro == '-3':
                if not path.exists(valor):
                    raise Exception('Diretorio do fen invalido')
                parametros['fen'] = valor if valor.endswith(
                    sep) else valor + sep
            elif parametro == '-4':
                if not path.exists(valor):
                    raise Exception('Diretorio auxiliar invalido')
                parametros['auxiliar'] = valor if valor.endswith(
                    sep) else valor + sep
            elif parametro == '-5':
                if valor not in ['cte', 'nfe']:
                    raise Exception(
                        'Documento invalido, deve ser informado cte ou nfe')
                parametros['documento'] = valor.lower()
            elif parametro in ['--emissao', '-e']:
                if 'tipo' in parametros.keys():
                    raise Exception('Parametro tipo duplicado')
                else:
                    parametros['tipo'] = 'emissao'
            elif parametro in ['--recepcao', '-r']:
                if 'tipo' in parametros.keys():
                    raise Exception('Parametro tipo duplicado')
                else:
                    parametros['tipo'] = 'recepcao'

        return parametros
    except GetoptError as err:
        print(str(err))
        exit(2)


def executar_emissao(parametros):
    """ Executa a organização dos arquivos emitidos """

    try:
        arquivo_lock = join(
            parametros['origem'], 'lock_emissao_{0}.lck'.format(parametros['documento']))

        if not path.isfile(arquivo_lock):
            gerar_bloqueio(arquivo_lock)

            arquivos = listar_arquivos(parametros['origem'])
            for arquivo in arquivos:
                try:
                    if arquivo.documento == parametros['documento']:
                        if 'backup' in parametros.keys():
                            diretorio_backup = join(parametros['backup'], 'Emissao', parametros['documento'].upper(
                            ), arquivo.diretorio_base, arquivo.ano, arquivo.mes, arquivo.cnpj) + sep
                            if not path.exists(diretorio_backup):
                                makedirs(diretorio_backup)

                            copy2(arquivo.arquivo_completo(), diretorio_backup)

                        if 'auxiliar' in parametros.keys():
                            if parametros['documento'] == 'nfe' and arquivo.diretorio_base == '':
                                gerar_xml_com_pipe(arquivo.arquivo_completo(), join(
                                    parametros['auxiliar'], arquivo.arquivo))

                        remove(arquivo.arquivo_completo())

                except:
                    gerar_log(parametros['origem'], data_hora.strftime(formato) + '.log',
                              '{0}\nArquivo: {1}\nMensagem:\n{2}\n'.format(datetime.now().strftime(formato_completo),
                                                                           arquivo.arquivo_completo(),
                                                                           format_exc()))

            liberar_bloqueio(arquivo_lock)
    except:
        gerar_log(parametros['origem'], data_hora.strftime(formato) + '.log',
                  '{0}\nMensagem:\n{1}\n'.format(datetime.now().strftime(formato_completo),
                                                 format_exc()))


def executar_recepcao(parametros):
    """ Executa a organização dos arquivos recepcionados """

    try:
        ano_atual = datetime.now().year
        arquivo_lock = join(
            parametros['origem'], 'lock_recepcao_{0}.lck'.format(parametros['documento']))

        if not path.isfile(arquivo_lock):

            gerar_bloqueio(arquivo_lock)

            arquivos = listar_arquivos(parametros['origem'])
            for arquivo in arquivos:
                try:
                    if arquivo.documento == parametros['documento']:
                        if 'backup' in parametros.keys():
                            diretorio_backup = join(parametros['backup'], 'Recepcao', parametros['documento'].upper(
                            ), arquivo.diretorio_base, arquivo.ano, arquivo.mes, arquivo.cnpj) + sep
                            if not path.exists(diretorio_backup):
                                makedirs(diretorio_backup)

                            copy2(arquivo.arquivo_completo(), diretorio_backup)

                        if (ano_atual - 1) <= int(arquivo.ano) <= ano_atual:
                            if 'fen' in parametros.keys():
                                if parametros['documento'] == 'nfe' and arquivo.diretorio_base == '':
                                    if contem_padrao(arquivo.arquivo_completo(), '<dest>.*<cnpj>2077056600....</cnpj>.*</dest>'):
                                        copy2(arquivo.arquivo_completo(),
                                            parametros['fen'])
                                elif parametros['documento'] == 'cte' and arquivo.diretorio_base == '':
                                    copy2(arquivo.arquivo_completo(),
                                        parametros['fen'])

                            if 'auxiliar' in parametros.keys():
                                if parametros['documento'] in ['cte', 'nfe'] and arquivo.diretorio_base == '':
                                    copy2(arquivo.arquivo_completo(),
                                        parametros['auxiliar'])

                        remove(arquivo.arquivo_completo())

                except:
                    gerar_log(parametros['origem'], data_hora.strftime(formato) + '.log',
                              '{0}\nArquivo: {1}\nMensagem:\n{2}\n'.format(datetime.now().strftime(formato_completo),
                                                                           arquivo.arquivo_completo(),
                                                                           format_exc()))

            liberar_bloqueio(arquivo_lock)
    except:
        gerar_log(parametros['origem'], data_hora.strftime(formato) + '.log',
                  '{0}\nMensagem:\n{1}\n'.format(datetime.now().strftime(formato_completo),
                                                 format_exc()))


parametros = recuperar_parametros()

if parametros['tipo'] == 'emissao':
    contador = 1
    while (contador <= 3):
        executar_emissao(parametros)
        contador = contador + 1
        if contador <= 3:
            sleep(15.0)
elif parametros['tipo'] == 'recepcao':
    executar_recepcao(parametros)
