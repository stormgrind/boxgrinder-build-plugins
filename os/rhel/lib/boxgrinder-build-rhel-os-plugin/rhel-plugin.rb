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

require 'boxgrinder-build-rpm-based-os-plugin'

module BoxGrinder
  class RHELPlugin < RPMBasedOSPlugin
    def build_rhel( repos = {} )
      adjust_partition_table

      normalize_packages( @appliance_config.packages.includes )

      build_with_appliance_creator( repos )  do |guestfs, guestfs_helper|
        # required for VMware
        @linux_helper.recreate_kernel_image( guestfs, ['mptspi'] )

        @log.debug "Applying root password..."
        guestfs.sh( "/usr/bin/passwd -d root" )
        guestfs.sh( "/usr/sbin/usermod -p '#{@appliance_config.os.password.crypt((0...8).map{65.+(rand(25)).chr}.join)}' root" )
        @log.debug "Password applied."
      end
    end

    def normalize_packages( packages )
      packages << "curl" unless packages.include?("curl")

      case @appliance_config.os.version
        when "5" then
          packages << "system-config-securitylevel-tui" unless packages.include?("system-config-securitylevel-tui")
      end
    end

    # https://bugzilla.redhat.com/show_bug.cgi?id=466275
    def adjust_partition_table
      @appliance_config.hardware.partitions['/boot'] = { 'root' => '/boot', 'size' => 0.1 } if @appliance_config.hardware.partitions['/boot'].nil?
    end

    def execute
      build_rhel
    end
  end
end
