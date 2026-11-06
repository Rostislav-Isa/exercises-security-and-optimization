#!/bin/sh
#
# builder.sh - Clone a GitHub repository, build its Docker image and push it.
#
# Usage: ./builder.sh <github-repo> <docker-image>
#   <github-repo>   GitHub repository as owner/name, e.g. octocat/hello-world
#   <docker-image>  Docker Hub repository as owner/name, e.g. octocat/hello-world
#                   (pushed as :latest)

set -eu

usage() {
  echo "Usage: $(basename "$0") <github-repo> <docker-image>" >&2
  echo "  <github-repo>   GitHub owner/name, e.g. octocat/hello-world" >&2
  echo "  <docker-image>  Docker Hub owner/name, e.g. octocat/hello-world" >&2
}

die() {
  echo "Error: $*" >&2
  exit 1
}

if [ "$#" -ne 2 ]; then
  usage
  exit 2
fi

github_repo=$1
docker_image=$2

# Fail early if required tools are missing.
for cmd in git docker; do
  command -v "$cmd" >/dev/null 2>&1 || die "'$cmd' is not installed or not in PATH"
done

# Both arguments must be lowercase "owner/name" (no URLs, hosts or tags).
# Docker Hub requires lowercase; GitHub is case-insensitive, so one rule fits both.
for arg in "$github_repo" "$docker_image"; do
  case $arg in
    */*/* | /* | */ | *[!a-z0-9._/-]*) ;;
    */*) continue ;;
  esac
  die "arguments must be lowercase 'owner/name', got '$arg'"
done

repo_url="https://github.com/${github_repo}.git"

# Clone into a temporary directory.
temp_dir=$(mktemp -d)
trap 'rm -rf "$temp_dir"' EXIT
trap 'exit 130' HUP INT TERM

echo "==> Cloning $repo_url"
git clone --depth 1 --quiet -- "$repo_url" "$temp_dir"

[ -f "$temp_dir/Dockerfile" ] || die "no Dockerfile found at the root of $github_repo"

echo "==> Building $docker_image"
docker build --tag "$docker_image" "$temp_dir"

echo "==> Pushing $docker_image"
docker push "$docker_image"

echo "==> Done: $docker_image"
