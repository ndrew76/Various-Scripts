#!/usr/bin/perl -w
#
# Copyright 2006 VMware, Inc.  All rights reserved.
#
# USAGE:
#
# vicfg-vswitch.pl [GENERAL_VIPERL_OPTIONS] [ADDITIONAL_OPTIONS]
# where acceptable ADDITIONAL_OPTIONS are the following:
#
# --list                              list vswitches and port groups
# --add <vswitch>                     add vswitch name
# --delete <vswitch>                  delete vswitch
# --link pnic <vswitch>               Sets a pnic as an uplink for the switch
# --unlink pnic <vswitch>             Removes a pnic from the uplinks for the switch
# --check <vswitch>                   check if vswitch exists (return 0 if no; 1 if yes)
# --add-pg <pgname> <vswitch>         adds port group
# --del-pg <pgname> <vswitch>         deletes port group
# --add-pg-uplink pnic --pg <pgname>  add an uplink for portgroup
# --del-pg-uplink pnic --pg <pgname>  delete an uplink for portgroup
# --mtu num <vswitch>                 sets the mtu of the vswitch
# --vlan <#> --pg <pgname> <vswitch>  Updates vlan id for port group
# --check-pg --pg <pgname>            check if port group exists (return 0 if no; 1 if yes)
# --check-pg --pg <pgname> <vswitch>  check if port group exists on a particular vswitch 
# 
# Example:
#
# vicfg-vswitch.pl --add-pg foo vSwitch0
# vicfg-vswitch.pl --mtu 9000 vSwitch0
#

my @options = (
    ['list'],                               # esxcfg-vswitch --list     
    );

use strict;
use warnings;
use Getopt::Long;

use VMware::VIRuntime;
use VMware::VILib;
use VMware::VIExt;

my %opts = (
   vihost => {
      alias => "h",
      type => "=s",
      help => qq!    The host to use when connecting via Virtual Center!,
      required => 0,
   },
   'list' => {
      alias => "l",
      type => "",
      help => qq!    List vswitches and port groups!,
      required => 0,
   },
   '_default_' => {
      type => "=s",
      argval => "vswitch",
      help => qq!    The name of the vswitch!,
      required => 0,
   },
);

Opts::add_options(%opts);
Opts::parse();
Opts::validate();

my $login = 0;

CheckValues();
Util::connect();

$login = 1;
my $exitStatus = 1;                     # assume success

my $host_view = VIExt::get_host_view(1, ['configManager.networkSystem']);
Opts::assert_usage(defined($host_view), "Invalid host.");

#
# find the host
#

my $network_system = Vim::get_view (mo_ref => $host_view->{'configManager.networkSystem'});

   #
   # cycle through various operations
   #
   if (defined OptVal('list')) {
      ListVirtualSwitch ($network_system);
   }
Util::disconnect();

sub OptVal {
  my $opt = shift;
  return Opts::get_option($opt);
}

# Retrieve the set of non viperl-common options for further validation
sub GetSuppliedOptions {
  my @optsToCheck = 
     qw(list add check delete link unlink add-pg del-pg add-pg-uplink del-pg-uplink check-pg vlan pg mtu add-dvp-uplink del-dvp-uplink get-cdp set-cdp dvp _default_);
  my %supplied = ();

  foreach (@optsToCheck) {
     if (defined(Opts::get_option($_))) {
        $supplied{$_} = 1;
     }
  }

  return %supplied;
}

use Data::Dumper;


sub ListVirtualSwitch {
   my ($network_system) = @_;
   my $vSwitches = $network_system->networkInfo->vswitch;
   foreach my $vSwitch (@$vSwitches) {
      print $vSwitch->name."|";
   }
   
}


sub CheckValues {
   my %locals = GetSuppliedOptions();
   my $masterMap = BuildBits (keys %locals);	# build the master list

   foreach (@options) {
      my $bitmap = BuildBits ( @$_);
      return 1 if ($bitmap == $masterMap);
   }
   
   print "The options are invalid.\n";
   Opts::usage();
   exit(1);
}

sub BuildBits {
   my (@arr) = @_;
   my %list;
   foreach (@arr) {
      $list{$_}++; 
   } 
   my $bit = 0;
   foreach (sort keys %opts) {
      $bit = ($bit | 1) if (defined $list{$_}); 
      $bit = $bit << 1;
   }
   return $bit;
}