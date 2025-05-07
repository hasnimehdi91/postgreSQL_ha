#!/bin/bash

# Start background PMM client registration script
/usr/local/bin/pmm_agent_registration.sh &

# Start Patroni in the foreground
patroni /etc/patroni/patroni.yml
