#!/bin/bash

#Arquivos utilizados
SITES=sites.txt
RESULTADO=result_$$.txt
PRELIMINAR=preliminar_$$.txt
PTMP=preliminartmp_$$.txt

#Parâmetros execução
THRTT=100
THLOSS=2

function cleanup {
  echo "Removing garbage"
  rm  -f *$$.txt
}

trap cleanup EXIT

echo "" > $PRELIMINAR
echo "iniciando..."
while true; do


	RED='\033[0;31m';
	NC='\033[0m';
        GREEN='\033[0;32m';
	FORA='\033[1;33m';
	TITULO='\033[0;36m';

	if [[ $1 == "prob" ]]; then
		objetivo="PROBLEMAS"
 		clear
                printf "\n ${GREEN} ########## ${TITULO} TESTE DE LOSS E RTT ${GREEN} ########## ${NC} - $objetivo\n"
                reg=$(cat $PRELIMINAR)
                printf "$reg"

	else
		objetivo="TUDO"
		printf "\n ${GREEN} ######### ${TITULO} TESTE DE LOSS E RTT ${GREEN} ######## ${NC} - $objetivo\n"
	fi

	while read i; do
		site=$(echo "$i" | cut -d' ' -f1);
		ip=$(echo "$i" | cut -d' ' -f2);
		ping -c 40 -i 0.5 $ip > $RESULTADO;
		loss=$(cat $RESULTADO | grep loss | cut -d',' -f3 | cut -d'%' -f1 | sed 's/ //g');
		rtt=$(cat $RESULTADO | grep rtt | cut -d'/' -f5);
		packets=$(cat $RESULTADO | grep packets | cut -d',' -f1);

		LC=$GREEN
		RC=$GREEN

		if (( $(echo "$loss > 2.0" |bc -l) )); then
			LC=$RED;
		fi 2> /dev/null

		if (( $(echo "$rtt > 100.0" |bc -l) )); then
			RC=$RED;
		fi 2> /dev/null

		time=$(date +"%r")

		if [[ $1 == "prob" ]]; then
			if (( $(echo "$loss > $THLOSS" |bc -l) )) || (( $(echo "$rtt > $THRTT" |bc -l) ));then
				cat $PRELIMINAR | sed "/$site/d" > $PTMP
				cat $PTMP > $PRELIMINAR
				if (( $(echo "$loss == 100.0" |bc -l) ));then
					echo "\n ${GREEN}$site - ${RED}PERDAS: $loss %% | RTT: $rtt ms | ${NC}$time - ${FORA}FORA\n" >> $PRELIMINAR;
				else
					echo "\n ${GREEN}$site - ${NC}PERDAS: ${LC}$loss %% ${NC} | ${NC}RTT: ${RC}$rtt ms ${NC}| $time\n" >> $PRELIMINAR;
				fi
			else
				cat $PRELIMINAR | sed "/$site/d" > $PTMP
				cat $PTMP > $PRELIMINAR
			fi
			clear
			printf "\n ${GREEN} ########## ${TITULO} TESTE DE LOSS E RTT ${GREEN} ########## ${NC} - $objetivo\n"
                	reg=$(cat $PRELIMINAR)
               		printf "$reg"
		else
			printf "\n ${GREEN}$site - ${NC}PERDAS: ${LC}$loss %% ${NC} | ${NC}RTT: ${RC}$rtt ms ${NC}| $time\n"
		fi

	sleep 1
	done <./$SITES

	sleep 1
done
