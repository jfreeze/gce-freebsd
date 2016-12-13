#!/bin/sh

usage ()
{
  echo "Usage : $(basename "$0") project-name instance-name network-name"
  exit
}

if [ "$#" -ne 3 ]
then
  usage
fi

run () {
  CMD=$(cat <<EOF
  gcloud compute instances create ${2} \
    --project "${1}" \
    --zone "us-central1-a" \
    --machine-type "f1-micro" \
    --tags "pingable,sshable,http-server,https-server" \
    --subnet "${3}" \
    --image freebsd-11-0-release-amd64 \
    --image-project=freebsd-org-cloud-dev \
    --boot-disk-device-name "${2}-bootdisk" \
    --boot-disk-size "40" 
EOF
)

  echo ${CMD}
  echo "${CMD}" | /bin/sh
}

run $1 $2 $3
