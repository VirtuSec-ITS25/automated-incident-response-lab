# Vagrantfile — PC A (Wazuh Manager)
# ⚠️  Change bridge: "Ethernet" to match your network adapter.
#     Run: Get-NetAdapter | Select-Object Name, Status

Vagrant.configure("2") do |config|
  # Increase boot timeout for slow starts
  config.vm.boot_timeout = 600  

  # Wazuh Manager Node
  config.vm.define "wazuh-manager" do |mgr|
    mgr.vm.box = "ubuntu/focal64"
    mgr.vm.network "private_network", ip: "192.168.56.10"
    mgr.vm.hostname = "wazuh-manager"
    mgr.vm.provider "virtualbox" do |vb|
      vb.memory = "6144"
      vb.cpus = 2
      vb.name = "wazuh-manager"
    end
  end

  # Web Agent Node
  config.vm.define "web-agent" do |web|
    web.vm.box = "ubuntu/focal64"
    web.vm.network "private_network", ip: "192.168.56.11"
    web.vm.hostname = "web-agent"
    web.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.name = "web-agent"
    end
  end

  # Database Agent Node
  config.vm.define "db-agent" do |db|
    db.vm.box = "ubuntu/focal64"
    db.vm.network "private_network", ip: "192.168.56.12"
    db.vm.hostname = "db-agent"
    db.vm.provider "virtualbox" do |vb|
      vb.memory = "1024"
      vb.name = "db-agent"
    end
  end

end