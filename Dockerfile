FROM ubuntu:22.04

LABEL "com.github.actions.name"="ACTION: TYPO3 DEPLOYMENT"
LABEL "com.github.actions.description"="Deploy your TYPO3 project via ssh and rsync"
LABEL "com.github.actions.icon"="upload-cloud"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="https://github.com/mai-space/action-typo3-deployment"
LABEL "homepage"="https://maispace.de"
LABEL "maintainer"="Joel Mai <joel@maispace.de>"

RUN apt-get update && apt-get install -y sshpass rsync openssh-client

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
