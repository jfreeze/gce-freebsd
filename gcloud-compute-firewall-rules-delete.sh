#!/bin/sh

usage ()
{
  echo "Usage : $(basename "$0") project-name"
  echo "Deletes the default firewall rules"
  exit
}

if [ "$#" -ne 1 ]
then
  usage
fi

run () {
  CMD1=$(cat <<EOF
  gcloud compute firewall-rules delete "default-allow-icmp" \
      --project "${1}"
EOF
)

  CMD2=$(cat <<EOF
  gcloud compute firewall-rules delete "default-allow-internal" \
      --project "${1}"
EOF
)

  CMD3=$(cat <<EOF
  gcloud compute firewall-rules delete "default-allow-rdp" \
      --project "${1}"
EOF
)

  CMD4=$(cat <<EOF
  gcloud compute firewall-rules delete "default-allow-ssh" \
      --project "${1}"
EOF
)

  echo ${CMD1}
  echo ${CMD2}
  echo ${CMD3}
  echo ${CMD4}

  echo "${CMD1}" | /bin/sh
  echo "${CMD2}" | /bin/sh
  echo "${CMD3}" | /bin/sh
  echo "${CMD4}" | /bin/sh
}

run $1
