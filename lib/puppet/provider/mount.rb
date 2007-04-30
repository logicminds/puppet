#  Created by Luke Kanies on 2006-11-12.
#  Copyright (c) 2006. All rights reserved.

require 'puppet'

# A module just to store the mount/unmount methods.  Individual providers
# still need to add the mount commands manually.
module Puppet::Provider::Mount
    # This only works when the mount point is synced to the fstab.
    def mount(remount = false)
        # Manually pass the mount options in, since some OSes *cough*OS X*cough* don't
        # read from /etc/fstab but still want to use this type.
        opts = nil
        if self.options and self.options != :absent
            opts = self.options
        end

        if remount and Facter.value(:operatingsystem) != "FreeBSD"
            if opts
                opts = [opts, "remount"].join(",")
            else
                opts = "remount"
            end
        end
        args = []
        args << "-o" << opts
        args << @model[:name]
        mountcmd(*args)
    end

    def remount
        info "Remounting"
        if @model[:remounts] == :true
            mount(true)
        else
            unmount()
            mount()
        end
    end

    # This only works when the mount point is synced to the fstab.
    def unmount
        umount @model[:name]
    end

    # Is the mount currently mounted?
    def mounted?
        platform = Facter["operatingsystem"].value
        df = [command(:df)]
        case Facter["operatingsystem"].value
        # Solaris's df prints in a very weird format
        when "Solaris": df << "-k"
        end
        execute(df).split("\n").find do |line|
            fs = line.split(/\s+/)[-1]
            if platform == "Darwin"
                fs == "/private/var/automount" + @model[:name] or
                    fs == @model[:name]
            else
                fs == @model[:name]
            end
        end
    end
end

# $Id$
