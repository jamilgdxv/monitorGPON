#!/bin/bash

####################################################
# script.sh - Script modelo                        #
#                                                  #
# Script GPL - Desenvolvido por Jamil W.           #
# Favor manter os direitos e adicionar alterações  #
# xx/xx/2020                                       #
# usage: ./script.sh <exemplo>                     #
#                                                  #
####################################################


###INICIO DO SCRIPT

DATA=`date +%d-%m-%Y`
HORA=`date +%Hh%Mmin`
#data=`date +%d-%m-%Y %Hh%Mmin`;
#LISTA DE IPS DOS CMTS CONSULTADOS

olts="/dados/monitor_olt/scripts/olt.list";
log="/dados/monitor_olt/scripts/coleta_$DATA.log";
com="comunidade";
comunidade="public";
snmpwalk="snmpwalk -Osqv -v2c -c";
snmpget="snmpget -Ovq -v2c -c";
walk="snmpwalk -On -v2c -c";
nmap="nmap -sP";


# Acesso SQL

SQL_H="192.168.10.43";
SQL_U="usuario";
SQL_P="senha";
SQL_DB="db_olt";
TB_OLT_CAD="tb_olt_cad";
TB_OLT_PLACA="tb_olt_placas";
TB_OLT_IF="tb_olt_uplink";


# Acesso LDAP

user="N5929639";
pass="!Drkcux9c07";

##LISTA DE OIDS


oltNome="1.3.6.1.2.1.1.5.0";
oltVendor="1.3.6.1.2.1.1.1.0";
boardModel="1.3.6.1.4.1.2011.2.6.7.1.1.2.1.7.0";
boardStatus="1.3.6.1.4.1.2011.6.3.3.2.1.8.0";
boardModelZ="1.3.6.1.4.1.3902.1082.10.1.2.4.1.42.1.1";
boardStatusZ="1.3.6.1.4.1.3902.1082.10.1.2.4.1.5.1.1";
boardPower="1.3.6.1.4.1.2011.2.6.7.1.1.2.1.11.0";
upTempo="1.3.6.1.2.1.1.3.0";
EtherOid="1.3.6.1.2.1.2.2.1.2";
EtherTx="1.3.6.1.4.1.2011.5.14.6.4.1.4";
EtherRx="1.3.6.1.4.1.2011.5.14.6.4.1.5";
EtherNome="1.3.6.1.2.1.2.2.1.2";

XgeiTx="1.3.6.1.4.1.3902.1082.30.40.2.4.1.3";
XgeiRx="1.3.6.1.4.1.3902.1082.30.40.2.4.1.2";

##Log Falha OLT

failLog="/dados/monitor_olt/scripts/log/fail_log_$DATA_$HORA.log";
execLog="/dados/monitor_olt/scripts/log/exec_log_$DATA.log";

#Redes por cidades

city1="10.10.1.0/24";
city2="10.20.1.0/24";

#Lista de Hosts

oltIps=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -N -e \
"select oltIp from $TB_OLT_CAD order by oltNome ASC" $SQL_DB)

oltIpsQnt=`echo "$oltIps" | wc -l`;




echo -ne "Sys Start [$DATA $HORA] - Serão processadas $oltIpsQnt host's no Cluster PR\n\n\n" >> $execLog;

for olt in ${oltIps[@]}; do


nomeOlt=`$snmpget $com $olt $oltNome 2> /dev/null | sed 's/"//g'`;

    if [ -z $nomeOlt ]; then
    echo -ne "[Sem coleta][$olt] HOST Off [OTHER]\n\n" >> $failLog;
    elif [[ $nomeOlt == *"RTD"* ]]; then
    echo -ne "[$nomeOlt][$olt] HOST type [RTD] \n\n" >> $failLog;
    elif [[ $nomeOlt == *"CMT"* ]]; then
    echo -ne "[$nomeOlt][$olt] HOST type [CMT] \n\n" >> $failLog;
    else
    vendor=`$snmpget $com $olt $oltVendor | sed 's/Integrated Access Software//g' | sed 's/ZXA10//g' | sed 's/,//g' | sed 's/"//g' | sed 's/Software Version: V1.2.3//g' | sed 's/C600//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' `;
	if [ $vendor == "Huawei" ]; then
		boards=`$walk $com $olt $boardModel | sed 's/.1.3.6.1.4.1.2011.2.6.7.1.1.2.1.7.0.//g' | awk '{print $1}'`;
		tempo=`$snmpget $com $olt $upTempo | awk '-F:' '{print $1,"Dias", $2"H", $3"Min"}'`;
		ether=`$walk $com $olt $EtherOid | egrep '0/8/0|0/9/0' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | awk '{print $1}'`;

		horaUpdate=`date +'%d-%m-%Y %H-%M'`;
		echo "$nomeOlt:$olt:$vendor:$tempo" >> $execLog;
		cableSql=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -e \
		"update $TB_OLT_CAD set oltUptime = '$tempo', oltTimeUpdate = '$horaUpdate' where oltIp = '$olt'" $SQL_DB)
			for slot in ${boards[@]}; do
				horaUpdate=`date +'%d-%m-%Y %H-%M'`;
				oltID=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -N -e \
				"select id_olt from $TB_OLT_CAD where oltIp = '$olt'" $SQL_DB)
				modelo=`$snmpget $com $olt $boardModel.$slot | sed 's/"//g'`;
				status=`$snmpget $com $olt $boardStatus.$slot | sed 's/"//g'`;
					if [ $status -eq 1 ]; then
					stats="uninstall";
					elif [ $status -eq 2 ]; then
					stats="normal";
					elif [ $status -eq 3 ]; then
					stats="fault";
					elif [ $status -eq 4 ]; then
					stats="forbidden";
					elif [ $status -eq 5 ]; then
					stats="discovery";
					elif [ $status -eq 6 ]; then
					stats="config";
					elif [ $status -eq 7 ]; then
					stats="offline";
					elif [ $status -eq 8 ]; then
					stats="abnormal";
					fi

					echo "$slot:$modelo:$stats" >> $execLog;

					placaSQL=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -e \
					"update $TB_OLT_PLACA set slotStatus = '$stats', horaUpdate = '$horaUpdate' where slotPlaca = '$slot' and id_olt = '$oltID'" $SQL_DB)
				PowerValue=`$snmpget $com $olt $boardPower.$slot | sed 's/"//g'`;
				PowerBoardStatus=`$snmpget $com $olt 1.3.6.1.4.1.2011.2.6.7.1.1.2.1.17.0.$slot | sed 's/"//g'`;
					if [ $PowerBoardStatus -eq 1 ]; then
					pstats="normal";
					elif [ $PowerBoardStatus -eq 2 ]; then
					pstats="fault";
					elif [ $PowerBoardStatus -eq 3 ]; then
					pstats="invalid";
					fi
					echo "$slot:$modelo:$stats" >> $execLog;
					placaSQL=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -e \
					"update $TB_OLT_PLACA set slotPowerState = '$pstats', slotPower = '$PowerValue', horaUpdate = '$horaUpdate' where slotPlaca = '$slot' and id_olt = '$oltID'" $SQL_DB)
			done

			for eth in ${ether[@]}; do
			nome_eth=`$snmpwalk $com $olt $EtherNome.$eth | sed 's/Huawei-MA5800-V100R020-ETHERNET//g' | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			eth_TX=`$snmpget $com $olt $EtherTx.$eth`;
			eth_RX=`$snmpget $com $olt $EtherRx.$eth`;
			TX=`echo "$eth_TX * 0.000001" | bc | awk '{printf "%.3f\n", $0}'`;
			RX=`echo "$eth_RX * 0.000001" | bc | awk '{printf "%.3f\n", $0}'`;

			echo "$nome_eth:$TX:$RX" >> $execLog;
			IfSQL=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -e \
			"update $TB_OLT_IF set slotIfTx ='$TX', slotIfRx = '$RX', horaUpdate = '$horaUpdate' where slotIF = '$nome_eth' and id_olt = '$oltID'" $SQL_DB)
			done
		echo -ne "\n\n" >> $execLog;
	elif [ $vendor == "ZTE" ]; then
		boards=`$walk $com $olt $boardModelZ | sed 's/.1.3.6.1.4.1.3902.1082.10.1.2.4.1.42.1.1.//g' | egrep 'HFTH|SFUQ|PRVR|GFGH'| awk '{print $1}'`;
		tempo=`$snmpget $com $olt $upTempo | awk '-F:' '{print $1,"Dias", $2"H", $3"Min"}'`;
		ether=`$walk $com $olt $EtherOid | egrep '1/10/1|1/11/1' | sed 's/.1.3.6.1.2.1.2.2.1.2.//g' | awk '{print $1}'`;
		horaUpdate=`date +'%d-%m-%Y %H-%M'`;
		echo "$nomeOlt:$olt:$vendor:$tempo" >> $execLog;
		cableSql=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -e \
		"update $TB_OLT_CAD set oltUptime = '$tempo', oltTimeUpdate = '$horaUpdate' where oltIp = '$olt'" $SQL_DB)


		PowerColeta=`./ZTE_power.sh $olt $user $pass > log/$nomeOlt.txt`;
			for slot in ${boards[@]}; do
				horaUpdate=`date +'%d-%m-%Y %H-%M'`;
				oltID=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -N -e \
				"select id_olt from $TB_OLT_CAD where oltIp = '$olt'" $SQL_DB)
				modelo=`$snmpget $com $olt $boardModelZ.$slot | sed 's/"//g'`;
				status=`$snmpget $com $olt $boardStatusZ.$slot`;
					if [ $status -eq 1 ]; then
					stats="inService";
					elif [ $status -eq 2 ]; then
					stats="notInService";
					elif [ $status -eq 3 ]; then
					stats="hwOnline";
					elif [ $status -eq 4 ]; then
					stats="hwOffline";
					elif [ $status -eq 5 ]; then
					stats="configuring";
					elif [ $status -eq 6 ]; then
					stats="configFailed";
					elif [ $status -eq 7 ]; then
					stats="typeMismatch";
					elif [ $status -eq 8 ]; then
					stats="deactived";
					elif [ $status -eq 9 ]; then
					stats="faulty";
					elif [ $status -eq 10 ]; then
					stats="invalid";
					elif [ $status -eq 11 ]; then
					stats="noPower";
					elif [ $status -eq 12 ]; then
					stats="unauthorized";
					elif [ $status -eq 13 ]; then
					stats="adminDown";
					elif [ $status -eq 34 ]; then
					stats="powerSaving";
					fi

					echo "$slot:$modelo:$stats" >> $execLog;
					placaSQL=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -e \
					"update $TB_OLT_PLACA set slotStatus = '$stats', horaUpdate = '$horaUpdate' where slotPlaca = '$slot' and id_olt = '$oltID'" $SQL_DB)
				if [ $slot == 18 ] || [ $slot == 20 ]; then
				PowerValue=`cat log/$nomeOlt.txt | egrep  'V' | grep -v AVISO | grep -w $slot | awk '-F ' '{print $NF}' | sed 's/V//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
				PowerBoardStatus=`cat log/$nomeOlt.txt | grep PPC | grep -w $slot | awk '-F ' '{print $NF}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
					placaSQL=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -e \
					"update $TB_OLT_PLACA set slotPowerState = '$PowerBoardStatus', slotPower = '$PowerValue', horaUpdate = '$horaUpdate' where slotPlaca = '$slot' and id_olt = '$oltID'" $SQL_DB)
				fi
			done

			for eth in ${ether[@]}; do
			nome_eth=`snmpwalk -v2c -c $com -Osqv $olt $EtherNome.$eth | sed 's/ZTE-C600-V1.2.3-xgei-//g' | sed 's/ZTE-C600-V1.1.2_BC-xgei-//g' | sed 's/"//g' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'`;
			eth_TX=`$snmpget $com $olt $XgeiTx.$eth`;
			eth_RX=`$snmpget $com $olt $XgeiRx.$eth`;
			TX=`echo "$eth_TX * 0.001" | bc | awk '{printf "%.3f\n", $0}'`;
			RX=`echo "$eth_RX * 0.001" | bc`;

			echo "$nome_eth:$TX:$RX" >> $execLog;
			IfSQL=$(mysql --defaults-extra-file=/dados/monitor_olt/scripts/acesso.cnf -e \
			"update $TB_OLT_IF set slotIfTx ='$TX', slotIfRx = '$RX', horaUpdate = '$horaUpdate' where slotIF = '$nome_eth' and id_olt = '$oltID'" $SQL_DB)
			done
		echo -ne "\n\n" >> $execLog;
	fi
    fi
done &
