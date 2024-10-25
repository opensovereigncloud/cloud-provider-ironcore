#!/bin/bash

cosign-main(){
  # define variables
  img_mtr_path=$1
  # commit can have values like e.g. dev, <tag value>, or <commit-ref name>
  commit=$2

  #main job
  echo "[INFO] cosign login to MTR ..."
  cosign login "${OSC_HOST}" -u "${MTR_GITLAB_LOGIN}" -p "${MTR_GITLAB_PASSWORD}"

  echo "[INFO] check image digest from MTR ..."
  echo "curl -sS -X GET -H "Authorization: Bearer $MTR_GITLAB_TOKEN" https://$OSC_HOST/api/v1/repository/${img_mtr_path} | jq -er '[.tags.'\"$commit\"'.manifest_digest] | sort []'"

  image_digest=$(curl -sS -X GET -H "Authorization: Bearer $MTR_GITLAB_TOKEN" https://$OSC_HOST/api/v1/repository/${img_mtr_path} | jq -er '[.tags.'\"$commit\"'.manifest_digest] | sort []')
  echo "$image_digest"

  if [[ -z $image_digest ]] || [[ ${image_digest} == "nill" ]]; then

    echo "[WARNING] unable to check image digest from MTR"

  else

    echo "[INFO] Sign image in MTR via cosign ..."
    yes y | cosign sign "${MTR_GITLAB_HOST}"/"${img_mtr_path}"@"${image_digest}" --key "${OSC_COSIGN_KEY}"

    echo "[INFO] Verify signature for image in MTR"
    cosign verify "${MTR_GITLAB_HOST}"/"${img_mtr_path}"@"${image_digest}" --key "${OSC_COSIGN_KEY_PUB}" | jq -er .

fi

}
