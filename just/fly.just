import 'flyctl.just'

# Deploy container image
[group('team')]
deploy tag=_DEFAULT_TAG regions=FLY_APP_REGIONS:
    just flyctl deploy --ha=false --image={{ APP_IMAGE }}:{{ tag }} \
      --regions {{ regions }} \
      --vm-cpu-kind {{ FLY_APP_REGION_HOT_CPU_KIND }} \
      --vm-cpus {{ FLY_APP_REGION_HOT_CPU_NUM }} \
      --vm-memory {{ FLY_APP_REGION_HOT_MEM }} \
      --env VARNISH_SIZE=$(({{ FLY_APP_REGION_HOT_MEM }} * 70 / 100))M \
      --env VARNISH_FILE_SIZE=$(({{ FLY_APP_DISK_SIZE }} * 90 / 100))G

# Scale app
[group('team')]
scale regions=FLY_APP_REGIONS regions_hot=FLY_APP_REGIONS_HOT: (scale-count regions) (scale-disk regions) (scale-size regions regions_hot)

# Scale number of app instances
[group('team')]
scale-count regions=FLY_APP_REGIONS:
    just flyctl scale count $(echo {{ regions }}, | grep -o ',' | wc -l) --max-per-region 1 --region {{ regions }} --app {{ FLY_APP }}

# Scale disk size
[group('team')]
scale-disk regions=FLY_APP_REGIONS:
    just flyctl volume list \
    | awk '/varnish_file_cache.*({{ replace(regions, ",", "|") }})/ { print $1, $4, $5 }' \
    | while read volume size region; do \
        if (( "${size%GB}" < "{{ FLY_APP_DISK_SIZE }}" )); then \
          echo -e "\n💿 Scaling disk in region {{ BOLD }}$region{{ NORMAL }} from {{ BOLD }}$size{{ NORMAL }} to {{ BOLD }}{{ FLY_APP_DISK_SIZE }}GB{{ NORMAL }} ..."; \
          just flyctl volume extend --yes \
            --size {{ FLY_APP_DISK_SIZE }}G \
            "$volume"; \
        else \
          echo "NOOP {{ BOLD }}$region{{ NORMAL }}: $size (from) >= {{ FLY_APP_DISK_SIZE }}GB (to)"; \
        fi; \
      done

# Scale size of app instances
[group('team')]
scale-size regions=FLY_APP_REGIONS regions_hot=FLY_APP_REGIONS_HOT:
    just machines \
    | awk '/({{ replace(regions, ",", "|") }}).*pipely/ { print $1, $5 }' \
    | while read machine region; do \
        if [[ {{ regions_hot }} =~ $region ]]; then \
          echo -e "\n🌕 Scaling machine in {{ YELLOW }}HOT region {{ BOLD }}$region{{ NORMAL }} to {{ BOLD }}{{ FLY_APP_REGION_HOT_CPU_KIND }}-{{ FLY_APP_REGION_HOT_CPU_NUM }}C-{{ FLY_APP_REGION_HOT_MEM }}M{{ BOLD }} ..."; \
          just flyctl machine update --yes \
            --vm-cpu-kind {{ FLY_APP_REGION_HOT_CPU_KIND }} \
            --vm-cpus {{ FLY_APP_REGION_HOT_CPU_NUM }} \
            --vm-memory {{ FLY_APP_REGION_HOT_MEM }} \
            --env VARNISH_SIZE=$(({{ FLY_APP_REGION_HOT_MEM }} * 70 / 100))M \
            --env VARNISH_FILE_SIZE=$(({{ FLY_APP_DISK_SIZE }} * 90 / 100))G \
            "$machine"; \
        else \
          echo -e "\n🌑 Scaling machine in {{ BLUE }}COLD region {{ BOLD }}$region{{ NORMAL }} to {{ BOLD }}{{ FLY_APP_REGION_DEFAULT_CPU_KIND }}-{{ FLY_APP_REGION_DEFAULT_CPU_NUM }}C-{{ FLY_APP_REGION_DEFAULT_MEM }}M{{ BOLD }} ..."; \
          just flyctl machine update --yes \
            --vm-cpu-kind {{ FLY_APP_REGION_DEFAULT_CPU_KIND }} \
            --vm-cpus {{ FLY_APP_REGION_DEFAULT_CPU_NUM }} \
            --vm-memory {{ FLY_APP_REGION_DEFAULT_MEM }} \
            --env VARNISH_SIZE=$(({{ FLY_APP_REGION_DEFAULT_MEM }} * 70 / 100))M \
            --env VARNISH_FILE_SIZE=$(({{ FLY_APP_DISK_SIZE }} * 90 / 100))G \
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
    just op run -- bash -c 'just flyctl secrets set --stage HONEYCOMB_DATASET="pipedream" HONEYCOMB_API_KEY="$HONEYCOMB_API_KEY" PURGE_TOKEN="$PURGE_TOKEN" AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"'
    just flyctl secrets list

# Show app certs
[group('team')]
certs:
    just flyctl certs list --app {{ FLY_APP }}

# Add cert $fqdn to app
[group('team')]
cert-add fqdn:
    just flyctl certs add {{ fqdn }} --app {{ FLY_APP }}

# Show cert $fqdn for app
[group('team')]
cert fqdn:
    just flyctl certs show {{ fqdn }} --app {{ FLY_APP }} --json

# Show app IPs
[group('team')]
ips:
    just flyctl ips list --app {{ FLY_APP }}

# Show app machines
[group('team')]
machines:
    just flyctl machines list --app {{ FLY_APP }}

# Restart ALL app machines, one-by-one
[group('team')]
restart:
    just machines \
    | awk '/pipely/ { print $1 }' \
    | while read machine; do \
        echo -en "\n♻️ "; \
        just flyctl machine stop $machine; \
        sleep 10; \
        just flyctl machine start $machine \
        || (sleep 10; just flyctl machine start $machine); \
    done
    @echo {{ MAGENTA }}🧐 Any stopped machines?{{ NORMAL }}
    @just machines | grep stop || echo ✨

# Show app status
[group('team')]
status:
    just flyctl status --app {{ FLY_APP }}

# Show Varnish status
[group('team')]
varnishstatus:
    just flyctl ssh console --app {{ FLY_APP }} --command "varnishstat -1" --select

# Show Varnish config
[group('team')]
varnishconfig:
    just flyctl ssh console --app {{ FLY_APP }} --command "varnishadm param.show" --select

[private]
create:
    (just flyctl apps list --org {{ FLY_ORG }} | grep {{ FLY_APP }}) \
    || (just flyctl apps create {{ FLY_APP }} --org {{ FLY_ORG }} \
      && just flyctl volume create varnish_file_cache --region {{ FLY_APP_PRIMARY_REGION }} --size {{ FLY_APP_DISK_SIZE }} --yes \
      && just flyctl ips allocate-v4 --yes)