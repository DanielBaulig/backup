#!/bin/bash

while [[ ${#} > 0 ]]
do
    key="${1}"

    case ${key} in
        -f|--force)
            FORCE="1"
            ;;
        -g|--gpg)
            GPGTARGET="${2}"
            shift
            ;;
        -s|--source)
            SOURCE="${2}"
            shift
            ;;
        -d|--destination)
            DESTINATION="${2}"
            shift
            ;;
        *)
            # unknown option
            ;;
    esac
    shift

done

encrypt() {
    gpg -e -r ${gpgtarget} --batch -
}

decrypt() {
    gpg -d --batch
}

backup_dir() {
    backup_files ${1} ${2} .
}

backup_files() {
    local src=$1
    if [ ! -d "${src}" ] ; then
        echo "${src} is not a directory." 1>&2
        exit 1
    fi
    local dst=$2
    shift 2
    if [ "${gpg}" == "1" ]; then
        dst=${dst}.tar.gz.gpg
        if [ -f "${dst}" -a "${FORCE}" != "1" ] ; then
            echo "${dst} exists. Use -f to force overwrite" 1>&2
            exit 2
        fi
        tar czf - -C ${src} "$@" |encrypt >${dst}
    else
        dst=${dst}.tar.gz
        if [ -f "${dst}" -a "${FORCE}" != "1" ] ; then
            echo "${dst} exists. Use -f to force overwrite" 1>&2
            exit 2
        fi
        tar czf - -C ${src} "$@" >${dst}
    fi
}

load_vars() {
    local backup_conf=~/.backup.conf
    if [ -f "${backup_conf}" ]; then
        echo $(cat ${backup_conf} |grep -v ^# |xargs)
    fi
}

vars=$(load_vars)
if [ -n "${vars}" ] ; then
    declare ${vars}
fi

if [ -n "${GPGTARGET}" ] ; then
    gpg=1
    gpgtarget=${GPGTARGET}
fi

if [ -z "${SOURCE}" -o -z "${DESTINATION}" ] ; then
    echo "Provide source and destination."
    exit 3
fi

backup_dir $SOURCE $DESTINATION
