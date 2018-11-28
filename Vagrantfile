# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant::Config.run do |config|
  config.vm.box = "ubuntu/bionic64"

  config.vm.provision :shell, :path => "bootstrap.sh"
  
  # PostgreSQL Server port forwarding
  # [Major].[Minor] => "100[Major][Minor]"
  # Ex: 9.3 => 10093
  config.vm.forward_port 10093, 10093
  config.vm.forward_port 10094, 10094
  config.vm.forward_port 10095, 10095
  config.vm.forward_port 10096, 10096
  config.vm.forward_port 10010, 10010
  config.vm.forward_port 10011, 10011
end
