server           = true
bootstrap_expect = 1
data_dir         = "/consul_data"
node_name        = "consul-server"
bind_addr        = "0.0.0.0"
client_addr      = "0.0.0.0"
ui_config {
    enabled = true
}
datacenter       = "dc1"
retry_join       = []
log_level        = "INFO"

ports {
    http  = -1     # Disable insecure HTTP
    https = 8500   # Enforce HTTPS on port 8500
}
