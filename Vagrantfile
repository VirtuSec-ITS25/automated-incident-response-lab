# -*- mode: ruby -*-
# vi: set ft=ruby :
#
# Automated Incident Response Lab
#
# Network layout:
#   wazuh-manager  192.168.56.10  — Wazuh Manager + Ansible control node (6 GB)
#   web-agent      192.168.56.11  — Simulated web server / attack target   (1 GB)
#   db-agent       192.168.56.12  — Simulated database server               (1 GB)
#
# Total RAM: ~8 GB
# All configuration is handled by Ansible after "vagrant up"

MANAGER_IP = "192.168.56.10"
WEB_IP     = "192.168.56.11"
DB_IP      = "192.168.56.12"

Vagrant.configure("2") do |config|
  config.vm.box              = "ubuntu/jammy64"
  config.vm.box_check_update = false
  config.vm.boot_timeout     = 900
  config.vm.synced_folder ".", "/vagrant"

  config.vm.define "wazuh-manager" do |m|
    m.vm.hostname = "wazuh-manager"
    m.vm.network "private_network", ip: MANAGER_IP

    m.vm.provider "virtualbox" do |vb|
      vb.name   = "wazuh-manager"
      vb.memory = 8192
      vb.cpus   = 4
    end

    # 1) Generate SSH key pair and share pubkey via /vagrant
    m.vm.provision "shell", inline: <<-SHELL
      apt-get update -y -qq
      apt-get install -y -qq ansible
      [ -f /home/vagrant/.ssh/id_ed25519 ] || \
        sudo -u vagrant ssh-keygen -t ed25519 \
          -f /home/vagrant/.ssh/id_ed25519 \
          -N "" -C "ansible-control" -q
      # Always overwrite — stale key from a previous run breaks agent SSH auth
      cp /home/vagrant/.ssh/id_ed25519.pub /vagrant/manager_key.pub
      # User-level ansible.cfg so host_key_checking=False is not ignored
      # (/vagrant is world-writable and Ansible ignores cfg files there)
      sudo -u vagrant tee /home/vagrant/.ansible.cfg > /dev/null << 'EOF'
[defaults]
host_key_checking = False
EOF
      echo "=== Wazuh Manager done — VM 1 / 3 ==="
    SHELL

    # 2) Add pubkey to authorized_keys (key now exists from step 1)
    m.vm.provision "shell", inline: <<-SHELL
      grep -qF "$(cat /home/vagrant/.ssh/id_ed25519.pub)" /home/vagrant/.ssh/authorized_keys 2>/dev/null || \
        cat /home/vagrant/.ssh/id_ed25519.pub >> /home/vagrant/.ssh/authorized_keys
      chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
      chmod 600 /home/vagrant/.ssh/authorized_keys
    SHELL
  end

  config.vm.define "web-agent" do |a|
    a.vm.hostname = "web-agent"
    a.vm.network "private_network", ip: WEB_IP

    a.vm.provider "virtualbox" do |vb|
      vb.name   = "wazuh-web-agent"
      vb.memory = 768
      vb.cpus   = 1
    end

    a.vm.provision "shell", inline: <<-SHELL
      while [ ! -f /vagrant/manager_key.pub ]; do sleep 2; done
      grep -qF "$(cat /vagrant/manager_key.pub)" /home/vagrant/.ssh/authorized_keys 2>/dev/null || \
        cat /vagrant/manager_key.pub >> /home/vagrant/.ssh/authorized_keys
      chmod 600 /home/vagrant/.ssh/authorized_keys
      echo "=== Web Agent done — VM 2 / 3 ==="
    SHELL
  end

  config.vm.define "db-agent" do |a|
    a.vm.hostname = "db-agent"
    a.vm.network "private_network", ip: DB_IP

    a.vm.provider "virtualbox" do |vb|
      vb.name   = "wazuh-db-agent"
      vb.memory = 768
      vb.cpus   = 1
    end

    a.vm.provision "shell", inline: <<-SHELL
      while [ ! -f /vagrant/manager_key.pub ]; do sleep 2; done
      grep -qF "$(cat /vagrant/manager_key.pub)" /home/vagrant/.ssh/authorized_keys 2>/dev/null || \
        cat /vagrant/manager_key.pub >> /home/vagrant/.ssh/authorized_keys
      chmod 600 /home/vagrant/.ssh/authorized_keys
      echo "=== DB Agent done — VM 3 / 3 ==="
    SHELL
  end
end