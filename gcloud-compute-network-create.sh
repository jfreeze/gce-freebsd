#!/bin/sh

usage ()
{
  echo "Usage : $(basename "$0") project-name network-name"
  exit
}

if [ "$#" -ne 2 ]
then
  usage
fi

run () {
CMD=$(cat <<EOF
  gcloud compute networks create "${2}" \
    --project "${1}" \
    --description "Network for ${1}" \
    --mode "auto"
EOF
)

  echo ${CMD}
  echo "${CMD}" | /bin/sh
}

run $1 $2
