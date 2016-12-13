#!/bin/sh

usage ()
{
  echo "Usage : $(basename "$0") project-name network-name"
  echo "Creates 5 default firewall rules"
  echo "allpw-http, allow-http2, allow-icmp, allow-internal, allow-ssh"
  exit
}

if [ "$#" -ne 2 ]
then
  usage
fi


run () {

CMD1=$(cat <<EOF
  gcloud compute firewall-rules create "${2}-allow-http" \
  --project "${1}" \
  --network "${2}" \
  --allow tcp:80 \
  --source-ranges "0.0.0.0/0" \
  --target-tags "http-server"
EOF
)

CMD2=$(cat <<EOF
gcloud compute firewall-rules create "${2}-allow-https" \
  --project "${1}" \
  --network "${2}" \
  --allow tcp:443 \
  --source-ranges "0.0.0.0/0" \
  --target-tags "https-server"
EOF
)

CMD3=$(cat <<EOF
gcloud compute firewall-rules create "${2}-icmp"\
  --project "${1}" \
  --network "${2}" \
  --allow icmp \
  --description "Allows ICMP connections from any source to any instance on the network." \
  --source-ranges "0.0.0.0/0" \
  --target-tags pingable
EOF
)

CMD4=$(cat <<EOF
gcloud compute firewall-rules create "${2}-allow-internal" \
  --project "${1}" \
  --network "${2}" \
  --allow tcp:0-65535,udp:0-65535,icmp \
  --description "Allows connections from any source in the network IP range to any instance on the network using TCP and UDP ports 1-65535 plus ICMP." \
  --source-ranges "10.128.0.0/9"
EOF
)

CMD5=$(cat <<EOF
gcloud compute firewall-rules create "${2}-allow-ssh"\
  --project "${1}" \
  --network "${2}" \
  --allow tcp:22 \
  --description "Allows TCP connections from any source to any instance on the network using port 22." \
  --source-ranges "0.0.0.0/0" \
  --target-tags sshable
EOF
)

  echo ${CMD1}
  echo ${CMD2}
  echo ${CMD3}
  echo ${CMD4}
  echo ${CMD5}

  echo "${CMD1}" | /bin/sh
  echo "${CMD2}" | /bin/sh
  echo "${CMD3}" | /bin/sh
  echo "${CMD4}" | /bin/sh
  echo "${CMD5}" | /bin/sh
}

run $1 $2
