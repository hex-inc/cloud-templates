#!/bin/bash
set -eo pipefail
POSITIONAL=()

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--namespace)
    NAMESPACE="$2"
    shift # past argument
    shift # past value
    ;;
    -r|--release)
    RELEASE="$2"
    shift # past argument
    shift # past value
    ;;
    --help)
    HELP=true
    shift # past argument
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift # past argument
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ $HELP ]]; then
  echo "Backs up existing Vault data and prepares deployment of Hex 1.3 infrastructure. The product should not be used after this is run."
  echo "Usage: \`./pre-upgrade.sh -n NAMESPACE -r RELEASE"
  exit 0
fi

if [[ -z $NAMESPACE ]]; then
  echo "Please specify a namespace with -n or --namespace"
  exit 1
fi

if [[ -z $RELEASE ]]; then
  echo "Please specify a release with -r or --release"
  exit 1
fi

read -p "The platform will not run properly until you complete the 1.3 upgrade after running this script. Are you sure? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[y]$ ]]
then
    echo "Proceeding with pre-upgrade steps..."
    echo "Backing up current Consul data..."
    kubectl -n $NAMESPACE exec $RELEASE-consul-server-0 -- consul snapshot save /tmp/backup.snap
    kubectl -n $NAMESPACE exec $RELEASE-consul-server-0 -- consul snapshot inspect /tmp/backup.snap
    FILENAME="consul-backup-$(date +%s).snap"
    kubectl -n $NAMESPACE cp $RELEASE-consul-server-0:tmp/backup.snap $FILENAME
    kubectl -n $NAMESPACE create secret generic pre-upgrade-raft-migration --from-literal "complete=true"
    echo "Saved snapshot as $FILENAME. This is your current encrypted secrets data, needed in case of a rollback."
    echo "Removing current Vault and certificate approver processes..."
    kubectl -n $NAMESPACE delete statefulset/$RELEASE-vault --wait=true
    kubectl -n $NAMESPACE delete deployment/$RELEASE-tls-approver --wait=true
    echo "Removed current Vault and certificate approver processes, you can now proceed with the upgrade to 1.3."
    echo "Note: you will need to run upgrade-1.3.sh after applying the latest release, this will require your Vault unseal keys."
fi
