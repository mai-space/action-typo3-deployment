#!/usr/bin/env bash
set -e

# COLORS
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
PURPLE='\033[1;35m'
ORANGE='\033[0;33m'
NO_COLOR='\033[0m'

ERROR=${RED}
SUCCESS=${GREEN}
PROMPT=${BLUE}
PREVIEW=${ORANGE}
DESCRIPTION=${PURPLE}
NC=${NO_COLOR}

# FANCY OUTPUTS
function cmd_success() {
    msg="$*"
    line=$(echo "$msg" | sed 's/./─/g')
    topedge="${SUCCESS}┌─$line─┐${NC}"
    botedge="${SUCCESS}└─$line─┘${NC}"
    msg="${SUCCESS}│${NC} $* ${SUCCESS}│${NC}"
    echo -e "$topedge"
    echo -e "$msg"
    echo -e "$botedge"
    echo ""
}

function cmd_error() {
    msg="$*"
    line=$(echo "$msg" | sed 's/./─/g')
    topedge="${ERROR}┌─$line─┐${NC}"
    botedge="${ERROR}└─$line─┘${NC}"
    msg="${ERROR}│${NC} $* ${ERROR}│${NC}"
    echo -e "$topedge"
    echo -e "$msg"
    echo -e "$botedge"
    echo ""
}

function cmd_describe() {
    msg="$*"
    line=$(echo "$msg" | sed 's/./─/g')
    topedge="${PRUPLE}┌─$line─┐${NC}"
    botedge="${PRUPLE}└─$line─┘${NC}"
    msg="${PRUPLE}│${NC} $* ${PRUPLE}│${NC}"
    echo -e "$topedge"
    echo -e "$msg"
    echo -e "$botedge"
    echo ""
}

function cmd_run() {
    msg="${PREVIEW}» $*${NC}"
    echo -e "$msg"
    echo ""
}

function confirm() {
    msg="${SUCCESS}✓ $*${NC}"
    echo -e "$msg"
    echo ""
}

function info() {
    msg="${PROMPT}> $*${NC}"
    echo -e "$msg"
}

# ECHO USED ENVIRONMENT VARIABLES
DATE_NOW=$(date +"%Y_%m_%d-%H_%M")
info "Using environment variables for deployment: ${DATE_NOW}"
info "SSH CONFIG: ${REMOTE_USERNAME}@${REMOTE_HOST}:${SSH_PORT}"
info "TO SITE: ${BASE_URL} with TYPO3_CONTEXT=${TYPO3_CONTEXT} and PHP_VERSION=${PHP_VERSION}"
info "TYPO3 project at: ${REMOTE_PATH}"
info "TYPO3 releases at: ${REMOTE_PATH}/releases"
info "TYPO3 shared at: ${REMOTE_PATH}/shared"
info "File storages: ${ADDITIONAL_FILE_STORAGES}"

cmd_run "Building path variables"
CURRENT_DIR=$(pwd)
DOCUMENT_ROOT="public"
DOCUMENT_DEPTH_PATH="../../.."
DEPLOY_PATH="$REMOTE_PATH/releases/$DATE_NOW"
cmd_success "✓ Your TYPO3 project will be deployed to: ${DEPLOY_PATH}"
PUBLIC_PATH="${DEPLOY_PATH}/${DOCUMENT_ROOT}"
BIN_PATH="${DEPLOY_PATH}/${COMPOSER_BIN_PATH}"

# DEPLOYMENT
cmd_run "Preparing deployment..."

cmd_run "Creating private ssh key..."
mkdir -p ~/.ssh
touch ~/.ssh/id_rsa
echo "$SSH_PRIVATE_KEY" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
eval `ssh-agent -s`
ssh-add ~/.ssh/id_rsa
confirm "Private ssh key is created"

cmd_run "Creating known_hosts file..."
touch ~/.ssh/known_hosts
ssh-keyscan -H ${REMOTE_HOST} >> ~/.ssh/known_hosts
confirm "Known_hosts file is created"

# Check if needed folders are present on remote, if not create them
cmd_run "Testing if file storages exist on remote host..."
for storage in ${ADDITIONAL_FILE_STORAGES//,/ }; do
ssh -i ~/.ssh/id_rsa -o UserKnownHostsFile=~/.ssh/known_hosts -T "$REMOTE_USERNAME@$REMOTE_HOST" -p $SSH_PORT << EOF
    set -e

    mkdir -p "$REMOTE_PATH/shared/Data/$storage"
EOF
done
confirm "All needed file storages are present on remote host"

cmd_run "Testing if needed TYPO3 folders exist on remote host..."
ssh -i ~/.ssh/id_rsa -o UserKnownHostsFile=~/.ssh/known_hosts -T "$REMOTE_USERNAME@$REMOTE_HOST" -p $SSH_PORT << EOF
    set -e

    mkdir -p "$DEPLOY_PATH"
    mkdir -p "$DEPLOY_PATH/var"
    mkdir -p "$REMOTE_PATH/shared/Data/typo3temp"
    mkdir -p "$REMOTE_PATH/shared/Data/uploads"
    mkdir -p "$REMOTE_PATH/shared/Data/var/labels"
EOF
confirm "All needed TYPO3 folders are present on remote host"

# Actually deploy the project
cmd_run "Deploying bin dir..."
test -d "$CURRENT_DIR/bin" && rsync -a -e "ssh -i /github/home/.ssh/id_rsa -o UserKnownHostsFile=/github/home/.ssh/known_hosts -p $SSH_PORT" --stats --human-readable $CURRENT_DIR/bin "$REMOTE_USERNAME@$REMOTE_HOST:$DEPLOY_PATH"
confirm "Binaries are deployed"

cmd_run "Deploying config dir..."
test -d "$CURRENT_DIR/config" && rsync -a -e "ssh -i /github/home/.ssh/id_rsa -o UserKnownHostsFile=/github/home/.ssh/known_hosts -p $SSH_PORT" --stats --human-readable $CURRENT_DIR/config "$REMOTE_USERNAME@$REMOTE_HOST:$DEPLOY_PATH"
confirm "Configuration files are deployed"

cmd_run "Deploying local packages..."
test -d "$CURRENT_DIR/local_packages" && rsync -a -e "ssh -i /github/home/.ssh/id_rsa -o UserKnownHostsFile=/github/home/.ssh/known_hosts -p $SSH_PORT" --stats --human-readable $CURRENT_DIR/local_packages "$REMOTE_USERNAME@$REMOTE_HOST:$DEPLOY_PATH"
confirm "Local packages are deployed"

cmd_run "Deploying public dir..."
test -d "$CURRENT_DIR/public" && rsync -a -e "ssh -i /github/home/.ssh/id_rsa -o UserKnownHostsFile=/github/home/.ssh/known_hosts -p $SSH_PORT" --stats --human-readable $CURRENT_DIR/public "$REMOTE_USERNAME@$REMOTE_HOST:$DEPLOY_PATH"
confirm "Public files are deployed"

cmd_run "Deploying vendor dir..."
test -d "$CURRENT_DIR/vendor" && rsync -a -e "ssh -i /github/home/.ssh/id_rsa -o UserKnownHostsFile=/github/home/.ssh/known_hosts -p $SSH_PORT" --stats --human-readable $CURRENT_DIR/vendor "$REMOTE_USERNAME@$REMOTE_HOST:$DEPLOY_PATH"
confirm "Vendor files are deployed"

cmd_success "✓ Project files are deployed"

# Execute commands after deployment

cmd_run "Changing directory permissions..."
ssh -i ~/.ssh/id_rsa -o UserKnownHostsFile=~/.ssh/known_hosts -T "$REMOTE_USERNAME@$REMOTE_HOST" -p $SSH_PORT << EOF
    set -e
    find "$DEPLOY_PATH" -type d -exec chmod 775 {} \;
EOF
confirm "Directory permissions are changed"

cmd_run "Creating symlinks from file storages..."
for storage in ${ADDITIONAL_FILE_STORAGES//,/ }; do
ssh -i ~/.ssh/id_rsa -o UserKnownHostsFile=~/.ssh/known_hosts -T "$REMOTE_USERNAME@$REMOTE_HOST" -p $SSH_PORT << EOF
    set -e

    echo "⧗ Create symlinks and directories for file storage $storage"
    cd "$DEPLOY_PATH/$DOCUMENT_ROOT"
    ln -sfn "$DOCUMENT_DEPTH_PATH/shared/Data/$storage" "$storage"
    echo "✓ Symlinks for file storage $storage successfully created!"
EOF
done
cmd_success "✓ Symlinks from file storages are created"

cmd_run "Creating symlinks from TYPO3 folders..."
ssh -i ~/.ssh/id_rsa -o UserKnownHostsFile=~/.ssh/known_hosts -T "$REMOTE_USERNAME@$REMOTE_HOST" -p $SSH_PORT << EOF
    set -e

    cd "$DEPLOY_PATH/$DOCUMENT_ROOT"
    echo "» Create symlinks and directories for uploads folder"
    ln -sfn "$DOCUMENT_DEPTH_PATH/shared/Data/uploads" "uploads"
    echo "✓ Symlinks for uploads folder successfully created!"
    echo ""

    echo "» Create symlinks and directories for typo3temp folder"
    test -d "typo3temp" && rm -rf "typo3temp"
    ln -sfn "$DOCUMENT_DEPTH_PATH/shared/Data/typo3temp" "typo3temp"
    echo "✓ Symlinks for typo3temp folder successfully created!"
    echo ""

    cd "$DEPLOY_PATH"
    echo "» Create symlinks and directories for .env file"
    test -f "$REMOTE_PATH/shared/Data/.env" && ln -sfn "$REMOTE_PATH/shared/Data/.env" .env
    echo "✓ Symlinks for .env file successfully created!"
    echo ""

    echo "» Create symlinks and directories for labels folder"
    cd "$DEPLOY_PATH/var"
    ln -sfn "../../../shared/Data/var/labels" "labels"
    echo "✓ Symlinks for labels folder successfully created!"
EOF
cmd_success "✓ Symlinks from TYPO3 folders are created"

cmd_run "Executing commands after deployment..."
ssh -i ~/.ssh/id_rsa -o UserKnownHostsFile=~/.ssh/known_hosts -T "$REMOTE_USERNAME@$REMOTE_HOST" -p $SSH_PORT << EOF
    set -e

    export TYPO3_CONTEXT="$TYPO3_CONTEXT"
    export PHPVERSION=$PHP_VERSION

    echo "⧗ Adding +x flag to binaries..."
    cd $BIN_PATH
    chmod +x *

    echo "⧗ Fixing folder structure..."
    ./typo3 install:fixfolderstructure

    echo "⧗ Updating database schema..."
    ./typo3 database:updateschema "*.add,*.change"

    echo "⧗ Updating languages..."
    ./typo3 language:update

    echo "⧗ Flushing TYPO3 Caches..."
    ./typo3 cache:flush
EOF
cmd_success "✓ Commands after deployment are executed"

cmd_run "Deploying update_symlinks.sh..."
rsync -a -e "ssh -i /github/home/.ssh/id_rsa -o UserKnownHostsFile=/github/home/.ssh/known_hosts -p $SSH_PORT" --stats --human-readable /update_symlinks.sh "$REMOTE_USERNAME@$REMOTE_HOST:$REMOTE_PATH/releases"
confirm "update_symlinks.sh script is deployed"

cmd_run "Deploying remove_old_releases.sh..."
rsync -a -e "ssh -i /github/home/.ssh/id_rsa -o UserKnownHostsFile=/github/home/.ssh/known_hosts -p $SSH_PORT" --stats --human-readable /remove_old_releases.sh "$REMOTE_USERNAME@$REMOTE_HOST:$REMOTE_PATH/releases"
confirm "remove_old_releases.sh script is deployed"

cmd_run "Running post-deploy scripts on the remote..."
ssh -i ~/.ssh/id_rsa -o UserKnownHostsFile=~/.ssh/known_hosts -T "$REMOTE_USERNAME@$REMOTE_HOST" -p $SSH_PORT << EOF
    set -e

    echo "⧗ Backing up previous release..."
    cd "$REMOTE_PATH/releases"

    ./update_symlinks.sh
    echo "✓ update_symlinks is executed"
    rm update_symlinks.sh
    echo "✓ update_symlinks script is removed"

    echo "⧗ Remove old releases..."
    cd "$REMOTE_PATH/releases"

    ./remove_old_releases.sh
    echo "✓ remove_old_releases is executed"
    rm remove_old_releases.sh
    echo "✓ remove_old_releases is removed"

    ln -sfn "./$DATE_NOW" "current"
    echo "✓ Symlink 'current' is updated"
EOF

cmd_success "Your TYPO3 project is deployed"
confirm "✓ Completed ${GITHUB_WORKFLOW}:${GITHUB_ACTION}"
