#!/bin/bash
#title           :gitlab_upgrade.sh
#description     :This script will update a self-hosted Gitlab Server automatically.
#author		       :nextleveldevops (nextleveldevops@gmail.com)
#date            :02-02-2023
#version         :1.0    
#usage		       :./gitlab_upgrade.sh
#notes           :install curl and jq to use this script.
#==============================================================================

# Declare variables:
SCRIPT_HOME="$HOME/scripts/gitlab_upgrade"
GITLAB_HOME="$HOME/gitlab-sandbox"
GITLAB_EDITION="gitlab/gitlab-ee" # Enterprise edition
# GITLAB_EDITION="gitlab/gitlab-ce" # Community edition
LOG_FILE="$SCRIPT_HOME/gitlab_upgrade.log"
DIGEST_CURRENT=$(docker inspect $(docker images -q)  | grep -m1 "${GITLAB_EDITION}@" | awk -F@ '{print $2}' | cut -d '"' -f1)
DIGEST_LATEST=$(curl -s https://hub.docker.com/v2/repositories/gitlab/gitlab-ee/tags |  jq -r '.results[] | select(.name=="latest") | .digest')
VERSION_CURRENT=$(cat "${GITLAB_HOME}"/data/gitlab-rails/VERSION)
IMAGE_ID_CURRENT=$(docker images -q "${GITLAB_EDITION}")

# Direct standart and error outputs to log-file: 
exec >> $LOG_FILE 2>&1

# Check if new version is available:
if [[ $DIGEST_CURRENT != $DIGEST_LATEST ]]
    then
	# If upgrade available 
	# Report of the upgrade starting to log-file and telegram:
	echo -e "\e[31m$(date '+%d-%m-%Y %H-%M-%S')\e[0m"
	echo -e "\e[33mCurrent GitLab version is: ${VERSION_CURRENT}\e[0m"
	echo -e "\e[32mNew version of GitLab is available...\e[0m"

	# start pulling new version in background:
	docker pull ${GITLAB_EDITION}:latest
	/usr/bin/telegram-send "GitLab ${VERSION_CURRENT} upgrade started..." >/dev/null
	
	# Restart docker-compose with latest Gitlab image:
	cd $GITLAB_HOME && \
        docker compose down && \
	# Remove old Gitlab image:
	docker rmi $IMAGE_ID_CURRENT

	# Start Gitlab with latest image:
	docker compose up -d && \
	# Wait 30 sec until VERSION file is being updated:
	sleep 30 && \
	VERSION_LATEST=$(cat "${GITLAB_HOME}"/data/gitlab-rails/VERSION) && \
	# Report of the upgrade completeion to log-file & Telegram:
	echo -e "\e[32mGitLab successfully upgraded to version: $VERSION_LATEST\e[0m" && \
	echo -e "\e[33m------------------------------------------------ \e[0m"
	MESSAGE="GitLab version:$VERSION_CURRENT has been successfully upgraded to version: $VERSION_LATEST" && \
	/usr/bin/telegram-send "${MESSAGE}" >/dev/null
fi
exit 0
