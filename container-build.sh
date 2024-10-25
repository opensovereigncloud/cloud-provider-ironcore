#!/bin/bash

set -e
start=`date +%s`
function timing()
{
  end=`date +%s`
  # shellcheck disable=SC2046
  echo Container build time was `expr $end - $start` seconds.
}
trap timing EXIT

cd $GOPATH || exit

img_mtr_path=$1
# commit can have values like e.g. dev, <tag value>, or <commit-ref name>
commit=$2
docker_target=$3

LABEL=""
if [[ "$commit" =~ ^feature-.*|^bugfix-.*|^v[0-9]+.[0-9]+.[0-9]+-[0-9]+.ci-.* ]]; then
    LABEL='--label quay.expires-after=30d'
    echo "set $LABEL"
fi



cd ${GOPATH}/src/${CI_SERVER_HOST}/${CI_PROJECT_PATH}.git
podman build --build-arg OSC_BUILD_VERSION=$commit --build-arg OSC_BUILD_COMMIT_SHA=${CI_COMMIT_SHA}  $LABEL --build-arg CI_SERVER_HOST=${CI_SERVER_HOST} --build-arg CI_PROJECT_PATH=${CI_PROJECT_PATH} --tag $docker_target:$commit --target ironcore-cloud-controller-manager -f Dockerfile .
podman tag $docker_target:$commit ${MTR_GITLAB_HOST}/$img_mtr_path:$commit
podman login -u $MTR_GITLAB_LOGIN -p $MTR_GITLAB_PASSWORD $MTR_GITLAB_HOST
podman push ${MTR_GITLAB_HOST}/$img_mtr_path:$commit

echo "third input. Docker target: $docker_target"
echo "CI_PROJECT_NAME: ${CI_PROJECT_NAME}"
echo "second input. Commit: $commit"
echo "MTR_GITLAB_HOST: ${MTR_GITLAB_HOST}"
echo "first input. MTR path: $img_mtr_path"
echo "CI_PROJECT_NAME: ${CI_PROJECT_NAME}"
echo "podman tag: ${CI_PROJECT_NAME}:$commit ${MTR_GITLAB_HOST}/$img_mtr_path:$commit"
echo "podman push: ${MTR_GITLAB_HOST}/$1:$commit"

# sign image in MTR based on digest
source ./cosign-main.sh
cosign-main $img_mtr_path $commit
