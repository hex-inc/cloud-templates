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
    --init)
    INIT=true
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
  echo "Initializes or unseals vault in a hex deployment"
  echo "Usage: \`./init-vault.sh -n NAMESPACE -r RELEASE --init\` to initialize vault for the first time"
  echo "Usage: \`./init-vault.sh -n NAMESPACE -r RELEASE KEY1 KEY2 KEY3\` to unseal vault after it's been initialized"
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

wait_pods_ready() {
  ATTEMPTS=0
  echo "Waiting for all vault pods to be ready to init"
  all_pods_running() {
    POD_0=$(kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault status -format=json 2> /dev/null | jq '.initialized == false' 2> /dev/null)
    POD_1=$(kubectl -n $NAMESPACE exec -it hex-vault-1 -- vault status -format=json 2> /dev/null | jq '.initialized == false' 2> /dev/null)
    POD_2=$(kubectl -n $NAMESPACE exec -it hex-vault-2 -- vault status -format=json 2> /dev/null | jq '.initialized == false' 2> /dev/null)
    [ "$POD_0" == "true" ] && [ "$POD_1" == "true" ] && [ "$POD_2" == "true" ]
  }
  while [ $ATTEMPTS -le 20 ]; do
    all_pods_running && break
    echo "Pods not ready, waiting 10 seconds"
    sleep 10
    let ATTEMPTS=ATTEMPTS+1
  done

  if [ $ATTEMPTS -eq 21 ]; then
    echo "Vault pods not running after timeout, please check your namespace"
    exit 1
  fi
}

if [[ $INIT ]]; then
  wait_pods_ready
  OUTPUT=$(kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator init -format=json)
  VAULT_UNSEAL_KEY_0=$(echo $OUTPUT | jq -r ".unseal_keys_b64[0]")
  VAULT_UNSEAL_KEY_1=$(echo $OUTPUT | jq -r ".unseal_keys_b64[1]")
  VAULT_UNSEAL_KEY_2=$(echo $OUTPUT | jq -r ".unseal_keys_b64[2]")
  VAULT_TOKEN=$(echo $OUTPUT | jq -r ".root_token")
else
  if [[ -z $1 || -z $2 || -z $3 ]]; then
    echo "You must provide 3 unseal keys"
    exit 1
  fi
  VAULT_UNSEAL_KEY_0=$1
  VAULT_UNSEAL_KEY_1=$2
  VAULT_UNSEAL_KEY_2=$3
fi

echo "Unsealing Vault leader node."
kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY_0
kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY_2
echo "Leader node unsealed, waiting for other nodes to join cluster."

other_pods_initialized() {
  POD_1=$(kubectl -n $NAMESPACE exec -it hex-vault-1 -- vault status -format=json 2> /dev/null | jq '.initialized == true' 2> /dev/null)
  POD_2=$(kubectl -n $NAMESPACE exec -it hex-vault-2 -- vault status -format=json 2> /dev/null | jq '.initialized == true' 2> /dev/null)
  [ "$POD_1" == "true" ] && [ "$POD_2" == "true" ]
}
ATTEMPTS=0
while [ $ATTEMPTS -le 5 ]; do
  other_pods_initialized && break
  echo "Other nodes not ready, waiting 5 seconds"
  sleep 5
  let ATTEMPTS=ATTEMPTS+1
done

if [ $ATTEMPTS -eq 6 ]; then
  echo "Other vault pods not initialized after timeout, please check your namespace"
  exit 1
fi

echo "Unsealing remaining nodes"
kubectl -n $NAMESPACE exec hex-vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY_0
kubectl -n $NAMESPACE exec hex-vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY_0
kubectl -n $NAMESPACE exec hex-vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl -n $NAMESPACE exec hex-vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl -n $NAMESPACE exec hex-vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY_2
kubectl -n $NAMESPACE exec hex-vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY_2

echo Vault unsealed!

if [[ $INIT ]]; then
  kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault login $VAULT_TOKEN
  kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault auth enable kubernetes
  kubectl -n $NAMESPACE exec -it hex-vault-0 -- /bin/sh -c 'vault write auth/kubernetes/config token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'
  kubectl -n $NAMESPACE exec -it hex-vault-0 -- /bin/sh -c "echo 'path \"secret/*\" {capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]}' | vault policy write hex -"
  kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault write auth/kubernetes/role/hex bound_service_account_names=hex-sa bound_service_account_namespaces=$NAMESPACE policies=hex ttl=24h
  kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault secrets enable -version=1 -path=secret kv
  kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault secrets enable pki
  kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault secrets tune -max-lease-ttl=87600h pki
  kubectl -n $NAMESPACE create secret generic hex-vault-keys --from-literal="key_0=$VAULT_UNSEAL_KEY_0" --from-literal="key_1=$VAULT_UNSEAL_KEY_1" --from-literal="key_2=$VAULT_UNSEAL_KEY_2"
  echo $OUTPUT
fi
