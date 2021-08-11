# Miscellaneous how-tos, and code snippets

## Shell

### Ask for `sudo` password only once

Add this to the top of your shell script.

```shell script
################################################################################
# Ask for root password upfront and keep updating the existing `sudo`
# timestamp on a background process until the script finishes. Note that
# you'll still need to use `sudo` where needed throughout the scripts.
################################################################################
echo "Some of the commands in this script require root access. Enter your password to unable root access when necessary..."
sudo -v
while true; do
  sudo -n true
  sleep 30
  kill -0 "$$" || exit
done 2>/dev/null &
```

### `ffmpeg` - Video from images

```shell script
ffmpeg -framerate 24.994862 -i img%06d.png -c:v libx264 -vf fps=24.994862 -pix_fmt yuv420p myMovie.mp4
```

### [FIXME] Remove local CloudDocs copies

```shell script
# $ source ~/.zshrc

function _safer_evict() {
  input_path=$(realpath "$@")/
  # shellcheck disable=SC2034
  path_to_icloud=$(realpath ~/Library/Mobile\ Documents/com~apple~CloudDocs)/
  if [[ "${input_path##path_to_icloud}" != "${input_path}" ]]; then
    echo yes;
    echo "$input_path";
  fi
}

function _evictall() {
  _SAFER_EVICT=$(functions _safer_evict)
  #find "$1" -type f -not -name .DS_Store -a -not -name .\*.icloud -exec "$SHELL" -c '_safer_evict "$@"' -- {} \;
  #find "$1" -type f -not -name .DS_Store -a -not -name .\*.icloud -exec zsh -c '_safer_evict "$@"' zsh {} \;
  #  find "$1" -type f -not -name .DS_Store -a -not -name .\*.icloud -print0 | xargs -0 ls
  #find "$1" -type f -not -name .DS_Store -a -not -name .\*.icloud -print0 | xargs -0 bash -c '_safer_evict "$@"' _
  #find "$1" -type f -not -name .DS_Store -a -not -name .\*.icloud -print0 | xargs -0 -I{} "$SHELL" -c "eval $_SAFER_EVICT; _safer_evict {}"
  find "$1" -type f -not -name .DS_Store -a -not -name .\*.icloud -print0 | xargs -0 -I{} "$SHELL" -c "eval ${_SAFER_EVICT}; ls {}"
}

_evictall "$1"

```

## SQL

### Compare two queries

Use the following template to get the difference between two queries:

```sql
with q1 as (
    <INSERT_QUERY_1_HERE>
)
, q2 as (
    <INSERT_QUERY_2_HERE>
  )
select * from q1 except select * from q2
union all (
select * from q2 except select * from q1);
```

References:

- <https://stackoverflow.com/questions/11017678/sql-server-compare-results-of-two-queries-that-should-be-identical/63380681#63380681>

### [Amazon Redshift] Disable results caching for current session

```sql
set enable_result_cache_for_session to off;
```

References:

- <https://docs.aws.amazon.com/redshift/latest/dg/r_enable_result_cache_for_session.html>

## Kubernetes

### Beyond `kubectl cp`

kubectl's builtin `cp` utility can sometimes trow weird errors. This simple alternative gets the job done
most of the time. In addition to this, this alternative also compresses the target before sending it over the
network (to stdin) which can reduce the download times many fold. This is actually _similar_ to what runs
[behind the scenes](https://github.com/kubernetes/kubectl/blob/master/pkg/cmd/cp/cp.go) when you invoke the
`kubectl cp` utility, excluding the compression bit (the `z` flag). Note that this only works in the context
of copying files **from** a container! Enjoy, and happy hacking!

```shell
kubectl exec my-pod -- tar czf - /path/to/file/or/directory | tar xzf -
```

Now an even fancier alternative...

```shell
#!/bin/zsh

# kp - Copy files from a k8s pod
#
# I found some issues with kubectl's builtin cp utility.
# This script replaces the `kubectl cp` command for the
# case of copying file **from** a container only.
#
# Note that the target path should be relative to the
# top-level directory of the current git working tree.
#
# Execution details:
#   1. execute a command inside a pod
#   2. (inside pod) change directories to the current repository
#   3. (inside pod) tar and compress the target file(s)
#   4. (inside pod) print compressed tarball to stdout
#   5. read from tarball from stdout
#   6. decompress and export file(s) to current project
# Note: pv is a utility for monitoring the progress of data through a pipe
#
# Arguments:
#   * $1 : pod name
#   * $2 : target file or directory
#
# Examples:
#   $ ./kp.zsh my-pod path/to/target/dir
#   ...
#   $ ./kp.zsh my-pod path/to/target/file.txt
#   ...

pod="${1}"
target="${2}"

target_tgz="${target}.tar.gz"

echo "Creating archive ${target_tgz}"
kubectl exec "${pod}" -- tar czf "${target_tgz}" "${target}"

target_size="$(kubectl exec "${pod}" -- du -bs "${target_tgz}" | cut -f1)"

echo "Copying archive to ${target}"
kubectl exec "${pod}" -- \
  cat "${target_tgz}" |
  pv -s "${target_size}" |
  tar xzf -

echo "Removing archive from ${pod}"
kubectl exec "${pod}" -- rm -f "${target_tgz}"
```



### Sync current git working tree to a k8s pod

This utility helps you sync your current git working tree with a remote k8s pod. This assumes that the project
is cloned under `/home/jovyan` on the remote pod. The repository name will be inferred from the current
repository using `git rev-parse --show-toplevel`. For this to work, you also need to have rsync installed in
the remote k8s pod (run: `sudo apt install rsync grsync`). Note that the `.git/` directory will not be synced.
In addition to this, nothing in `.gitignore` will be synced.

Simply add a copy of [snippets/k8s/krsync.zsh](snippets/k8s/krsync.zsh) and
[snippets/k8s/krsync-subshell.sh](snippets/k8s/krsync-subshell.sh) to the top level directory of your git
repository and run `./krsync.zsh my-pod`.

- <https://serverfault.com/questions/741670/rsync-files-to-a-kubernetes-pod>

## Misc

### GitHub Markdown style on JetBrains IDEs

Inspired and adapted from <https://github.com/sindresorhus/github-markdown-css>

1. Open the `Preferences -> Language & Frameworks -> Markdown`
2. Copy the contents of [snippets/misc/github-markdown.css](snippets/misc/github-markdown.css) into the open
   text box under `Custom CSS -> Add CSS rules`

![img.png](assets/img/jetbrains_markdown_css_rules.png)

References:

- <https://www.jetbrains.com/help/idea/markdown.html#css>
