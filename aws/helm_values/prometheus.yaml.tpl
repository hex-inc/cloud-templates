rbac:
  create: true

podSecurityPolicy:
  enabled: false

## Define serviceAccount names for components. Defaults to component's fully qualified name.
serviceAccounts:
  server:
    create: true
    name:
    annotations: {}

alertmanager:
  enabled: false


## Monitors ConfigMap changes and POSTs to a URL
## Ref: https://github.com/jimmidyson/configmap-reload
##
configmapReload:
  prometheus:
    ## If false, the configmap-reload container will not be deployed
    ##
    enabled: true

    ## configmap-reload container name
    ##
    name: configmap-reload

    ## configmap-reload container image
    ##
    image:
      repository: jimmidyson/configmap-reload
      tag: v0.4.0
      pullPolicy: IfNotPresent


kubeStateMetrics:
  enabled: false


nodeExporter:
  enabled: false

server:
  enabled: true
  name: server

  # sidecarContainers - add more containers to prometheus server
  # Key/Value where Key is the sidecar `- name: <Key>`
  # Example:
  #   sidecarContainers:
  #      webserver:
  #        image: nginx
  sidecarContainers: {}

  ## Prometheus server container image
  ##
  image:
    repository: quay.io/prometheus/prometheus
    tag: v2.24.0
    pullPolicy: IfNotPresent

  extraInitContainers:
    - name: vault-login
      image: vault:1.6.1
      securityContext:
        runAsUser: 0
      command:
        - /bin/sh
        - -c
        - |
          set -euxo pipefail
          apk add jq
          # Write policy for metrics
          OUTPUT=$(vault operator generate-root -init -format=json)
          NONCE=$(echo $OUTPUT | jq -r .nonce)
          OTP=$(echo $OUTPUT | jq -r .otp)

          echo $KEY_0 | vault operator generate-root -nonce=$NONCE -
          echo $KEY_1 | vault operator generate-root -nonce=$NONCE -
          ROOT_GENERATION_OUTPUT=$(echo $KEY_2 | vault operator generate-root -nonce=$NONCE -format=json -) 

          ENCODED_TOKEN=$(echo $ROOT_GENERATION_OUTPUT | jq -r .encoded_token)
          VAULT_TOKEN=$(echo $(vault operator generate-root -decode=$ENCODED_TOKEN -otp=$OTP -format=json) | jq -r .token)

          vault login $VAULT_TOKEN
          echo "path \"sys/metrics\" {capabilities = [\"read\", \"list\"]}" | vault policy write prometheus-metrics -
          vault write auth/kubernetes/role/prometheus-metrics bound_service_account_names=prometheus-server bound_service_account_namespaces=monitoring policies=prometheus-metrics ttl=24h

          # Log into vault to get token
          VAULT_TOKEN=$(vault write auth/kubernetes/login role=prometheus-metrics jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" -format=json | jq -r .auth.client_token)
          echo $VAULT_TOKEN > /etc/vault-token/token
      env:
        - name: VAULT_ADDR
          value: https://${vault-endpoint}
        - name: VAULT_CACERT
          value: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        - name: KEY_0
          valueFrom:
            secretKeyRef:
              name: hex-vault-keys
              key: key_0
        - name: KEY_1
          valueFrom:
            secretKeyRef:
              name: hex-vault-keys
              key: key_1
        - name: KEY_2
          valueFrom:
            secretKeyRef:
              name: hex-vault-keys
              key: key_2

      volumeMounts:
        - name: vault-token
          mountPath: /etc/vault-token
  extraVolumeMounts:
    - name: vault-token
      mountPath: /etc/vault-token
  extraVolumes:
    - name: vault-token
      emptyDir:
        medium: Memory

  ## EnableServiceLinks indicates whether information about services should be injected
  ## into pod's environment variables, matching the syntax of Docker links.
  ## WARNING: the field is unsupported and will be skipped in K8s prior to v1.13.0.
  ##
  enableServiceLinks: true

  ## The URL prefix at which the container can be accessed. Useful in the case the '-web.external-url' includes a slug
  ## so that the various internal URLs are still able to access as they are in the default case.
  ## (Optional)
  prefixURL: ""

  extraFlags:
    - web.enable-lifecycle
    ## web.enable-admin-api flag controls access to the administrative HTTP API which includes functionality such as
    ## deleting time series. This is disabled by default.
    # - web.enable-admin-api
    ##
    ## storage.tsdb.no-lockfile flag controls BD locking
    # - storage.tsdb.no-lockfile
    ##
    ## storage.tsdb.wal-compression flag enables compression of the write-ahead log (WAL)
    # - storage.tsdb.wal-compression

  ## Path to a configuration file on prometheus server container FS
  configPath: /etc/config/prometheus.yml

  global:
    ## How frequently to scrape targets by default
    ##
    scrape_interval: 1m
    ## How long until a scrape request times out
    ##
    scrape_timeout: 10s
    ## How frequently to evaluate rules
    ##
    evaluation_interval: 1m
  ## https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write
  ##

  ingress:
    enabled: false


  persistentVolume:
    ## If true, Prometheus server will create/use a Persistent Volume Claim
    ## If false, use emptyDir
    ##
    enabled: true

    ## Prometheus server data Persistent Volume access modes
    ## Must match those of existing PV or dynamic provisioner
    ## Ref: http://kubernetes.io/docs/user-guide/persistent-volumes/
    ##
    accessModes:
      - ReadWriteOnce

    ## Prometheus server data Persistent Volume mount root path
    ##
    mountPath: /data

    ## Prometheus server data Persistent Volume size
    ##
    size: 8Gi

  ## Use a StatefulSet if replicaCount needs to be greater than 1 (see below)
  ##
  replicaCount: 1

  statefulSet:
    ## If true, use a statefulset instead of a deployment for pod management.
    ## This allows to scale replicas to more than 1 pod
    ##
    enabled: false

  ## Security context to be added to server pods
  ##
  securityContext:
    runAsUser: 65534
    runAsNonRoot: false
    runAsGroup: 65534
    fsGroup: 65534

  ## Prometheus data retention period (default if not specified is 15 days)
  ##
  retention: "1d"

pushgateway:
  ## If false, pushgateway will not be installed
  ##
  enabled: false

## Prometheus server ConfigMap entries
##
serverFiles:

  ## Alerts configuration
  ## Ref: https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/
  alerting_rules.yml: {}
  alerts: {}

  ## Records configuration
  ## Ref: https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/
  recording_rules.yml: {}

  prometheus.yml:
    remote_write:
      - url: https://metric-api.newrelic.com/prometheus/v1/write?prometheus_server=${name}
        bearer_token: ${nr-license-key}
    rule_files:
      - /etc/config/recording_rules.yml
      - /etc/config/alerting_rules.yml

    scrape_configs:
      - job_name: prometheus
        static_configs:
          - targets:
            - localhost:9090

      # A scrape configuration for running Prometheus on a Kubernetes cluster.
      # This uses separate scrape configs for cluster components (i.e. API server, node)
      # and services to allow each to use different authentication configs.
      #
      # Kubernetes labels will be added as Prometheus labels on metrics via the
      # `labelmap` relabeling action.
      - job_name: 'kubernetes-nodes'

        # Default to scraping over https. If required, just disable this or change to
        # `http`.
        scheme: https

        # This TLS & bearer token file config is used to connect to the actual scrape
        # endpoints for cluster components. This is separate to discovery auth
        # configuration because discovery & scraping are two separate concerns in
        # Prometheus. The discovery auth config is automatic if Prometheus runs inside
        # the cluster. Otherwise, more config options have to be provided within the
        # <kubernetes_sd_config>.
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
          # If your node certificates are self-signed or use a different CA to the
          # master CA, then disable certificate verification below. Note that
          # certificate verification is an integral part of a secure infrastructure
          # so this should only be disabled in a controlled environment. You can
          # disable certificate verification by uncommenting the line below.
          #
          insecure_skip_verify: true
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token

        kubernetes_sd_configs:
          - role: node

        relabel_configs:
          - action: labelmap
            regex: __meta_kubernetes_node_label_(.+)
          - target_label: __address__
            replacement: kubernetes.default.svc:443
          - source_labels: [__meta_kubernetes_node_name]
            regex: (.+)
            target_label: __metrics_path__
            replacement: /api/v1/nodes/$1/proxy/metrics


      - job_name: 'vault'
        scrape_interval: 1m
        scrape_timeout: 10s
        metrics_path: "/v1/sys/metrics"
        params:
          format:
            - prometheus
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /etc/vault-token/token
        static_configs:
          - targets: 
            - ${vault-endpoint}



networkPolicy:
  ## Enable creation of NetworkPolicy resources.
  enabled: false

# Force namespace of namespaced resources
forceNamespace: null

