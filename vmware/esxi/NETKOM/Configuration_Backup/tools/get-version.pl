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

Opts::parse();
Util::connect();

my $host_view = VIExt::get_host_view(1, ['config.product.version', 'configManager.storageSystem']);
print $host_view->{'config.product.version'};;

Util::disconnect();

