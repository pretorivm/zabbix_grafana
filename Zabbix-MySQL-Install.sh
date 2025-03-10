#---------------------------------------------------------------------------------------
# Instalação automatizada do Zabbix, MySQL e o Grafana no Ubuntu Server 24.04
#
# Download da ISO do Ubuntu Server
# https://mirror.uepg.br/ubuntu-releases/24.04.2/ubuntu-24.04.2-live-server-amd64.iso
#
#---------------------------------------------------------------------------------------
# Desenvolvido e personalizado por Raimundo Junior
#
# sudo git  clone https://github.com/pretorivm/zabbix_grafana.git
# sudo chmod +x Zabbix-MySQL-Install.sh
# sudo ./Zabbix-MySQL-Install.sh
#---------------------------------------------------------------------------------------

clear
echo "#------------------------------------------------------#"
echo      			"Instalando o MySQL"
echo "#------------------------------------------------------#"
export DEBIAN_FRONTEND=noninteractive
sudo apt update && sudo apt install mysql-server net-tools -y
echo "--------------------------------------------------------"

echo "#------------------------------------------------------#"
echo      "Criando o banco de dados Zabbix e seu usuário"
echo "#------------------------------------------------------#"
sudo mysql -u root -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;" && \
sudo mysql -u root -e "create user zabbix@localhost identified by 'zabbix';" && \
sudo mysql -u root -e "grant all privileges on zabbix.* to zabbix@localhost;" && \
sudo mysql -u root -e "set global log_bin_trust_function_creators = 1;"
echo "------------------------------------------------------------------------------------"
# Comando para verificar usuários criados no banco de dados
# SELECT user FROM mysql.user;

# Comando para verificar os privilégios do usuário 
# SHOW GRANTS FOR zabbix@localhost;

export DEBIAN_FRONTEND=noninteractive
sudo wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.0+ubuntu24.04_all.deb
sudo dpkg -i zabbix-release_latest_7.0+ubuntu24.04_all.deb
sudo apt update && sudo apt upgrade -y && sudo apt list --upgradable
sudo apt install zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent2 zabbix-agent2-plugin-mongodb zabbix-agent2-plugin-mssql zabbix-agent2-plugin-postgresql -y
#
echo "#--------------------------------------------------------#"
echo         "Importando os dados para o Banco de dados"
echo "#--------------------------------------------------------#"
sudo zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -pzabbix zabbix

echo "#--------------------------------------------------------#"
echo     "Importando os dados para o Banco de dados +- 35sec"
echo "#--------------------------------------------------------#"
sleep 35

sudo sed -i 's/^# DBPassword=/DBPassword=zabbix/' /etc/zabbix/zabbix_server.conf
#
echo "#------------------------------------------------------------#"
echo      "Mudando parâmetro do banco de dados Zabbix e seu usuário"
echo "#------------------------------------------------------------#"
sudo mysql -u root -e "set global log_bin_trust_function_creators = 0;"
#
echo "#--------------------------------------------------------#"
echo            "Ajustando arquivo do Zabbix Server"
echo "#--------------------------------------------------------#"
sudo sed -i 's/Timeout=4/Timeout=30/' /etc/zabbix/zabbix_server.conf
echo "#--------------------------------------------------------#"
echo            "Ajustando o arquivo do NGINX"
echo "#--------------------------------------------------------#"
sudo sed -i 's/#        listen/        listen/' /etc/nginx/conf.d/zabbix.conf
sudo sed -i 's/8080/80/' /etc/nginx/conf.d/zabbix.conf
# Extrair o valor inet da primeira placa de rede excluindo a interface "lo" e armazenar em uma variável
inet_value=$(ifconfig | awk '/inet / && $1 !~ /lo/{gsub("addr:",""); print $2; exit}')
echo "#--------------------------------------------------------#"
echo 				"Exibir o valor da variável"
echo "#--------------------------------------------------------#"
echo $inet_value
sudo sed -i 's/#        server_name     example.com;/        server_name     '$inet_value';/' /etc/nginx/conf.d/zabbix.conf
sudo sed -i '42s/^/#/' /etc/nginx/nginx.conf
sudo sed -i '43s/^/        root         \/usr\/\share\/\zabbix;'/ /etc/nginx/nginx.conf
echo "#--------------------------------------------------------#"
echo    "Habilitando os serviços no início do boot do servidor"
echo "#--------------------------------------------------------#"
sudo systemctl restart zabbix-server zabbix-agent2 nginx php8.3-fpm
sudo systemctl enable zabbix-server zabbix-agent2 nginx php8.3-fpm

echo "Parabéns, seu Zabbix instalado com sucesso !"
#==     show access url ==#
echo    "########============================================########"
echo    "######## URL de acesso : http://$inet_value/        ########"
echo    "######## Usuário Zabbix: Admin                      ########"
echo    "######## Senha: zabbix                              ########"
echo    "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo    "######## Note: Não esqueça de mudar a senha depois  ########"
echo    "########============================================########"

sleep 10

echo "Baixando, instalando e configurando o Grafana"
echo "Preparando o ambiente para instalar o Grafana"
sudo apt-get install -y adduser libfontconfig1 musl
sudo wget https://dl.grafana.com/oss/release/grafana_11.5.2_amd64.deb
sudo dpkg -i grafana_11.5.2_amd64.deb

echo "Parabéns, seu Grafana foi instalado com sucesso !"
#==     show access url ==#
echo    "########============================================########"
echo    "######## URL de acesso : http://$inet_value:3000    ########"
echo    "######## Usuário Grafana: admin                     ########"
echo    "######## Senha: admin                               ########"
echo    "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo    "######## Note: Não esqueça de mudar a senha depois  ########"
echo    "########============================================########"

sleep 10

sudo systemctl start grafana-server
sudo systemctl enable grafana-server	
