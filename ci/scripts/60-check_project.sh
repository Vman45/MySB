#!/bin/bash
# ----------------------------------
#  __/\\\\____________/\\\\___________________/\\\\\\\\\\\____/\\\\\\\\\\\\\___
#   _\/\\\\\\________/\\\\\\_________________/\\\/////////\\\_\/\\\/////////\\\_
#	_\/\\\//\\\____/\\\//\\\____/\\\__/\\\__\//\\\______\///__\/\\\_______\/\\\_
#	 _\/\\\\///\\\/\\\/_\/\\\___\//\\\/\\\____\////\\\_________\/\\\\\\\\\\\\\\__
#	  _\/\\\__\///\\\/___\/\\\____\//\\\\\________\////\\\______\/\\\/////////\\\_
#	   _\/\\\____\///_____\/\\\_____\//\\\____________\////\\\___\/\\\_______\/\\\_
#		_\/\\\_____________\/\\\__/\\_/\\\______/\\\______\//\\\__\/\\\_______\/\\\_
#		 _\/\\\_____________\/\\\_\//\\\\/______\///\\\\\\\\\\\/___\/\\\\\\\\\\\\\/__
#		  _\///______________\///___\////__________\///////////_____\/////////////_____
#			By toulousain79 ---> https://github.com/toulousain79/
#
######################################################################
#
#	Copyright (c) 2013 toulousain79 (https://github.com/toulousain79/)
#	Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#	The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#	--> Licensed under the MIT license: http://www.opensource.org/licenses/mit-license.php
#
##################### FIRST LINE #####################################

# 1/ lister tous les fichiers .tmpl
# 2/ pour chaque fichier trouvé, rechercher si il est appelé
#   SI trouvé ALORS OK
#   SI trouvé ET commenté ALORS WARNING
#   SINON KO

if [ -z "${vars}" ] || [ "${vars}" -eq 0 ]; then
    # shellcheck source=ci/scripts/00-load_vars.bsh
    source "$(dirname "$0")/00-libs.bsh"
else
    nReturn=${nReturn}
fi

gfnCopyProject

# Templates files used
sFilesListTmpl="$(find "${sDirToScan}"/templates/ -type f -name "*.tmpl" -printf "%f\n" | sort -z | xargs -r0)"
if [ -n "${sFilesListTmpl}" ]; then
    echo && echo -e "${CBLUE}*** Check for unused templates ***${CEND}"
    for sFile in ${sFilesListTmpl}; do
        if (grep -q 'etc.logrotate.d.' <<<"${sFile}"); then
            case "${sFile}" in
                'etc.logrotate.d.users.tmpl')
                    if (! grep -qR --exclude-dir=.git "${sFile}" "${sDirToScan}"/); then
                        echo -e "${CYELLOW}${sDirToScan}/${sFile}:${CEND} ${CRED}Failed${CEND}"
                        nReturn=$((nReturn + 1))
                    else
                        echo -e "${CYELLOW}${sFile}:${CEND} ${CGREEN}Passed${CEND}"
                    fi
                    ;;
                *)
                    sString="$(echo "${sFile}" | cut -d '.' -f 4)"
                    if (! grep -qR --exclude-dir=.git "gfnLogRotate '${sString}'" "${sDirToScan}"/); then
                        echo -e "${CYELLOW}${sDirToScan}/${sFile}:${CEND} ${CRED}Failed${CEND}"
                        nReturn=$((nReturn + 1))
                    else
                        echo -e "${CYELLOW}${sFile}:${CEND} ${CGREEN}Passed${CEND}"
                    fi
                    ;;
            esac
        else
            if (! grep -qR --exclude-dir=.git "${sFile}" "${sDirToScan}"/); then
                echo -e "${CYELLOW}${sDirToScan}/${sFile}:${CEND} ${CRED}Failed${CEND}"
                nReturn=$((nReturn + 1))
            else
                echo -e "${CYELLOW}${sFile}:${CEND} ${CGREEN}Passed${CEND}"
            fi
        fi
    done
fi

# Templates files called
sLine="$(grep -rh --exclude-dir=ci --exclude-dir=.git '/templates/' "${sDirToScan}"/)"
if [ -n "${sLine}" ]; then
    echo && echo -e "${CBLUE}*** Check for missing templates ***${CEND}"
    for sColumn in ${sLine}; do
        sColumn="$(echo "${sColumn}" | sed "s/\"//g;s/'//g;s/)//g;s/;//g;")"
        if [ -n "${sColumn}" ]; then
            (grep -q "etc.logrotate.d.\${1}.tmpl" <<<"${sColumn}") && continue
            (grep -q '/templates/' <<<"${sColumn}") && {
                sTemplate="$(echo "${sColumn}" | cut -d '/' -f 4)"
                if [ -n "${sTemplate}" ]; then
                    sFile="$(find "${sDirToScan}"/templates/ -type f -name "${sTemplate}")"
                    if [ -n "${sFile}" ] && [ -f "${sFile}" ]; then
                        echo -e "${CYELLOW}${sTemplate}:${CEND} ${CGREEN}Passed${CEND}"
                    else
                        echo -e "${CYELLOW}${sTemplate}:${CEND} ${CRED}Failed${CEND}"
                        nReturn=$((nReturn + 1))
                    fi
                fi
            }
        fi
    done
fi

export nReturn

##################### LAST LINE ######################################
