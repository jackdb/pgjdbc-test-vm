# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/bionic64"
  config.vm.network "private_network", type: "dhcp"
  config.vm.provision :shell, :path => "bootstrap.sh"
  
  # PostgreSQL Server port forwarding
  # [Major].[Minor] => "100[Major][Minor]"
  # Ex: 9.3 => 10093
  config.vm.network "forwarded_port", guest: 10093, host: 10093
  config.vm.network "forwarded_port", guest: 10094, host: 10094
  config.vm.network "forwarded_port", guest: 10095, host: 10095
  config.vm.network "forwarded_port", guest: 10096, host: 10096
  config.vm.network "forwarded_port", guest: 10010, host: 10010
  config.vm.network "forwarded_port", guest: 10011, host: 10011
end
