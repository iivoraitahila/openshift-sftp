#!/bin/bash
mkdir /tmp/custom_ssh
ssh-keygen -f /tmp/custom_ssh/ssh_host_rsa_key -N '' -t rsa
ssh-keygen -f /tmp/custom_ssh/ssh_host_dsa_key -N '' -t dsa
/usr/sbin/sshd -f /tmp/custom_ssh/sshd_config
