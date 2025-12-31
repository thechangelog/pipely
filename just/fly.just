# Deploy container image
[group('team')]
deploy tag=_DEFAULT_TAG:
    flyctl deploy --ha=false --image={{ APP_IMAGE }}:{{ tag }} \
      --vm-cpu-kind {{ FLY_APP_REGION_HOT_CPU_KIND }} \
      --vm-cpus {{ FLY_APP_REGION_HOT_CPU_NUM }} \
      --vm-memory {{ FLY_APP_REGION_HOT_MEM }} \
      --env VARNISH_SIZE=$(({{ FLY_APP_REGION_HOT_MEM }} * 70 / 100))M \
      --env VARNISH_FILE_SIZE=$(({{ FLY_APP_DISK_SIZE }} * 90 / 100))G

# Scale production app
[group('team')]
scale:
    flyctl scale count $(echo {{ FLY_APP_REGIONS }}, | grep -o ',' | wc -l) --max-per-region 1 --region {{ FLY_APP_REGIONS }} --app {{ FLY_APP }}
    @just machines \
    | awk '/pipely/ { print $1, $5 }' \
    | while read machine region; do \
        if [[ ! {{ FLY_APP_REGIONS_HOT }} =~ $region ]]; then \
          echo -e "\n🌑 Scaling machine in {{ BLUE }}COLD region {{ BOLD }}$region{{ NORMAL }} to {{ BOLD }}{{ FLY_APP_REGION_DEFAULT_CPU_KIND }}-{{ FLY_APP_REGION_DEFAULT_CPU_NUM }}C-{{ FLY_APP_REGION_DEFAULT_MEM }}M{{ BOLD }} ..."; \
          flyctl machine update --yes \
            --vm-cpu-kind {{ FLY_APP_REGION_DEFAULT_CPU_KIND }} \
            --vm-cpus {{ FLY_APP_REGION_DEFAULT_CPU_NUM }} \
            --vm-memory {{ FLY_APP_REGION_DEFAULT_MEM }} \
            --env VARNISH_SIZE=$(({{ FLY_APP_REGION_DEFAULT_MEM }} * 70 / 100))M \
            "$machine"; \
        fi; \
      done

# Set app secrets - assumes envrc-secrets was already run
[group('team')]
secrets:
    PURGE_TOKEN="op://pipely/purge/credential" \
    HONEYCOMB_API_KEY="op://pipely/honeycomb/credential" \
    AWS_ACCESS_KEY_ID="op://pipely/aws-s3-logs/access-key-id" \
    AWS_SECRET_ACCESS_KEY="op://pipely/aws-s3-logs/secret-access-key" \
    just op run -- bash -c 'flyctl secrets set --stage HONEYCOMB_DATASET="pipedream" HONEYCOMB_API_KEY="$HONEYCOMB_API_KEY" PURGE_TOKEN="$PURGE_TOKEN" AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"'
    flyctl secrets list

# Show app certs
[group('team')]
certs:
    flyctl certs list --app {{ FLY_APP }}

# Add cert $fqdn to app
[group('team')]
cert-add fqdn:
    flyctl certs add {{ fqdn }} --app {{ FLY_APP }}

# Show cert $fqdn for app
[group('team')]
cert fqdn:
    flyctl certs show {{ fqdn }} --app {{ FLY_APP }} --json

# Show app IPs
[group('team')]
ips:
    flyctl ips list --app {{ FLY_APP }}

# Show app machines
[group('team')]
machines:
    flyctl machines list --app {{ FLY_APP }}

# Restart ALL app machines, one-by-one
[group('team')]
restart:
    @just machines \
    | awk '/pipely/ { print $1 }' \
    | while read machine; do \
        echo -en "\n♻️ "; \
        flyctl machine stop $machine; \
        sleep 10; \
        flyctl machine start $machine \
        || (sleep 10; flyctl machine start $machine); \
    done
    @echo {{ MAGENTA }}🧐 Any stopped machines?{{ NORMAL }}
    @just machines | grep stop || echo ✨

# Show app status
[group('team')]
status:
    flyctl status --app {{ FLY_APP }}

# Show Varnish status
[group('team')]
varnishstatus:
    flyctl ssh console --app {{ FLY_APP }} --command "varnishstat -1" --select

# Show Varnish config
[group('team')]
varnishconfig:
    flyctl ssh console --app {{ FLY_APP }} --command "varnishadm param.show" --select

[private]
create:
    (flyctl apps list --org {{ FLY_ORG }} | grep {{ FLY_APP }}) \
    || (flyctl apps create {{ FLY_APP }} --org {{ FLY_ORG }} \
        && flyctl volume create varnish_file_cache --region {{ FLY_APP_PRIMARY_REGION }} --size {{ FLY_APP_DISK_SIZE }} --yes \
        && flyctl ips allocate-v4 --yes)