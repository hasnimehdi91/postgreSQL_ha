server           = true
bootstrap_expect = {{ consul_cluster_replica_count | default(3) }}
data_dir         = "/consul_data"
node_name        = "postgres_ha_consul_{{ item }}"
bind_addr        = "0.0.0.0"
client_addr      = "0.0.0.0"
datacenter       = "dc1"
retry_join       = [{% for i in range(1, (consul_cluster_replica_count | default(3)) + 1) if i != item %}"postgres_ha_consul_{{ i }}"{% if not loop.last %}, {% endif %}{% endfor %}]
encrypt          = "{{ consul_gossip_encryption_key }}"
log_level        = "INFO"

ui_config {
    enabled = true
}

ports {
    http  = -1   # Disable insecure HTTP
    https = 8500 # Enforce HTTPS on port 8500
}
