#!/bin/zsh

# krsync - rsync current git working tree to k8s pod
#
# This utility helps you sync your current git working tree with a remote k8s
# pod. This assumes that the project is cloned under `/home/jovyan` on the
# remote pod. The repository name will be inferred from the current repository
# using `git rev-parse --show-toplevel`. For this to work, you also need to have
# rsync installed in the remote k8s pod (run: `sudo apt install rsync grsync`).
# Note that the `.git/` directory will not be synced. In addition to this,
# nothing in `.gitignore` will be synced.
#
# References:
#   * https://serverfault.com/questions/741670/rsync-files-to-a-kubernetes-pod
#
# Arguments:
#   * $1 : pod name
#
# Examples:
#   $ ./krsync.zsh my-pod
#   ...

pod="${1}"

top_level="$(git rev-parse --show-toplevel)"
destination="/home/jovyan/$(basename "${top_level}")"

echo -e "\033[1m--- Syncing details ---\033[0m"
echo "pod:  ${pod}"
echo "from: ${top_level}"
echo "to:   ${destination}"
echo -e "\033[1m--- Syncing details ---\033[0m"

rsync -av \
  --exclude='.git' --filter="dir-merge,- .gitignore" \
  --progress --stats \
  -e './krsync-subshell.sh' \
  "${top_level}/" \
  "${pod}:${destination}"
