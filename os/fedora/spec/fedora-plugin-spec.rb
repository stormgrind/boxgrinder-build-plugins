#
# Copyright 2010 Red Hat, Inc.
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

require 'boxgrinder-build-fedora-os-plugin/fedora-plugin'
require 'rspec/rspec-config-helper'

module BoxGrinder
  describe FedoraPlugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = `uname -m`.chomp.strip
    end

    before(:each) do
      @plugin = FedoraPlugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'), :plugin_info => { :class => BoxGrinder::FedoraPlugin, :type => :os, :name => :fedora, :full_name  => "Fedora", :versions   => ["11", "12", "13", "14", "rawhide"] })

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
    end

    it "should normalize packages for i386" do
      packages = ['abc', 'def', 'kernel']

      @appliance_config.hardware.arch = "i386"
      @plugin.normalize_packages( packages )
      packages.should == ['abc', 'def', 'passwd', 'lokkit', 'kernel-PAE']
    end

    it "should normalize packages for x86_64" do
      packages = ['abc', 'def', 'kernel']

      @appliance_config.hardware.arch = "x86_64"
      @plugin.normalize_packages( packages )
      packages.should == ['abc', 'def', 'passwd', 'lokkit', 'kernel']
    end

    it "should add packages for fedora 13" do
      packages = ['kernel']

      @appliance_config.hardware.arch = "x86_64"
      @appliance_config.os.name = "fedora"
      @appliance_config.os.version = "13"
      @plugin.normalize_packages( packages )
      packages.should == ["passwd", "system-config-firewall-base", "selinux-policy-targeted", "dhclient", "kernel"]
    end

    it "should add packages for fedora 14" do
      packages = ['kernel']

      @appliance_config.hardware.arch = "x86_64"
      @appliance_config.os.name = "fedora"
      @appliance_config.os.version = "14"
      @plugin.normalize_packages( packages )
      packages.should == ["passwd", "system-config-firewall-base", "selinux-policy-targeted", "dhclient", "kernel"]
    end

  end
end

