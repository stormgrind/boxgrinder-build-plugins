require 'rubygems'
require 'jeweler'
require 'spec/rake/spectask'
require 'rcov'

MAIN_PLUGIN_VERSION = '0.0.1'

plugins = {
        "boxgrinder-build-local-delivery-plugin"  => { :dir => "delivery/local", :desc => 'Local Delivery Plugin' },
        "boxgrinder-build-s3-delivery-plugin"     => { :dir => "delivery/s3", :desc => 'Amazon Simple Storage Service (Amazon S3) Delivery Plugin', :deps => { 'aws-s3' => '>= 0.6.2', 'amazon-ec2' => '>= 0.9.6' }},
        "boxgrinder-build-sftp-delivery-plugin"   => { :dir => "delivery/sftp", :desc => 'SSH File Transfer Protocol Delivery Plugin', :deps => { 'net-sftp' => '>= 2.0.4', 'net-ssh' => '>= 2.0.20', 'progressbar' => '0.9.0' }},

        "boxgrinder-build-rpm-based-os-plugin"    => { :dir => "os/rpm-based", :desc => 'RPM Based Operating System Plugin' },
        "boxgrinder-build-fedora-os-plugin"       => { :dir => "os/fedora", :desc => 'Fedora Operating System Plugin', :deps => { 'boxgrinder-build-rpm-based-os-plugin' => '>= 0.0.1' }},
        "boxgrinder-build-rhel-os-plugin"         => { :dir => "os/rhel", :desc => 'Red Hat Enterprise Linux Operating System Plugin', :deps => { 'boxgrinder-build-rpm-based-os-plugin' => '>= 0.0.1' }},
        "boxgrinder-build-centos-os-plugin"       => { :dir => "os/centos", :desc => 'CentOS Operating System Plugin', :deps => { 'boxgrinder-build-rhel-os-plugin' => '>= 0.0.1' }},

        "boxgrinder-build-vmware-platform-plugin" => { :dir => "platform/vmware", :desc => 'VMware Platform Plugin' },
        "boxgrinder-build-ec2-platform-plugin"    => { :dir => "platform/ec2", :desc => 'Elastic Compute Cloud (EC2) Platform Plugin' }
}

plugins.each do |name, info|
  Jeweler::Tasks.new( :base_dir => info[:dir] ) do |s|
    s.name              = name
    s.summary           = info[:desc]
    s.version           = info[:version].nil? ? MAIN_PLUGIN_VERSION : info[:version]
    s.email             = "info@boxgrinder.org"
    s.homepage          = "http://www.jboss.org/stormgrind/projects/boxgrinder/build.html"
    s.description       = "BoxGrinder Build #{info[:desc]}"
    s.authors           = ["Marek Goldmann"]
    s.rubyforge_project = "boxgrinder-build-plugins"

    info[:deps].each do |dep, version|
      s.add_dependency dep, version
    end unless info[:deps].nil?

    s.add_dependency 'boxgrinder-build', '>= 0.4.2'
  end
end

desc "Install all built gems"
task "go" => [ "gemspec", "build" ] do
  plugins.each do |name, info|
    puts `gem uninstall -I #{name}`
    puts `gem install --ignore-dependencies #{info[:dir]}/pkg/#{name}*.gem`
  end
end