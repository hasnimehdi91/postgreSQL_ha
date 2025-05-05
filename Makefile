# Makefile
# Automates the setup, configuration, and lifecycle management of the PostgreSQL HA environment
# using Ansible and a Python virtual environment.

# Define the shell to be used for executing Makefile commands
SHELL := /bin/bash

# Targets that should never be treated as filenames
.PHONY: install_virtual_env check_virtual_env provision stop destroy

# Capture the current Makefile for reference (debugging or dynamic inclusion)
CURRENT_MK := $(lastword $(MAKEFILE_LIST))

# Directory name for the Python virtual environment
VIRTUAL_ENV_DIR := "postgreSQL_ha.venv"

# Root directory of the project context (used for virtualenv and Ansible execution)
CONF_DIR_CONTEXT := "."

# Python version selector (adjust based on system)
PYTHON_VERSION_12  = python3.12

# -----------------------------------
# Target: install_virtual_env
# -----------------------------------
# Description:
# Initializes a clean Python virtual environment for running Ansible tasks.
# If the environment already exists, it is deleted and rebuilt to ensure consistency.
# Installs Python dependencies and required Ansible collections.
install_virtual_env:
	@echo "Checking if directory ${CONF_DIR_CONTEXT}/${VIRTUAL_ENV_DIR} exists..."
	@if [ -d "${CONF_DIR_CONTEXT}/${VIRTUAL_ENV_DIR}" ]; then \
		echo "Directory ${CONF_DIR_CONTEXT}/${VIRTUAL_ENV_DIR} already exists."; \
		echo "Deleting existing virtual environment..."; \
		rm -r ${CONF_DIR_CONTEXT}/${VIRTUAL_ENV_DIR}; \
	fi
	@echo "Creating virtual environment in ${CONF_DIR_CONTEXT}/${VIRTUAL_ENV_DIR}"
	@$(PYTHON_VERSION_12) -m venv ${CONF_DIR_CONTEXT}/${VIRTUAL_ENV_DIR}
	@echo "Upgrading pip and core Python packaging tools..."
	@pushd ${CONF_DIR_CONTEXT}/ && source ${VIRTUAL_ENV_DIR}/bin/activate && pip3 install --upgrade pip setuptools wheel
	@echo "Installing Python dependencies from requirements.txt..."
	@pushd ${CONF_DIR_CONTEXT}/ && source ${VIRTUAL_ENV_DIR}/bin/activate && pip3 install -r requirements.txt
	@echo "Installing required Ansible collections..."
	@pushd ${CONF_DIR_CONTEXT}/ && source ${VIRTUAL_ENV_DIR}/bin/activate && ansible-galaxy collection install community.general --force
	@pushd ${CONF_DIR_CONTEXT}/ && source ${VIRTUAL_ENV_DIR}/bin/activate && ansible-galaxy collection install community.crypto --force
	@pushd ${CONF_DIR_CONTEXT}/ && source ${VIRTUAL_ENV_DIR}/bin/activate && ansible-galaxy collection install community.docker --force

# -----------------------------------
# Target: check_virtual_env
# -----------------------------------
# Description:
# Verifies whether the Python virtual environment is present.
# If missing, triggers the installation process to ensure all dependencies are ready.
check_virtual_env:
	@if [ ! -d "${CONF_DIR_CONTEXT}/${VIRTUAL_ENV_DIR}" ]; then \
		echo "Virtual environment directory ${CONF_DIR_CONTEXT}/${VIRTUAL_ENV_DIR} not found."; \
		echo "Triggering virtual environment setup..."; \
		$(MAKE) install_virtual_env; \
	fi

# -----------------------------------
# Target: provision
# -----------------------------------
# Description:
# Provisions the PostgreSQL HA environment by executing the main Ansible playbook with stack_state=present.
# This initializes the required infrastructure: Consul service discovery, PostgreSQL primary and replicas,
# TLS certificates, security assets, and local volumes.
provision: check_virtual_env
	@pushd ${CONF_DIR_CONTEXT}/ && source ${VIRTUAL_ENV_DIR}/bin/activate && ansible-playbook provision.yml -e "stack_state=present"

# -----------------------------------
# Target: stop
# -----------------------------------
# Description:
# Gracefully stops all services in the PostgreSQL HA environment without removing container state or volumes.
# Useful for temporary shutdown or maintenance without data loss.
stop: check_virtual_env
	@pushd ${CONF_DIR_CONTEXT}/ && source ${VIRTUAL_ENV_DIR}/bin/activate && ansible-playbook provision.yml -e "stack_state=stopped"

# -----------------------------------
# Target: destroy
# -----------------------------------
# Description:
# Destroys the entire PostgreSQL HA stack, including all running containers and their associated volumes.
# Use with caution, as this operation is irreversible and removes all persisted data.
destroy: check_virtual_env
	@pushd ${CONF_DIR_CONTEXT}/ && source ${VIRTUAL_ENV_DIR}/bin/activate && ansible-playbook provision.yml -e "stack_state=absent"
