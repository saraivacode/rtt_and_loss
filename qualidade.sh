#!/bin/bash
#
# Teste de RTT e Loss
#
# Using ICMP ping packets, measure the connection with remote nodes with LOSS and RTT parameters
#
# Author: Tiago Saraiva <tiagosarai@gmail.com>
#
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


#Arquivos utilizados
SITES=sites.txt
RESULTADO=result_$$.txt
PRELIMINAR=preliminar_$$.txt
PRELIMINAR_T=preliminar_t_$$.txt
PTMP=preliminartmp_$$.txt

#Parâmetros execução
THRTT=100 # valor em ms de RTT para consideraro link problemático
THLOSS=2 # valor em % de perdas para considerr o link problemático
PQTD=40 #Quantidade de pacotes utilizados em cada teste de ping por host
PITVL=0.5 #Intervalo em segundos, para envio dos pacotes de teste. O tempo em cada host será de PQTD * PITVL
m="prob" #Default mostra apenas problemas

#Cores
RED='\033[0;31m';
NC='\033[0m';
GREEN='\033[0;32m';
PROB='\033[1;31m';
FORA='\033[1;33m';
TITULO='\033[0;36m';
OK='\033[0;96m';

#Função de limpeza de arquivos temporários
function cleanup {
	#echo -e "\nApagando arquivos temporários..."
	rm  -f *$$.txt
	printf "\n ${NC} Kilo Bravo 1 Alpha - Ok!\n\n"
}

#Em caso de interrupção do programa, executa funnção de limpeza de arquivos temporários
trap cleanup EXIT

usage() { u1="\nUso: $0 [-r <limiar de tempo de resposta em ms> [$THRTT] ] [-l <limiar de perdas em %> [$THLOSS] ] [-n <Qtd. pacotes por dispositivo> [$PQTD] ]"
	  u2="\n[-i <intervalo do ping> [$PITVL] [-m <modalidade prob | tudo | sping> [$m] ]"
	  echo -e $u1 $u2 1>&2;
	  exit 1; }


help() {
echo -e '\nFerramenta de testes de RTT e LOSS\n'
echo Uso: $0 [opcoes]
echo -e '\n  Opcoes:\n'

echo '-m	modo de operação [sping | tudo | prob]'
echo -e '-r	tempo de resposta em ms para considerar um local com problema de latência. \e[7mNão funciona com sping'
echo -e '\e[0m-l	taxa de perdas em % para considerar um local com problema de perda de pacotes. \e[7mNão funciona com sping'
echo -e '\e[0m-n	quantidade de pacotes por teste por host - (interfere no tempo e na precisão do teste). \e[7mNão funciona com sping'
echo -e '\e[0m-i	intervalo de transissão entre pacotes - (interfere no tempo e na precisão do teste). \e[7mNão funciona com sping \e[0m.'
echo ''
echo 'Sobre os modos de operação:'
echo -e '\t ->sping - teste de ping para verificar disponibilidade.'
echo -e '\t ->tudo - exibe o resultado de todos os testes de tempo de reposta (RTT) e LOSS, destacando problemas'
echo -e '\t ->prob - teste de RTT e LOSS. Exibe apenas os testes dos locais com problema'
echo ''
echo Default: $0 -m $m -r $THRTT -l $THLOSS -n $PQTD -i $PITVL 

exit 0

}

while getopts r:l:n:i:m:h flag
do
    case "${flag}" in
        r) THRTT=${OPTARG};;
        l) THLOSS=${OPTARG};;
        n) PQTD=${OPTARG};;
	i) PITVL=${OPTARG};;
	m) m=${OPTARG}
        	if [[ $m != "prob" ]] && [[ $m != "tudo" ]] && [[ $m != "sping" ]]; then
			echo $m
			usage
		fi
            ;;
	h) help ;;
	*) usage ;;
    esac
done

#Inicia arquivo temporário de logs
echo "" > $PRELIMINAR
echo "" > $PRELIMINAR_T
echo "iniciando..."

if [[ $m == "prob" ]]; then
        objetivo="TEMPO DE RESPOSTA E PERDAS - PROBLEMAS"
        reg=$(cat $PRELIMINAR)
        printf "$reg"

elif [[ $m == "sping" ]]; then
        objetivo="DISPONIBILIDADE"
        THLOSS=99
        THRTT=10000
	PQTD=10
	PITVL=0.3
else
        objetivo="TEMPO DE RESPOSTA E PERDAS - TUDO"
fi

#Inicio da execução do programa em loop
while true; do

	clear
	printf "\n ${GREEN} ########## ${TITULO} TESTES DE CONECTIVIDADE KILO BRAVO 1 ALPHA ${GREEN} ########## ${NC} - $objetivo\n"
	echo -e "\n \e[95mUtilizando RTT: $THRTT ms | LOSS: $THLOSS % | QTD_PING: $PQTD | INTERVALO: $PITVL s | MODLIDADE: $m \n"

	while read i; do
		site=$(echo "$i" | cut -d' ' -f1);
		ip=$(echo "$i" | cut -d' ' -f2);
		ping -c $PQTD -i $PITVL $ip > $RESULTADO;
		loss=$(cat $RESULTADO | grep loss | cut -d',' -f3 | cut -d'%' -f1 | sed 's/ //g');
		rtt=$(cat $RESULTADO | grep rtt | cut -d'/' -f5);
		packets=$(cat $RESULTADO | grep packets | cut -d',' -f1);

		LC=$OK
		RC=$OK

		time=$(date +"%T")

		if (( $(echo "$loss > $THLOSS" |bc -l) )); then
			LC=$PROB
		fi

		if (( $(echo "$rtt > $THRTT" |bc -l) ));then
			RC=$PROB
		fi 2> /dev/null

		if [[ $m == "prob" ]] || [[ $m == "sping" ]]; then

 			if [[ $(cat $PRELIMINAR | grep -c $site) -ne 0 ]]; then
                        	cat $PRELIMINAR | sed "/$site/d" > $PTMP
                        	cat $PTMP > $PRELIMINAR
                	fi

			if (( $(echo "$loss > $THLOSS" |bc -l) )) || (( $(echo "$rtt > $THRTT" |bc -l) ));then
				if (( $(echo "$loss == 100.0" |bc -l) ));then
					echo "${GREEN}$site - ${PROB}PERDAS: $loss %% | RTT: $rtt ms | ${NC}$time - ${FORA}FORA\n" >> $PRELIMINAR;
				else
					echo "${GREEN}$site - ${NC}PERDAS: ${LC}$loss %% ${NC} | ${NC}RTT: ${RC}$rtt ms ${NC}| $time\n" >> $PRELIMINAR;
				fi
			fi
			clear
			printf "\n ${GREEN} ########## ${TITULO} TESTES DE CONECTIVIDADE KILO BRAVO 1 ALPHA ${GREEN} ########## ${NC} - $objetivo\n"
			echo -e "\n \e[95mUtilizando RTT: $THRTT ms | LOSS: $THLOSS % | QTD_PING: $PQTD | INTERVALO: $PITVL s | MODLIDADE: $m \n"
                	reg=$(cat $PRELIMINAR)
               		printf "$reg" | column
		else

 			if [[ $(cat $PRELIMINAR_T | grep -c $site) -ne 0 ]]; then
                        	cat $PRELIMINAR_T | sed "/$site/d" > $PTMP
                        	cat $PTMP > $PRELIMINAR_T
                	fi

			if (( $(echo "$loss == 100.0" |bc -l) )); then
				echo "${GREEN}$site - ${PROB}PERDAS: $loss %% | RTT: $rtt ms ${NC}| $time - ${FORA}FORA ${FORA}\n" >> $PRELIMINAR_T
			else
				echo "${GREEN}$site - ${NC}PERDAS: ${LC}$loss %% ${NC} | ${NC}RTT: ${RC}$rtt ms ${NC}| $time\n" >> $PRELIMINAR_T
			fi

 			clear
                        printf "\n ${GREEN} ########## ${TITULO} TESTES DE CONECTIVIDADE KILO BRAVO 1 ALPHA ${GREEN} ########## ${NC} - $objetivo\n"
                        echo -e "\n \e[95mUtilizando RTT: $THRTT ms | LOSS: $THLOSS % | QTD_PING: $PQTD | INTERVALO: $PITVL s | MODLIDADE: $m \n"
                        reg=$(cat $PRELIMINAR_T)
                        printf "$reg" | column
		fi

	sleep 1
	done <./$SITES

	sleep 1
done
