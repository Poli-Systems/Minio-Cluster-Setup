#!/bin/bash
#Automatically install and configure minio
#By Poli Systems
While=1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"


echo "Il vous faut rajouter chaque hôte dans /etc/hosts dans le format minio-1 minio-2..."
read -p "Combien de serveur minio aller vous connecter (minimum 4 ou minio fonctionnera pas):" Nserv
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio /usr/local/bin
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin

useradd -r minio-user -s /sbin/nologin
chown -R minio-user:minio-user /usr/local/bin/minio
read -p "Ou voulez vous stocker les données de minio :" Folder
mkdir $Folder
chown -R minio-user:minio-user $Folder
chmod u+rxw $Folder
mkdir /etc/minio
chown -R minio-user:minio-user /etc/minio
chmod u+rxw /etc/minio


read -p "Quel access key shouaitez vous utiliser :" AccessKey
read -p "Quel secret key shouaitez vous utiliser :" SecretKey
echo "MINIO_ACCESS_KEY=\"$AccessKey\"" > /etc/default/minio
echo "MINIO_SECRET_KEY=\"$SecretKey\"" >> /etc/default/minio
echo 'MINIO_VOLUMES=""' >> /etc/default/minio
Opts='MINIO_OPTS="'
let "Nserv=Nserv+1"
while [[ $Nserv -ne $While ]]; do
        Opts=${Opts}"https://minio-${While}:9000/var/minio "
        Hostnames=${Hostnames}"minio-${While} "
        let "While=While+1"
done
Opts=$Opts'-C /etc/minio"'
echo $Opts >> /etc/default/minio


echo '[Unit]
Description=MinIO
Documentation=https://docs.min.io
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
WorkingDirectory=/usr/local/

User=minio-user
Group=minio-user

EnvironmentFile=/etc/default/minio

ExecStart=/usr/local/bin/minio server $MINIO_OPTS

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target

# Built for ${project.name}-${project.version} (${project.name})
' > /etc/systemd/system/minio.service
systemctl daemon-reload

service minio start
service minio stop
apt update
apt install curl wget golang-go -y
wget -O generate_cert.go "https://golang.org/src/crypto/tls/generate_cert.go?m=text"
go run generate_cert.go -ca --host "$Hostnames"
sleep 2s
mv ${DIR}/cert.pem /etc/minio/certs/public.crt
mv ${DIR}/key.pem /etc/minio/certs/private.key
chown minio-user:minio-user /etc/minio


echo "Minio à été installer et peut-être lancer avec 'service minio start' cepandant n'oubliez pas que il faut lancer toutes les machines en même temps la première fois"
echo "Avant de lancer minio copier chaque clé publique dans /etc/minio/certs/public.crt vers les différentes machines vers /etc/minio/certs/CAs/public.crt et faites un"
echo "chown -R minio-user:minio-user /etc/minio"
