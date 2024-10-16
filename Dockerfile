# From: https://medium.com/@tshenolomos/guide-to-creating-an-sftp-server-with-docker-using-ssh-key-ce9bddb77f39
# And: https://serverfault.com/a/946877

# Use Ubuntu latest as the base image
FROM ubuntu:latest

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Update packages and install OpenSSH Server and vim
RUN apt-get update && \
    apt-get install -y openssh-server vim && \
    rm -rf /var/lib/apt/lists/*

# Set up user for SFTP with no shell login
RUN useradd -m -d /home/sftpuser -s /usr/sbin/nologin -u 1000700000 sftpuser && \
    mkdir -p /home/sftpuser/.ssh && \
    chown sftpuser:sftpuser /home/sftpuser && \
    chmod 700 /home/sftpuser && \
    chown sftpuser:sftpuser /home/sftpuser/.ssh && \
    chmod 700 /home/sftpuser/.ssh

# OpenShift requirements
RUN chmod a+r /etc/shadow && \
    echo "moi" > /run/motd.dynamic.new && \
    chmod 777 /run/motd.dynamic.new

# Copy the public key
# Ensure you replace 'docker_rsa.pub' with your actual public key file name
COPY docker_rsa.pub /home/sftpuser/.ssh/authorized_keys

# Set permissions for the public key
RUN chmod 600 /home/sftpuser/.ssh/authorized_keys && \
    chown sftpuser:sftpuser /home/sftpuser/.ssh/authorized_keys

RUN mkdir /tmp/custom_ssh && chmod 777 /tmp/custom_ssh && \
    echo "Port 2222" > /tmp/custom_ssh/sshd_config && \
    echo "HostKey /tmp/custom_ssh/ssh_host_rsa_key" >> /tmp/custom_ssh/sshd_config && \
    echo "HostKey /tmp/custom_ssh/ssh_host_dsa_key" >> /tmp/custom_ssh/sshd_config && \
    echo "AuthorizedKeysFile  .ssh/authorized_keys" >> /tmp/custom_ssh/sshd_config && \
    echo "ChallengeResponseAuthentication no" >> /tmp/custom_ssh/sshd_config && \
    echo "UsePAM yes" >> /tmp/custom_ssh/sshd_config && \
    echo "Subsystem   sftp    /usr/lib/ssh/sftp-server" >> /tmp/custom_ssh/sshd_config && \
    echo "PidFile /tmp/custom_ssh/sshd.pid" >> /tmp/custom_ssh/sshd_config && \
    echo "Match User sftpuser" >> /tmp/custom_ssh/sshd_config && \
    echo "    ForceCommand internal-sftp" >> /tmp/custom_ssh/sshd_config && \
    echo "    PasswordAuthentication no" >> /tmp/custom_ssh/sshd_config && \
    echo "    PubkeyAuthentication yes" >> /tmp/custom_ssh/sshd_config && \
    echo "    PermitTunnel no" >> /tmp/custom_ssh/sshd_config && \
    echo "    AllowAgentForwarding no" >> /tmp/custom_ssh/sshd_config && \
    echo "    AllowTcpForwarding no" >> /tmp/custom_ssh/sshd_config && \
    echo "    X11Forwarding no" >> /tmp/custom_ssh/sshd_config
#   echo "    ChrootDirectory /home/sftpuser/sftp" >> /tmp/custom_ssh/sshd_config

ADD start.sh /usr/local/bin/start.sh
RUN chmod 777 /usr/local/bin/start.sh

# Expose the SSH port
EXPOSE 2222

# Run SSHD on container start
#CMD ["/usr/sbin/sshd", "-D", "-e"]
#CMD ["/usr/sbin/sshd", "-f", "/tmp/custom_ssh/sshd_config"]
CMD /usr/local/bin/start.sh
