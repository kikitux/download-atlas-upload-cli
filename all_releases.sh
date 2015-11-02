#!/bin/bash
set -e

which curl jq >/dev/null || exit 1

baseurl="http://releases.hashicorp.com"
curl -R -sSL -o index.json ${baseurl}/index.json || exit 1

echo "k = shasum passed, c = verified file is current, d = downloaded"

echo "checking files.. "
#while read loop
#-R to set timestap as source, -z to compare with local file if exist
#if file change in source, we will redownload. This only happen when same file is published again. say a bad bug.
cat index.json | jq -r '.[].versions[].builds[]| "\(.name)/\(.version) \(.filename) \(.url)"' | while read -r dir file url; do
  unset is304
  [ -d ${dir} ] || mkdir -p ${dir}
  if [ -f ${dir}/${file}.ok ] ; then
    echo -n "k"
  elif [ -f ${dir}/${file} ] ; then
    is304="`curl -R -sSLR -i -z ${dir}/${file} -o /dev/null --write-out '%{http_code}' ${url}`"
    if [ ${is304} -eq 304 ]; then
      echo -n "c"
    else
      curl -R -sSL -z ${dir}/${file} -o ${dir}/${file} ${url}
      echo -n "d"
    fi
  else
    curl -R -sSL -o ${dir}/${file} ${url}
    echo -n "d"
  fi
done
echo " done"

echo "checking shasums.. "
cat index.json | jq -r '.[].versions[]|"\(.name)/\(.version) \(.shasums) \(.shasums_signature)"' | while read -r dir shasums shasums_signature; do
  unset issig304 issum304
  if [ -f ${dir}/${shasums_signature} ] ; then
    issig304="`curl -R -sSLR -i -z ${dir}/${shasums_signature} -o /dev/null --write-out '%{http_code}' ${baseurl}/${dir}/${shasums_signature}`"
    if [ ${issig304} -eq 304 ]; then
      echo -n "c"
    else
      curl -R -sSL -z ${dir}/${shasums_signature} -o ${dir}/${shasums_signature} ${baseurl}/${dir}/${shasums_signature}
      echo -n "d"
    fi
  else
    curl -R -sSL -o ${dir}/${shasums_signature} ${baseurl}/${dir}/${shasums_signature}
    echo -n "d"
    issig304="1"
  fi
  if [ -f ${dir}/${shasums} ] ; then
    issum304="`curl -R -sSLR -i -z ${dir}/${shasums} -o /dev/null --write-out '%{http_code}' ${baseurl}/${dir}/${shasums}`"
    if [ ${issum304} -eq 304 ]; then
      echo -n "c"
    else
      curl -R -sSL -z ${dir}/${shasums} -o ${dir}/${shasums} ${baseurl}/${dir}/${shasums}
      echo -n "d"
    fi
  else
    curl -R -sSL -o ${dir}/${shasums} ${baseurl}/${dir}/${shasums}
    echo -n "d"
    issum304="1"
  fi
  if [ ${issig304} -ne 304 ] || [ ${issum304} -ne 304 ]; then
    echo " gpg"
    gpg --verify ${dir}/${shasums_signature} ${dir}/${shasums} || exit 1
  fi
  pushd ${dir} &>/dev/null
  cat ${shasums} | while read -r sha file ; do
    if [ ! -f ${file}.ok ]; then
      echo "${sha}  ${file}" | tee ${file}.tmp | shasum -a 256 -c
      if [ ${?} -eq 0 ];then
        mv ${file}.tmp ${file}.ok
      else
        rm ${file}.ok
      fi
    fi
  done
  popd &>/dev/null
done
echo " done"
