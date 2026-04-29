# Vagrantfile — PC A (Wazuh Manager)
# ⚠️  Change bridge: "Ethernet" to match your network adapter.
#     Run: Get-NetAdapter | Select-Object Name, Status

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/jammy64"

  config.vm.define "wazuh-manager" do |w|
    w.vm.hostname = "wazuh-manager"
    w.vm.network "public_network", bridge: ENV['VAGRANT_BRIDGE'] || "Ethernet" # ⚠️  Set VAGRANT_BRIDGE env var on your machine to match your network adapter (e.g., Wi-Fi).
    w.vm.provider "virtualbox" do |vb|
      vb.memory = 6144   # Minimum for Wazuh
      vb.cpus   = 4
      vb.name   = "wazuh-manager"
    end
  end
end
