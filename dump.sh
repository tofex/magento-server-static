#!/bin/bash -e

scriptName="${0##*/}"

usage()
{
cat >&2 << EOF
usage: ${scriptName} options

OPTIONS:
  -h  Show this message
  -u  Upload file to Tofex server

Example: ${scriptName} -u
EOF
}

trim()
{
  echo -n "$1" | xargs
}

upload=0

while getopts hu? option; do
  case "${option}" in
    h) usage; exit 1;;
    u) upload=1;;
    ?) usage; exit 1;;
  esac
done

currentPath="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -f "${currentPath}/../env.properties" ]]; then
    echo "No environment specified!"
    exit 1
fi

serverList=( $(ini-parse "${currentPath}/../env.properties" "yes" "system" "server") )
if [[ "${#serverList[@]}" -eq 0 ]]; then
  echo "No servers specified!"
  exit 1
fi

for server in "${serverList[@]}"; do
  webServer=$(ini-parse "${currentPath}/../env.properties" "no" "${server}" "webServer")

  if [[ -n "${webServer}" ]]; then
    serverType=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "type")

    if [[ "${serverType}" == "local" ]]; then
      webPath=$(ini-parse "${currentPath}/../env.properties" "yes" "${server}" "webPath")

      if [[ -d "${webPath}" ]]; then
        echo "Dumping static content on local server: ${server}"

        sourcePath=${webPath}/pub/static
        cd "${sourcePath}"

        dumpPath=${currentPath}/dumps
        mkdir -p "${dumpPath}"

        date=$(date +%Y-%m-%d)

        tar -zcf "${dumpPath}/static-${date}.tar.gz" .

        if [[ ${upload} == 1 ]]; then
          "${currentPath}/upload-dump.sh" -d "${date}"
        fi
      else
        echo "Missing web path at: ${webPath}"
      fi
    fi
  fi
done
