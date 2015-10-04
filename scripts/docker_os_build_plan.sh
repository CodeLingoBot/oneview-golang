#!/bin/bash

echo "This script will pre-configure the server to run docker"
DOCKER_USER_INPUT=$1
DOCKER_PUBKEY_INPUT=$2
DOCKER_HOSTNAME=$3
DOCKER_PROXY=$4
PROXY_ENABLE=$5
INTERFACE=$6
if [ -z "${DOCKER_PUBKEY_INPUT}" ]; then
  echo "ERROR : this script requires a public key for docker user!"
  echo "USAGE: $0 <docker user> '<public key>'"
  exit 1
fi

DOCKER_USER=${DOCKER_USER_INPUT:-"docker"}
DOCKER_PROXY=${DOCKER_PROXY_INPUT}
DOCKER_PUBKEY=${DOCKER_PUBKEY_INPUT}

# boot the external interface, replace this to another interface dependening on your hardware
ifup $INTERFACE
echo "Completed bringing $INTERFACE up, $?"

# optionally set some persistent proxy server configuration
if [ "${PROXY_ENABLE}" = "true" ]; then
cat >> "/etc/environment" << EOF
${DOCKER_PROXY}
EOF
echo "Completed update to /etc/environment, $?"
fi

# create a service account
if [ "$DOCKER_USER" = "root" ]; then
  echo "WARNING : docker-engine user should not be configured as root on bare metal systems, ${DOCKER_USER}."
else
  useradd "${DOCKER_USER}" -d "/home/${DOCKER_USER}"
  echo "Completed adding user account ${DOCKER_USER}, $?"
fi

# setup .ssh folderls -ak
if [ ! -d "/home/${DOCKER_USER}/.ssh" ]; then
  mkdir -p "/home/${DOCKER_USER}/.ssh"
  chmod 700 "/home/${DOCKER_USER}/.ssh"
  chown "${DOCKER_USER}:${DOCKER_USER}" "/home/${DOCKER_USER}/.ssh"
  echo "Completed updating permissions and folders for /home/${DOCKER_USER}/.ssh, $?"
fi
if [ ! -f "/home/${DOCKER_USER}/.ssh/authorized_keys" ] ; then
  touch "/home/${DOCKER_USER}/.ssh/authorized_keys"
  chmod 600 "/home/${DOCKER_USER}/.ssh/authorized_keys"
  chown "${DOCKER_USER}:${DOCKER_USER}" "/home/${DOCKER_USER}/.ssh/authorized_keys"
  echo "Completed updating permissions for /home/${DOCKER_USER}/.ssh/authorized_keys, $?"
fi
cat >> "/home/${DOCKER_USER}/.ssh/authorized_keys" << EOF
${DOCKER_PUBKEY}
EOF

# modify /home/{user}/.bash_profile to set a persistent proxy
if [ "${PROXY_ENABLE}" = "true" ]; then
cat >> "/home/${DOCKER_USER}/.bash_profile" << EOF
${DOCKER_PROXY}
EOF
fi

# give sudoers access
cat >> "/etc/sudoers.d/90-${DOCKER_USER}" << SUDOERS_EOF
# User rules for icsp docker user
${DOCKER_USER} ALL=(ALL) NOPASSWD:ALL
SUDOERS_EOF
echo "Completed updating permissions for sudoers on user ${DOCKER_USER}, $?"

# modify primary nic eno50 to start on boot
sed -i 's/ONBOOT=no/ONBOOT=yes/g' /etc/sysconfig/network-scripts/ifcfg-eno50
sed -i "s/localhost.localdomain/${DOCKER_HOSTNAME}/g" /etc/hostname
echo "Completed hostname update : $(cat /etc/hostname), $?"

echo "public_ip=$(ifconfig ${INTERFACE}|grep inet |head -1 | awk '{print $2}')"
shutdown -r now

echo "docker customizations complete"