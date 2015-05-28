#!/usr/bin/env bash
set -ex

function get_version_from_string () {
  cat - | sed -E 's/.*\(([0-9\.]+)\).*/\1/'
}

function build_image () {
  local image_name=${1}
  local tag=${2:-latest}
  docker build --pull --file Dockerfile-build --tag ${image_name}:${tag} . \
      && docker push ${image_name}:${tag}
}

markup=$(curl --silent http://jenkins-ci.org/)
weekly_version=$(echo "$markup" | grep -Eo 'Latest and greatest[^<]+' | get_version_from_string)
stable_version=$(echo "$markup" | grep -Eo 'Older but stable[^<]+' | get_version_from_string)

# Build weekly image
sed -E \
    -e "s/ENV JENKINS_VERSION .+/ENV JENKINS_VERSION ${weekly_version}/" \
    Dockerfile > Dockerfile-build
build_image mikewhy/jenkins-weekly latest
build_image mikewhy/jenkins-weekly ${weekly_version}

# Build stable image
sed -E \
    -e "s/ENV JENKINS_VERSION .+/ENV JENKINS_VERSION ${stable_version}/" \
    -e "s|/war/|/war-stable/|g" \
    Dockerfile > Dockerfile-build
build_image mikewhy/jenkins-weekly stable
build_image mikewhy/jenkins-weekly ${stable_version}
