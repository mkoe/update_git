#!/usr/bin/env bash

#set -x

######## CONFIG #######
# You can place your config in ~/.updategit 
# This will overwrite the following Parameter
# Enter your PATH
ROOTPATH="/XXX/XXXX/XXXXX"
IFS=$'\n';
DEBUG=1
SKIP_REPO="XXXXXXXXXXXX"
PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games"
# Get your own PRIV TOKEN ;-)
PRIVTOKEN="XXXXXXXXXXXX"
URL="XXXXXXXXXXXX"
ERRORCOUNT=0
######## CONFIG #######

if [[ -e ~/.updategit ]]
then
	source ~/.updategit 
fi

function debug() {

		if [[ ${DEBUG} -eq 1 ]]
		then
			echo $1
		fi
}


function check_software() {

	for SOFTWARE in curl awk jq 
	do
		debug "Checking for ${SOFTWARE}"
		if ( ! which ${SOFTWARE} > /dev/null 2>&1)
		then
			echo "Please install missing software ${SOFTWARE}"
			ERRORCOUNT=$((ERRORCOUNT+1))
		fi
	done
	if [[ ${ERRORCOUNT} -gt 0 ]]
	then
		echo "Fix the previous ${ERRORCOUNT} Errors"
		exit 1;
	fi

}

function check_dir() {

DIR=$(echo $1 | awk '{print $1}')

if ( ! echo ${SKIP_REPO} | grep ${DIR} > /dev/null 2>&1 )
then
	if [[ ! -e ${ROOTPATH}/${DIR} ]]
	then
		debug "Make directory ${DIR}"
		mkdir -p ${ROOTPATH}/${DIR}
		cd ${ROOTPATH}/${DIR}
		debug "Git init"
		git init
	fi
else
	debug "Skipping (check_dir) Repo ${DIR} because it is not wanted"
fi
}

function check_repo() {
DIR=$(echo $1 | awk '{print $1}')
REPOPATH=$(echo $1 | awk '{print $2}')
REPOS=$(echo $1 | awk '{print $3}')

if ( ! echo ${SKIP_REPO} | grep ${DIR} > /dev/null 2>&1 )
then
	if [[ -e ${ROOTPATH}/${DIR}/${REPOPATH} ]]
	then
		cd ${ROOTPATH}/${DIR}/${REPOPATH}
		debug "Updating Repo ${REPOPATH}"
		git pull
	else
		cd ${ROOTPATH}/${DIR}
		debug "Cloning Repo ${REPOS}"
		git clone ${REPOS}
	fi
else
	debug "Skipping (check_repo) Repo ${REPOS} because it is not wanted"
fi	
}

check_software

# Search for new projects and clone them
for REPO in $(curl -s -k  -H "PRIVATE-TOKEN: ${PRIVTOKEN}"  "https://${URL}/?per_page=999" | jq '. | map([.namespace.path , .path ,  .ssh_url_to_repo ] | join (", "))' | grep -v -E "\[|\]" | sed 's#[",]##g');
do
	PAGE_STATUS=$(curl -o /dev/null -I -s -k  -w "%{http_code}\n"   -H "PRIVATE-TOKEN: ${PRIVTOKEN}"  "https://${URL}/")
	if [[ ${PAGE_STATUS} -eq 200 ]]
	then
		debug "Variables: ${REPO}"
		check_dir ${REPO}
		debug "Variables: ${REPO}"
		check_repo ${REPO}
	else
		echo "Wrong ${PAGE_STATUS}"
	fi
done


