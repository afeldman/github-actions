#!/usr/bin/env bash

set -euo pipefail

echo "--------------------------------------------------------"
echo "Patch Helm values"
echo "--------------------------------------------------------"

if [[ ! -f "${VALUES_FILE}" ]]; then
    echo "ERROR: values file '${VALUES_FILE}' not found."
    exit 1
fi

# --------------------------------------------------------
# Defaults
# --------------------------------------------------------

IMAGE_TAG="${INPUT_IMAGE_TAG}"
IMAGE_PULL_POLICY="${INPUT_IMAGE_PULL_POLICY}"

IMAGE_REPOSITORY="${INPUT_IMAGE_REPOSITORY}"
ORGANIZATION="${INPUT_ORGANIZATION}"

REPOSITORY_NAME="${GITHUB_REPOSITORY##*/}"

if [[ -z "${IMAGE_REPOSITORY}" ]]; then

    if [[ -n "${ORGANIZATION}" ]]; then
        IMAGE_REPOSITORY="${INPUT_HOST}/${ORGANIZATION}/${REPOSITORY_NAME}"
    else
        IMAGE_REPOSITORY="${INPUT_HOST}/${GITHUB_REPOSITORY}"
    fi

fi

# Default Tag
if [[ -z "${IMAGE_TAG}" ]]; then
    IMAGE_TAG="${GITHUB_REF_NAME}"
fi

# Default Pull Policy
if [[ -z "${IMAGE_PULL_POLICY}" ]]; then
    IMAGE_PULL_POLICY="IfNotPresent"
fi

echo "Using:"
echo "  Repository : ${IMAGE_REPOSITORY}"
echo "  Tag        : ${IMAGE_TAG}"
echo "  PullPolicy : ${IMAGE_PULL_POLICY}"

export IMAGE_REPOSITORY
export IMAGE_TAG
export IMAGE_PULL_POLICY

# --------------------------------------------------------
# Patch values.yaml
# --------------------------------------------------------

yq -i '
.image.repository = env(IMAGE_REPOSITORY) |
.image.tag = env(IMAGE_TAG) |
.image.pullPolicy = env(IMAGE_PULL_POLICY)
' "${VALUES_FILE}"

# --------------------------------------------------------
# Patch Chart.yaml (optional)
# --------------------------------------------------------

#CHART_FILE="$(dirname "${VALUES_FILE}")/Chart.yaml"

#if [[ -f "${CHART_FILE}" ]]; then
#    echo
#    echo "Patching ${CHART_FILE}"

    # Keep appVersion in sync with the image tag
#    yq -i '
#    .appVersion = env(IMAGE_TAG)
#    ' "${CHART_FILE}"

#    echo
#    echo "Updated Chart.yaml:"

#    yq '
#    {
#      version: .version,
#      appVersion: .appVersion
#    }
#    ' "${CHART_FILE}"
#fi

echo
echo "Patched ${VALUES_FILE}:"

yq '.image' "${VALUES_FILE}"
