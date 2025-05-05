tls {
    defaults {
        ca_file            = "/consul_certs/ca.crt"
        cert_file          = "/consul_certs/consul.crt"
        key_file           = "/consul_certs/consul.key"
        verify_incoming    = false
        verify_outgoing    = true
    }

    internal_rpc {
        verify_server_hostname = true
    }
}
