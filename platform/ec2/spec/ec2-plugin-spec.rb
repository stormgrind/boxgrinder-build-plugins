require 'boxgrinder-build-ec2-platform-plugin/ec2-plugin'
require 'rspec/rspec-config-helper'

module BoxGrinder
  describe EC2Plugin do
    include RSpecConfigHelper

    before(:all) do
      @arch = `uname -m`.chomp.strip
    end

    before(:each) do
      @plugin = EC2Plugin.new.init(generate_config, generate_appliance_config, :log => Logger.new('/dev/null'), :plugin_info => {:class => BoxGrinder::EC2Plugin, :type => :platform, :name => :ec2, :full_name  => "Amazon Elastic Compute Cloud (Amazon EC2)"})

      @config             = @plugin.instance_variable_get(:@config)
      @appliance_config   = @plugin.instance_variable_get(:@appliance_config)
      @exec_helper        = @plugin.instance_variable_get(:@exec_helper)
      @log                = @plugin.instance_variable_get(:@log)
    end

    it "should download a rpm to cache directory" do
      @exec_helper.should_receive(:execute).with( "mkdir -p /var/cache/boxgrinder/sources-cache" )
      @exec_helper.should_receive(:execute).with( "wget http://rpm_location -O /var/cache/boxgrinder/sources-cache/rpm_name" )
      @plugin.cache_rpms( 'rpm_name' => 'http://rpm_location' )
    end

#    it "should get new free loop device" do
#      @exec_helper.should_receive(:execute).with( "losetup -f 2>&1" ).and_return(" /dev/loop1   ")
#      @plugin.get_loop_device.should == "/dev/loop1"
#    end
#
#    it "should create filesystem" do
#      @exec_helper.should_receive(:execute).with( "mkfs.ext3 -F build/appliances/#{`uname -m`.chomp.strip}/fedora/11/full/ec2-plugin/tmp/full.ec2")
#      @plugin.ec2_create_filesystem
#    end
#
#    it "should mount image" do
#      FileUtils.should_receive(:mkdir_p).with("mount_dir").once
#
#      @plugin.should_receive(:get_loop_device).and_return("/dev/loop0")
#      @exec_helper.should_receive(:execute).with( "losetup /dev/loop0 disk" )
#      @exec_helper.should_receive(:execute).with( "parted /dev/loop0 'unit B print' | grep -e '^ [0-9]' | awk '{ print $2 }'" ).and_return("1234")
#      @exec_helper.should_receive(:execute).with( "losetup -d /dev/loop0" )
#
#      @plugin.should_receive(:get_loop_device).and_return("/dev/loop1")
#      @exec_helper.should_receive(:execute).with( "losetup -o 1234 /dev/loop1 disk" )
#      @exec_helper.should_receive(:execute).with( "e2label /dev/loop1" ).and_return("/")
#      @exec_helper.should_receive(:execute).with( "mount /dev/loop1 -t ext3 mount_dir" )
#
#      @plugin.mount_image("disk", "mount_dir")
#    end
#
#    it "should sync files" do
#      @exec_helper.should_receive(:execute).with( "rsync -u -r -a  from/* to" )
#      @plugin.sync_files("from", "to")
#    end

    it "should create devices" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:sh).once.with("/sbin/MAKEDEV -d /dev -x console")
      guestfs.should_receive(:sh).once.with("/sbin/MAKEDEV -d /dev -x null")
      guestfs.should_receive(:sh).once.with("/sbin/MAKEDEV -d /dev -x zero")

      @log.should_receive(:debug).once.with("Creating required devices...")
      @log.should_receive(:debug).once.with("Devices created.")

      @plugin.create_devices( guestfs )
    end

    it "should upload fstab" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:upload).once.with(any_args(), "/etc/fstab")

      @log.should_receive(:debug).once.with("Uploading '/etc/fstab' file...")
      @log.should_receive(:debug).once.with("'/etc/fstab' file uploaded.")

      @plugin.upload_fstab( guestfs )
    end

    it "should enable networking" do
      guestfs = mock("guestfs")

      guestfs.should_receive(:sh).once.with("/sbin/chkconfig network on")
      guestfs.should_receive(:upload).once.with(any_args(), "/etc/sysconfig/network-scripts/ifcfg-eth0")

      @log.should_receive(:debug).once.with("Enabling networking...")
      @log.should_receive(:debug).once.with("Networking enabled.")

      @plugin.enable_networking( guestfs )
    end

    it "should upload rc_local" do
      guestfs   = mock("guestfs")
      tempfile  = mock("tempfile")

      Tempfile.should_receive(:new).with("rc_local").and_return(tempfile)
      File.should_receive(:read).with(any_args()).and_return("with other content")

      guestfs.should_receive(:read_file).once.ordered.with("/etc/rc.local").and_return("content ")
      tempfile.should_receive(:<<).once.ordered.with("content with other content")
      tempfile.should_receive(:flush).once.ordered
      tempfile.should_receive(:path).once.ordered.and_return("path")
      guestfs.should_receive(:upload).once.ordered.with("path", "/etc/rc.local")
      tempfile.should_receive(:close).once.ordered

      @log.should_receive(:debug).once.with("Uploading '/etc/rc.local' file...")
      @log.should_receive(:debug).once.with("'/etc/rc.local' file uploaded.")

      @plugin.upload_rc_local( guestfs )
    end

    it "should install additional packages" do
      guestfs = mock("guestfs")

      kernel_rpm = (@arch == "x86_64" ? "kernel-xen-2.6.21.7-2.fc8.x86_64.rpm" : "kernel-xen-2.6.21.7-2.fc8.i686.rpm")

      rpms = { kernel_rpm => "http://repo.oddthesis.org/packages/other/#{kernel_rpm}", "ec2-ami-tools.noarch.rpm" => "http://s3.amazonaws.com/ec2-downloads/ec2-ami-tools.noarch.rpm" }

      @plugin.should_receive(:cache_rpms).ordered.with(rpms)

      guestfs.should_receive(:mkdir_p).ordered.with("/tmp/rpms")
      guestfs.should_receive(:upload).ordered.with("/var/cache/boxgrinder/sources-cache/#{kernel_rpm}", "/tmp/rpms/#{kernel_rpm}")
      guestfs.should_receive(:upload).ordered.with("/var/cache/boxgrinder/sources-cache/ec2-ami-tools.noarch.rpm", "/tmp/rpms/ec2-ami-tools.noarch.rpm")
      guestfs.should_receive(:sh).ordered.with("rpm -ivh --nodeps /tmp/rpms/*.rpm")
      guestfs.should_receive(:rm_rf).ordered.with("/tmp/rpms")

      guestfs.should_receive(:sh).ordered.with("setarch #{@arch} yum -y install ruby rsync curl")

      @log.should_receive(:debug).ordered.with("Installing additional packages (#{kernel_rpm}, ec2-ami-tools.noarch.rpm)...")
      @log.should_receive(:debug).ordered.with("Additional packages installed.")

      @plugin.install_additional_packages( guestfs )
    end

    it "should change configuration" do
      guestfs_helper = mock("GuestFSHelper")

      guestfs_helper.should_receive(:augeas)

      @plugin.change_configuration( guestfs_helper )
    end

    it "should use xvda disks for Fedora 13" do
      @appliance_config.os.version = '13'
      @plugin.disk_device_prefix.should == 'xv'
    end

    it "should use xvda disks for Fedora 12" do
      @appliance_config.os.version = '12'
      @plugin.disk_device_prefix.should == 'xv'
    end

    it "should use sda disks for Fedora < 12" do
      @appliance_config.os.version = '11'
      @plugin.disk_device_prefix.should == 's'
    end
  end
end

