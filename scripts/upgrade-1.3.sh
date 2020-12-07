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
  echo "Migrate Vault from the existing Consul backed storage to Raft."
  echo "Usage: \`./upgrade-1.3.sh -n NAMESPACE -r RELEASE UNSEAL_KEY_1 UNSEAL_KEY_2 UNSEAL_KEY_3"
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

if [[ -z $1 || -z $2 || -z $3 ]]; then
    echo "You must provide 3 unseal keys"
    exit 1
fi
VAULT_UNSEAL_KEY_0=$1
VAULT_UNSEAL_KEY_1=$2
VAULT_UNSEAL_KEY_2=$3

CONSUL_AGENT_IP=$(kubectl -n $NAMESPACE get pod hex-vault-0 -o json | jq -r .status.hostIP)

cat > migrate.hcl << EOF
storage_source "consul" {
address = "$CONSUL_AGENT_IP:8500"
path    = "vault"
}

storage_destination "raft" {
  path = "/vault/data/"
}

cluster_addr = "http://127.0.0.1:8200"
EOF

echo "Migrating Vault data..."
kubectl -n $NAMESPACE cp migrate.hcl hex-vault-0:tmp/migrate.hcl
rm migrate.hcl
kubectl -n $NAMESPACE exec hex-vault-0 -- /bin/sh -c "rm -rf /vault/data/*"
kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator migrate -config=/tmp/migrate.hcl
kubectl -n $NAMESPACE delete pod/hex-vault-0
wait_pods_ready() {
  ATTEMPTS=0
  all_pods_running() {
    POD_0=$(kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault status -format=json 2> /dev/null | jq '.initialized == true' 2> /dev/null)
    POD_1=$(kubectl -n $NAMESPACE exec -it hex-vault-1 -- vault status -format=json 2> /dev/null | jq '.initialized == false' 2> /dev/null)
    POD_2=$(kubectl -n $NAMESPACE exec -it hex-vault-2 -- vault status -format=json 2> /dev/null | jq '.initialized == false' 2> /dev/null)
    [ "$POD_0" == "true" ] && [ "$POD_1" == "true" ] && [ "$POD_2" == "true" ]
  }
  while [ $ATTEMPTS -le 5 ]; do
    all_pods_running && break
    echo "Pods not ready, waiting 10 seconds"
    sleep 10
    let ATTEMPTS=ATTEMPTS+1
  done

  if [ $ATTEMPTS -eq 6 ]; then
    echo "Vault pods not running after timeout, please check your namespace"
    exit 1
  fi
}
echo "Waiting for Vault to restart..."
wait_pods_ready
echo "Unsealing Vault leader node..."
kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY_0
kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY_1
kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY_2
ROOT_GEN=$(kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator generate-root -init -format json)
NONCE=$(echo $ROOT_GEN | jq -r ".nonce")
OTP=$(echo $ROOT_GEN | jq -r ".otp")
kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator generate-root -nonce=$NONCE -format json $VAULT_UNSEAL_KEY_0
kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator generate-root -nonce=$NONCE -format json $VAULT_UNSEAL_KEY_1
OUTPUT=$(kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator generate-root -nonce=$NONCE -format json $VAULT_UNSEAL_KEY_2)
ENCODED_TOKEN=$(echo $OUTPUT | jq -r ".encoded_token")
VAULT_TOKEN=$(kubectl -n $NAMESPACE exec hex-vault-0 -- vault operator generate-root -decode=$ENCODED_TOKEN -otp=$OTP)
kubectl -n $NAMESPACE exec hex-vault-0 -- vault login $VAULT_TOKEN
kubectl -n $NAMESPACE exec -it hex-vault-0 -- /bin/sh -c 'vault write auth/kubernetes/config token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt'


# Enable PKI engine for future service mesh work.
kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault secrets enable pki
kubectl -n $NAMESPACE exec -it hex-vault-0 -- vault secrets tune -max-lease-ttl=87600h pki

kubectl -n $NAMESPACE exec hex-vault-0 -- vault token revoke -self

# Create secret for 3 unseal keys so that we can operate independent of manual migrations.
kubectl -n $NAMESPACE create secret generic hex-vault-keys --from-literal="key_0=$VAULT_UNSEAL_KEY_0" --from-literal="key_1=$VAULT_UNSEAL_KEY_1" --from-literal="key_2=$VAULT_UNSEAL_KEY_2"


echo "Leader node unsealed, waiting for init"
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

echo "Migration complete."
