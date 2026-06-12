#!/usr/bin/env bash

# Cloudflare Workers runs this build hook during deployment.
# Keep the actual toolchain and commands in mise.toml so local and CI builds stay aligned.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_PARENT="$(dirname "${SCRIPT_DIR}")"
ORIGINAL_HOME="${HOME}"
cd "${SCRIPT_DIR}"

export HOME="${PWD}/.mise-ci/home"
export PATH="${PWD}/.mise-ci/bin:${HOME}/.local/bin:${HOME}/.mise/bin:${ORIGINAL_HOME}/.local/bin:${ORIGINAL_HOME}/.mise/bin:${PATH}"
export TZ="${TZ:-America/Sao_Paulo}"
export MISE_CEILING_PATHS="${REPO_PARENT}"
export MISE_CONFIG_DIR="${PWD}/.mise-ci/config"
export MISE_SYSTEM_CONFIG_DIR="${PWD}/.mise-ci/system"
export MISE_YES=1
export MISE_TRUSTED_CONFIG_PATHS="${PWD}/mise.toml"
export npm_config_cache="${npm_config_cache:-${PWD}/.npm}"
export ASDF_DIR="${ASDF_DIR:-${ORIGINAL_HOME}/.asdf}"
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-${ORIGINAL_HOME}/.asdf}"

mkdir -p "${HOME}" "${MISE_CONFIG_DIR}" "${MISE_SYSTEM_CONFIG_DIR}"

configured_hugo_version() {
  local version
  version="$(awk -F '"' '/^hugo-extended[[:space:]]*=/ { print $2; exit }' mise.toml)"
  if [[ -z "${version}" ]]; then
    echo "Unable to determine Hugo version from mise.toml" >&2
    exit 1
  fi
  printf '%s\n' "${version}"
}

hugo_is_ready() {
  if ! command -v hugo >/dev/null 2>&1; then
    return 1
  fi

  if [[ "$(uname -s)" != "Linux" ]]; then
    return 0
  fi

  hugo version 2>/dev/null | grep -q "v$(configured_hugo_version)"
}

install_hugo_direct() {
  local version os arch asset_platform archive_url install_dir tmp_dir

  version="$(configured_hugo_version)"

  os="$(uname -s)"
  arch="$(uname -m)"
  case "${os}-${arch}" in
    Linux-x86_64)
      asset_platform="linux-amd64"
      ;;
    Linux-aarch64|Linux-arm64)
      asset_platform="linux-arm64"
      ;;
    *)
      echo "Unsupported platform for direct Hugo install: ${os}-${arch}" >&2
      exit 1
      ;;
  esac

  install_dir="${PWD}/.mise-ci/bin"
  tmp_dir="${PWD}/.mise-ci/tmp/hugo-${version}"
  archive_url="https://github.com/gohugoio/hugo/releases/download/v${version}/hugo_extended_${version}_${asset_platform}.tar.gz"

  mkdir -p "${install_dir}" "${tmp_dir}"
  echo "Installing Hugo ${version} from direct release asset..."
  curl -fsSL --retry 3 --retry-delay 2 "${archive_url}" -o "${tmp_dir}/hugo.tar.gz"
  tar -xzf "${tmp_dir}/hugo.tar.gz" -C "${tmp_dir}" hugo
  install -m 0755 "${tmp_dir}/hugo" "${install_dir}/hugo"
}

if ! hugo_is_ready; then
  install_hugo_direct
  hash -r
fi

if ! command -v mise >/dev/null 2>&1; then
  echo "Installing mise..."
  curl -fsSL https://mise.run | sh
  hash -r
fi

command -v mise >/dev/null 2>&1 || {
  echo "mise was not found after installation" >&2
  exit 1
}

echo "Installing Node dependencies..."
HOME="${ORIGINAL_HOME}" npm ci --prefer-offline --no-audit --fund=false

mise ls --current || true
mise run --skip-tools --skip-deps build
