#!/usr/bin/perl -w
#
# Copyright 2008 VMware, Inc. All rights reserved.
#
use strict;
use warnings;
use Getopt::Long;

use VMware::VIRuntime;
use VMware::VILib;
use VMware::VIExt;

my $PORT = 3260;

my %opts = (
   'vihost' => {
      alias => "h",
      type => "=s",
      help => qq!
         The host to use when connecting via Virtual Center.
      !,
      required => 0,
   },
   'discovery' => {
      alias => "D",
      type => "",
      help => qq!
         Discovery addresses properties and configuration.
      !,
      required => 0,
   },
   'static' => {
      alias => "S",
      type => "",
      help => qq!
         Static discovery targets properties and configuration.
      !,
      required => 0,
   },
   'target' => {
      alias => "T",
      type => "",
      help => qq!
         List all targets information.
      !,
      required => 0,
   },
   'authentication' => {
      alias => "A",
      type => "",
      help => qq!
         Authentication properties and configuration.
      !,
      required => 0,
   },
   'network' => {
      alias => "N",
      type => "",
      help => qq!
         Network properties and configuration.
      !,
      required => 0,
   },
   'phba' => {
      alias => "P",
      type => "",
      help => qq!
         List Phba and node information.
      !,
      required => 0,
   },
   'lun' => {
      alias => "L",
      type => "",
      help => qq!
         List active LUNs information.
      !,
      required => 0,
   },
   'pnp' => {
      alias => "p",
      type => "",
      help => qq!
         List Physical Network Portal properties.
      !,
      required => 0,
   },
   'iscsiname' => {
      alias => "I",
      type => "",
      help => qq!
         List or configure iSCSI initiator name or alias.
      !,
      required => 0,
   },
   'parameter' => {
      alias => "W",
      type => "",
      help => qq!
         For iSCSI parameters operations.
      !,
      required => 0,
   },
   'list' => {
      alias => "l",
      type => "",
      help => qq!
         List operation.  Used with --discovery, --static, --target, --lun, \
         --authentication, --phba, --network, --pnp, --iscsiname, --parameter,\
         --swiscsi or --adapter options.
      !,
      required => 0,
   },
   'add' => {
      alias => "a",
      type => "",
      help => qq!
         Add operation.  Used with --discovery or --static option.
      !,
      required => 0,
   },
   'remove' => {
      alias => "r",
      type => "",
      help => qq!
         Remove operation.  Used with --discovery or --static option.
      !,
      required => 0,
   },
   'ip' => {
      alias => "i",
      type => "=s",
      help => qq!
         Specify IP address or DNS recognized domain name.  Used with \
         --discovery, --static, --authentication, --network, or \
         --parameter option.
      !,
      required => 0,
   },
   'name' => {
      alias => "n",
      type => "=s",
      help => qq!
         Initiator or target iSCSI name.  Used with --static, \
         --authentication, --iscsiname, or --parameter option.
      !,
      required => 0,
   },
   'level' => {
      alias => "c",
      type => "=s",
      help => qq!
         Authentication level.  Used with --authentication option.
      !,
      required => 0,
   },
   'method' => {
      alias => "m",
      type => "=s",
      help => qq!
         Authentication method, allows 'CHAP'.  Used with --authentication \
         option.
      !,
      required => 0,
   },
   'auth_username' => {
      alias => "u",
      type => "=s",
      help => qq!
         Authentication username.  Used with --authentication option.
      !,
      required => 0,
   },
   'auth_password' => {
      alias => "w",
      type => "=s",
      help => qq!
         Authentication password.  Used with --authentication option.
      !,
      required => 0,
   },
   'mutual' => {
      alias => "b",
      type => "",
      help => qq!
         If set, indicates mutual CHAP.  Used with --authentication option.
      !,
      required => 0,
   },
   'target_id' => {
      alias => "t",
      type => "=s",
      help => qq!
         Target ID.  Used with --lun option.
      !,
      required => 0,
   },
   'subnetmask' => {
      alias => "s",
      type => "=s",
      help => qq!
         Subnet mask.  Used with --network option.
      !,
      required => 0,
   },
   'gateway' => {
      alias => "g",
      type => "=s",
      help => qq!
         Default gateway.  Used with --network option.
      !,
      required => 0,
   },
   'mtu' => {
      alias => "M",
      type => "=s",
      help => qq!
         MTU size.  Used with --pnp option.
      !,
      required => 0,
   },
   'alias' => {
      alias => "k",
      type => "=s",
      help => qq!
         iSCSI initiator alias name.  Used with --iscsiname option.
      !,
      required => 0,
   },
   'detail' => {
      alias => "f",
      type => "",
      help => qq!
         Details of iSCSI parameters.  Used with --parameter option.
      !,
      required => 0,
   },
   'set' => {
      alias => "j",
      type => "=s",
      help => qq!
         Set iSCSI parameter specified by <name> to the value specified by \
         <value>.  Provide <name>=<value> pair to this option.  The <name> \
         can be one of the parameter names listed in the --parameter --list \
         option plus 'dataDigestType', or 'headerDigestType' when used with \
         --parameter option.  The <name> can be 'ARP' when used with \
         --network option.
      !,
      required => 0,
   },
   'reset' => {
      alias => "o",
      type => "=s",
      help => qq!
         Reset target level specified iSCSI parameter to be inherited from \
         adapter level. Provide <name>.  The <name> can be one of the \
         parameter names listed in the --parameter --list option. Used with \
         --parameter option.
      !,
      required => 0,
   },
   'reset_auth' => {
      alias => "z",
      type => "",
      help => qq!
         Reset target level authentication properties to be inherited from \
         adapter level.  Used with --authentication option.
      !,
      required => 0,
   },
   'swiscsi' => {
      alias => "E",
      type => "",
      help => qq!
         Software iSCSI enabling configuration or information.
      !,
      required => 0,
   },
   'enable' => {
      alias => "e",
      type => "",
      help => qq!
         Enable operation.  Used with --swiscsi option.
      !,
      required => 0,
   },
   'disable' => {
      alias => "q",
      type => "",
      help => qq!
         Disable operation.  Used with --swiscsi option.
      !,
      required => 0,
   },
   'adapter' => {
      alias => "H",
      type => "",
      help => qq!
         List iSCSI adapter(s).
      !,
      required => 0,
   },
   '_default_' => {
      type => "=s",
      argval => "vmhba",
      help => qq!
         Adapter name. Not used with --swiscsi, --adapter option.
      !,
      required => 0,
   },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();


my $list = Opts::get_option('list');
my $dev = Opts::get_option('adapter');
my $adapter = Opts::get_option('_default_');

Util::connect();

my $host_view = VIExt::get_host_view(1, ['config.product.version', 'configManager.storageSystem']);
Opts::assert_usage($host_view, "Invalid host.");

check_version();

my $ss = Vim::get_view (mo_ref => $host_view->{'configManager.storageSystem'});
if (!$ss->storageDeviceInfo) {
   VIExt::fail("StorageDeviceInfo is not defined.");
}

my $hbas = $ss->storageDeviceInfo->hostBusAdapter;
my $hba = undef;
my $usage_error = 0;

if (defined $adapter) {   
   my $found = 0;
   foreach my $h (@$hbas) {
      if ($h->device eq $adapter && $h->isa('HostInternetScsiHba')) {
         $found = 1;
         $hba = $h;
         last;
      }
   }
   if (!$found) {
      VIExt::fail("Adapter $adapter is not an iSCSI adapter.");
   }
}


if ($dev) {
   adapter_op();
} else {
   Opts::usage();
   exit 1;
}

if ($usage_error) {
   Opts::usage();
   exit 1;
}

Util::disconnect();

sub check_version {
   my $host_version = $host_view->{'config.product.version'};
   if ($host_version ne 'e.x.p' && $host_version !~ /^4./ && $host_version !~ /^5./) {
     VIExt::fail("ESX host version is $host_version. " .
                  "This operation is supported on ESX 4.x, ESXi 4.x, ESXi 5.x or " .
                  "through VC 4.x, VC 5.x");
   }
}

sub adapter_op {
   if ($list) {
      foreach my $h (@$hbas) {
         if ($h->isa('HostInternetScsiHba')) {
			if ($h->model  =~ /Software/ )  {
				print $h->device;
			}
         }
      }
   } else {
      $usage_error = 1;  
   }
}

sub swiscsi_op {
   my $option = undef;
   
   if ($list) {
      if ($ss->storageDeviceInfo->softwareInternetScsiEnabled) {
         print "Software iSCSI is enabled.\n";
      } else {
         print "Software iSCSI is not enabled.\n";
      }
   } 
 }