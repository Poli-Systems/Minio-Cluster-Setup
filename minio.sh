#!/bin/bash
#Automatically install and configure minio
#By Poli Systems
While=1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
Opts='MINIO_OPTS="'


read -p "Enter the public hostname's of the machines (minimum 4, separated by spaces):" Hostname
Nserv=$(echo "$Hostname" | wc -w)


MyIP=$(curl ifconfig.me)
for X in $Hostname
do
        CurrentIP=$(getent ahostsv4 $X | awk '{print $1}' | head -1)
        if [[ $CurrentIP == $MyIP ]]
        then
                apt update 
                apt install certbot

                service lsws stop
                service apache2 stop
                service nginx stop

                mkdir -p /etc/minio/certs

                Domain=$(echo "$Hostname" | awk -F\. '{print $(NF-1) FS $NF}')
                certbot certonly --standalone -n -d $Hostname --staple-ocsp -m admin@${Domain} --agree-tos

                cp /etc/letsencrypt/live/${Hostname}/fullchain.pem /etc/minio/certs/public.crt
                cp /etc/letsencrypt/live/${Hostname}/privkey.pem /etc/minio/certs/private.key

                chown -R minio-user:minio-user /etc/minio
                chmod u+rxw /etc/minio

                service lsws start
                service apache2 start
                service nginx start
        fi

        Opts=${Opts}"https://${X}:9000/var/minio "

        let "While=While+1"
done
Opts=$Opts'-C /etc/minio"'

While=1

wget https://dl.min.io/server/minio/release/linux-amd64/minio
chmod +x minio
mv minio /usr/local/bin
wget https://dl.min.io/client/mc/release/linux-amd64/mc
chmod +x mc
mv mc /usr/local/bin

useradd -r minio-user -s /sbin/nologin
chown -R minio-user:minio-user /usr/local/bin/minio
read -p "Where do you want to store your minio data :" Folder
mkdir $Folder
chown -R minio-user:minio-user $Folder
chmod u+rxw $Folder
echo "Random keys"
head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 ; echo ''
head /dev/urandom | tr -dc A-Za-z0-9 | head -c 24 ; echo ''

echo ""
read -p "Which Access key do you want to use :" AccessKey
read -p "Which Secret key do you want to use :" SecretKey
echo "MINIO_ACCESS_KEY=\"$AccessKey\"" > /etc/default/minio
echo "MINIO_SECRET_KEY=\"$SecretKey\"" >> /etc/default/minio
echo 'MINIO_VOLUMES=""' >> /etc/default/minio
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

chown -R minio-user:minio-user /etc/minio

echo "Minio was installed and can be launched with 'service minio start' but don't forget the start all the machines at the same time the first time. Also copy the certs between the machines using copy-cert.sh for example."
