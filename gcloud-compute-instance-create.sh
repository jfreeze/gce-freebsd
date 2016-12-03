#!/bin/sh

CMD=$(cat <<EOF
gcloud compute instances create ${2} \
  --project ${1} \
  --zone "us-central1-a" \
  --machine-type "f1-micro" \
  --network "${1}-net" \
  --tags "pingable,sshable,http-server" \
  --image freebsd-11-0-release-amd64 \
  --image-project=freebsd-org-cloud-dev \
  --boot-disk-device-name "${2}-bootdisk" \
  --no-address \
  --boot-disk-size "40" 
EOF
)

#  --subnet "${1}-net" \
echo "${CMD}"
echo "${CMD}" | /bin/sh
