#!/bin/bash

PORT=17000
RPCPORT=17001
CONF_DIR=~/.spectra
COINZIP='https://github.com/Spectra-blockchain/SPC/releases/download/v1.1/spectra-linux.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/spectra.service
[Unit]
Description=Spectra Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/spectrad
ExecStop=-/usr/local/bin/spectra-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable spectra.service
  systemctl start spectra.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  rm spectra-qt spectra-tx spectra-linux.zip
  chmod +x spectra*
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget http://cdn.delion.xyz/spc.zip
  unzip spc.zip
  rm spc.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> spectra.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> spectra.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> spectra.conf_TEMP
  echo "rpcport=$RPCPORT" >> spectra.conf_TEMP
  echo "listen=1" >> spectra.conf_TEMP
  echo "server=1" >> spectra.conf_TEMP
  echo "daemon=1" >> spectra.conf_TEMP
  echo "maxconnections=250" >> spectra.conf_TEMP
  echo "masternode=1" >> spectra.conf_TEMP
  echo "" >> spectra.conf_TEMP
  echo "port=$PORT" >> spectra.conf_TEMP
  echo "externalip=$IP:$PORT" >> spectra.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> spectra.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> spectra.conf_TEMP
  mv spectra.conf_TEMP spectra.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start Spectra Service: ${GREEN}systemctl start spectra${NC}"
echo -e "Check Spectra Status Service: ${GREEN}systemctl status spectra${NC}"
echo -e "Stop Spectra Service: ${GREEN}systemctl stop spectra${NC}"
echo -e "Check Masternode Status: ${GREEN}spectra-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}Spectra Masternode Installation Done${NC}"
exec bash
exit
