#!/bin/bash
### PUT THIS ON to initiate with system /etc/init.d/


sqlBase="db_olt";


## PARANDO A CRONTAB

/etc/init.d/cron stop


## LIMPEZA DE DADOS SQL

limpa1=$(mysql --defaults-extra-file=/locate/of/acesso.cnf -N -e \
"delete from tb_olt_placas where slotStatus like '%n%'"  $sqlBase);

limpa2=$(mysql --defaults-extra-file=/locate/of/acesso.cnf -N -e \
"delete from tb_olt_ports where oltNomePort like '%/%'"  $sqlBase);

limpa3=$(mysql --defaults-extra-file=/locate/of/acesso.cnf -N -e \
"delete from tb_olt_ports where oltDescPort like '%NO%'"  $sqlBase);

limpa4=$(mysql --defaults-extra-file=/locate/of/acesso.cnf -N -e \
"delete from tb_olt_ports where oltDescPort like '%.%'"  $sqlBase);

limpa5=$(mysql --defaults-extra-file=/locate/of/acesso.cnf -N -e \
"delete from tb_olt_ports where oltDescPort like '%/%'"  $sqlBase);

limpa6=$(mysql --defaults-extra-file=/locate/of/acesso.cnf -N -e \
"delete from tb_olt_uplink where slotIF like '%/%';"  $sqlBase);


limpa7=$(mysql --defaults-extra-file=/locate/of/acesso.cnf -N -e \
"delete from tb_olt_ports where oltNomePort = ''"  $sqlBase);


limpa8=$(mysql --defaults-extra-file=/locate/of/acesso.cnf -N -e \
"delete from tb_olt_cad where oltNome like '%OLT%'" $sqlBase);

limpa9=$(mysql --defaults-extra-file=/locate/of/acesso.cnf -N -e \
"delete from tb_olt_uplink"  $sqlBase);


## START PROCEDURE COLETA DE OLTS E INSERCAO DE PLACAS


cd /dados/monitor_olt/scripts


/bin/bash cad_olt_sql.sh


/bin/bash cad_placas.sh



sleep 120

/etc/init.d/cron start
