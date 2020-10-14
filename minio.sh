#!/bin/bash
While=1


echo "Il vous faut rajouter chaque hôte dans /etc/hosts dans le format minio-1 minio-2..."
read Nserv?"Combien de serveur minio aller vous connecter :"
wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio /usr/local/bin
useradd -r minio-user -s /sbin/nologin
chown minio-user:minio-user /usr/local/bin/minio
read Folder?"Ou voulez vous stocker les données de minio :"
mkdir $Folder
chown minio-user:minio-user $Folder
mkdir /etc/minio
chown minio-user:minio-user /etc/minio
mkdir /var/minio
chown minio-user:minio-user /var/minio


read AccessKey?"Quel access key shouaitez vous utiliser :"
read SecretKey?"Quel secret key shouaitez vous utiliser :"
echo "MINIO_ACCESS_KEY=\"$AccessKey\"" > /etc/default/minio
echo "MINIO_SECRET_KEY=\"$SecretKey\"" >> /etc/default/minio
echo 'MINIO_VOLUMES=""' >> /etc/default/minio
Opts='MINIO_OPTS="'
let "Nserv=Nserv+1"
while [[ $Nserv -ne $While ]]; do
        Opts=${Opts}"https://minio-${While}:9000/var/minio "
        let "While=While+1"
done
Opts=$Opts'-C /etc/minio"'
echo $Opts >> /etc/default/minio


apt update
apt install curl wget golang-go -y
wget -O generate_cert.go "https://golang.org/src/crypto/tls/generate_cert.go?m=text"
$IP=`curl ifconfig.me`
go run generate_cert.go -ca --host "$IP"
mv cert.pem /etc/minio/certs/public.crt
mv key.pem /etc/minio/certs/private.key


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

echo "Minio à été installer et peut-être lancer avec 'service minio start' cepandant n'oubliez pas que il faut lancer toutes les machines en même temps la première fois"
