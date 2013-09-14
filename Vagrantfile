# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"

  config.vm.share_folder "bootstrap", "/mnt/bootstrap", ".", :create => true
  config.vm.provision :shell, :path => "Vagrant-setup/bootstrap.sh"
  
  # PostgreSQL Server port forwarding
  # [Major].[Minor] => "100[Major][Minor]"
  # Ex: 9.3 => 10093
  config.vm.forward_port 5432, 10084
  config.vm.forward_port 5433, 10090
  config.vm.forward_port 5434, 10091
  config.vm.forward_port 5435, 10092
  config.vm.forward_port 5436, 10093
end
