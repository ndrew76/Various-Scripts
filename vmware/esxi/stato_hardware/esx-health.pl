#!/usr/bin/perl -w
#
# Orignally developed by William Lam, 12/11/2009
#   http://engineering.ucsb.edu/~duonglt/vmware
#   http://communities.vmware.com/docs/DOC-9852
#
# Further development by James Pearce
#
# Updated 18-Jan-10
#   - Enhanced report layout wih colour coding of line items according to status
#   - Added ALERT reference to message title if alerts (non-green) status items are present
#   - Added simple check of CPU and RAM usage, and reporting on these
#   - Added command line email options (optional)
#   - Removed reference to UNIX RM command (report html is now kept in working folder)
#   - Added append to log file of date/time and result (log file is command line option)
#   - Amended report name
#
# Updated 01-Aug-10
#   - Added optional command line parameters 'memwarnpc' and 'cpuwarnpc', which allow the
#     percentage utilisation at which to generate a warning for these functions.
#     If not specified, defaults are 75% for CPU and 85% for RAM.
#
# Updated 02-Aug-10
#   - Corrected reporting on numeric sensor values (i.e. fan speeds, temperatures etc)
#     per input from Murray Finch
#
# Updated 18-Aug-10
#   - Added ability to exclude output matching specified criteria per input from
#     reader Tim
#
# Updated 12-Oct-10
#   - Added ability to track the number of alerts between runs, using this to send an
#     alert by email only if it has changed, per the request of reader Jonas.
#
# Updated 07-Nov-10
#   - Added --warnofsnapshots option, which considers any running VM with a snapshot
#     to be a warning condition
#   - Added datastore usage checking (see switches dscriticalpc and dswarnpc)
#   - Added multiple email recipient ability (seperate mail addresses with semi-colon)
#
#
# Updated 09-Nov-10
#   - Added --statusfile option, to enable seperate warning status tracking when used
#     with multiple hosts
#
# Updated 8-Jan-11
#   - Added --concise option, which includes only section headings with alert
#     items in them, and only the alert items themselves, to aid viewing on Blackberry
#     and so on
#   - Added summary to section titles (such as Healthy, 1 warning, etc)
#
# Updated 23-Nov-11
#   - Added --warnonalerts option, which modifies --alertonchange to always send mail
#     if alert count > 0
#   - Minor fixes & coding improvements
#
 
use strict;
use warnings;
use VMware::VIRuntime;
use VMware::VILib;
use Net::SMTP;
 
 
# define custom options for vm and target host
my %opts = (
   'hostfile' => {
      type => "=s",
      help => "List of hosts to perform operation on",
      required => 0,
   },
   'reportname' => {
      type => "=s",
      help => "Name of the report to email out",
      required => 0,
      default => 'esx-host-health-report.html',
   },
   'mailhost' => {
      type => "=s",
      help => "DNS name of mail server to use to send report",
      required => 0,
      default => '',
   },
   'maildomain' => {
      type => "=s",
      help => "Email domain name (i.e. vmware.com)",
      required => 0,
      default => '',
   },
   'mailfrom' => {
      type => "=s",
      help => "Email address alerts will be sent from",
      required => 0,
      default => '',
   },
   'mailto' => {
      type => "=s",
      help => "Email address of recipient",
      required => 0,
      default => '',
   },
   'cpuwarnpc' => {
      type => "=i",
      help => "Percentage CPU utilisation at which to warn (i.e. 75 to warn if >75%)",
      required => 0,
      default => 75,
   },
   'memwarnpc' => {
      type => "=i",
      help => "Percentage RAM utilisation at which to warn (i.e. 85 to warn if >85%)",
      required => 0,
      default => 85,
   },
   'dswarnpc' => {
      type => "=i",
      help => "Percentage of datastore free space at which to warn (i.e. 25 to warn if <25% free)",
      required => 0,
      default => 25,
   },
   'dscriticalpc' => {
      type => "=i",
      help => "Percentage of datastore free space at which to warn RED (i.e. 10 to warn if <10% free)",
      required => 0,
      default => 10,
   },
   'exclude' => {
      type => "=s",
      help => "PERL Regular expression to supress certain sensors (i.e. 'Power Supply' or 'PSU 2|Fan 4|Intrusion')",
      required => 0,
      default => 'zzzzz',
   },
   'warnofsnapshots' => {
      type => "",
      help => "Consider running VMs with snapshots to be alert items",
      required => 0,
      default => 0,
   },
   'warnonchange' => {
      type => "",
      help => "Only send an email alert if the number of warnings reported has changed since last run",
      required => 0,
      default => 0,
   },
   'warnonalerts' => {
      type => "",
      help => "Modifies --alertonchange to always send mail if alert count > 0",
      required => 0,
      default => 0,
   },
   'concise' => {
      type => "",
      help => "Include on report only section headings with alert counts and alert items",
      required => 0,
      default => 0,
   },
   'logfile' => {
      type => "=s",
      help => "Name of logfile to use",
      required => 0,
      default => 'esx-health.log',
   },
   'statusfile' => {
      type => "=s",
      help => "Name of file to store host alerts in (for use with --warnonchange)",
      required => 0,
      default => 'esx-health-status.txt',
   },
);
 
# read and validate command-line parameters 
Opts::add_options(%opts);
Opts::parse();
Opts::validate();
Util::connect();
 
 
# CHECK HOST IS ESX 3.5 OR ABOVE
 
my $hosttype = &validateConnection('3.5.0','undef','both');
 
 
# GLOBAL VARS
 
my ($host_view,$task_ref,$hostfile,$reportname,$mailhost,$maildomain,$mailfrom,$mailto);
my ($cpuwarnpc,$memwarnpc,$dswarnpc,$dscriticalpc,$exclude,$warnonchange,$warnonalerts,$warnofsnapshots,$concise);
my ($logfile,$statusfile);
my @host_list = ();
my $debug = 1;
my $report_name = "ESX host health report";
my $alerts = 0;
 
$hostfile = Opts::get_option("hostfile");
$reportname = Opts::get_option("reportname");
$mailhost = Opts::get_option("mailhost");
$maildomain = Opts::get_option("maildomain");
$mailfrom = Opts::get_option("mailfrom");
$mailto = Opts::get_option("mailto");
$cpuwarnpc = Opts::get_option("cpuwarnpc");
$memwarnpc = Opts::get_option("memwarnpc");
$dswarnpc = Opts::get_option("dswarnpc");
$dscriticalpc = Opts::get_option("dscriticalpc");
$exclude = Opts::get_option("exclude");
$warnonchange = Opts::get_option("warnonchange");
$warnonalerts = Opts::get_option("warnonalerts");
$warnofsnapshots = Opts::get_option("warnofsnapshots");
$concise = Opts::get_option("concise");
$logfile = Opts::get_option("logfile");
$statusfile = Opts::get_option("statusfile");
 
my $LOG_FILE = $logfile;
my $STATUS_FILE = $statusfile;
 
# EMAIL CONFIGURATION FROM COMMAND LINE PARAMETERS
 
my $SEND_MAIL = "no";
my $EMAIL_HOST = $mailhost;
my $EMAIL_DOMAIN = $maildomain;
my $EMAIL_TO = $mailto;
my $EMAIL_FROM = $mailfrom;
my $EMAIL_SUBJECT_NORMAL = 'vmware Host Health Report - Status Normal';
my $EMAIL_SUBJECT_ALERTS = 'vmware Host Health Report - ALERTS DETECTED';
 
if($EMAIL_HOST) {
	# user specified mail server; configure parameters for emailing output
	print "Using mail host: $EMAIL_HOST.\n";
	$SEND_MAIL = "yes";
}
 
## Datastore warning levels
 
my $DsWarnPC = ($dswarnpc / 100);
my $DsCriticalPC = ($dscriticalpc / 100);
 
# set colour for datastores listed as inactive - GREEN, YELLOW, or RED
my $DsInactiveColour = 'RED';
 
# determine reporting level
if ($concise) { $debug = 0; }
 
# CONNECT AND GET HEALTH STATUS...
 
&writelog(""); # Linefeed to aid log review
 
$alerts = &checkHosts(); # connects to hosts and obtains data
&endReportCreation(); # writes out report footers etc
 
Util::disconnect();
 
# If required, check if number of alerts has changed
if ($warnonchange) {
  # Don't send a mail if the number of alerts hasn't changed since last run...
  unless (&alertschange($alerts)) {
    # ... unless --warnonalerts is set (meaning to always generate a mail if alerts are present)
    if (($warnonalerts) && (!$alerts)) { $SEND_MAIL = "no"; }
    elsif (!$warnonalerts) { $SEND_MAIL = "no"; }
  }
}
 
# Send report by email if required, and if mail server was specified on command line
if (($SEND_MAIL eq "yes") && ($EMAIL_HOST)) {
	print "Sending email to $EMAIL_TO.\n";
        &sendMail($alerts);
}
 
print "Done.\n\n";
 
 
 
 
############################################################################
# MAIN SUB-ROUTINES; THESE DO THE WORK
############################################################################
 
 
sub checkHosts {
	my ($total_alerts) = 0;
	my ($host_alerts) = 0;
 
	if($hosttype eq 'VirtualCenter') {
		unless($hostfile) {
			Util::disconnect();
			print "Error: When connecting to vCenter, you must specify --hostfile and provide input file of the ESX(i) hosts you would like to check!\n\n";
			&writelog("Error: --hostfile not specified for vCentre connection.");
			exit 1;
		}
		&startReportCreation();
		&processFile($hostfile);
		foreach my $host_name( @host_list ) {
                	chomp($host_name);
                	$host_view = Vim::find_entity_view(view_type => 'HostSystem', filter => { 'name' => $host_name});
			&writelog("ESX Server $host_name checked ".&giveMeDate('DMY')." at ".&giveMeDate('HMS'));
			$host_alerts += &getHardwareHealthInfo($host_view);
			$total_alerts += $host_alerts;
			&writelog("  $host_name had $host_alerts alerts.");
			$host_alerts = 0;
		}
	} else {
		&startReportCreation();
		$host_view = Vim::find_entity_view(view_type => 'HostSystem');
		my $host_name = $host_view->name;
		&writelog("ESX Server $host_name checked ".&giveMeDate('DMY')." at ".&giveMeDate('HMS'));
		$total_alerts += &getHardwareHealthInfo($host_view);
		&writelog("  $host_name had $total_alerts alerts.");		
	}
 
return $total_alerts;
 
}
 
 
sub getHardwareHealthInfo {
	my ($host_view) = @_;
 
	my ($err_count) = 0;
 
	if($host_view) {
		my $host_name = $host_view->name;
		print REPORT_OUTPUT "<div id=\"wrapper\">\n";
 
		my $hardwareSystem = Vim::get_view(mo_ref => $host_view->configManager->healthStatusSystem);
		my ($cpu,$mem,$storage,@sensors,@datastores,@vmsnaps);
		if($hardwareSystem->runtime->hardwareStatusInfo) {	
			###########
			# CPU
			###########
			my $cpuStatus = $hardwareSystem->runtime->hardwareStatusInfo->cpuStatusInfo;
			foreach(@$cpuStatus) {
				if($_->status->key ne 'Green' || $debug eq 1) {
					if ($_->name !~ /$exclude/) {
						# only report if it doesn't match the exclude line
						$cpu .= &newBullet($_->name,&rep_color($_->status->key));
						if($_->status->key ne 'Green') { $err_count += 1; }
					}
				}
			}
 
			###########
			# MEMORY
			###########
			my $memStatus = $hardwareSystem->runtime->hardwareStatusInfo->memoryStatusInfo;
			foreach(@$memStatus) {
				if($_->status->key ne 'Green' || $debug eq 1) {
					if ($_->name !~ /$exclude/) {
						# only report if it doesn't match the exclude line
						$mem .= &newBullet($_->name,&rep_color($_->status->key));
						if($_->status->key ne 'Green') { $err_count += 1; }
					}
				}
			}
 
			###########
			# STORAGE 
			###########
			my $stoStatus = $hardwareSystem->runtime->hardwareStatusInfo->storageStatusInfo;
			foreach(@$stoStatus) {
				if($_->status->key ne 'Green' || $debug eq 1) {
					if ($_->name !~ /$exclude/) {
						# only report if it doesn't match the exclude line
						$storage .= &newBullet($_->name,&rep_color($_->status->key));
						if($_->status->key ne 'Green') { $err_count += 1; }
					}
                       		}
               		}
		}
 
		if($hardwareSystem->runtime->systemHealthInfo) {
			##########################
			# OTHER SYSTEM COMPONENTS
			##########################
			my $sensorInfo = $hardwareSystem->runtime->systemHealthInfo->numericSensorInfo;
			foreach(@$sensorInfo) {
				if($_->healthState && $_->healthState->label ne 'Green' || $debug eq 1) {
					if ($_->name !~ /$exclude/) {
						# only report if it doesn't match the exclude line
						my $reading = $_->currentReading * 10 ** $_->unitModifier; 
						my $units;
						if($_->rateUnits) {
							$units = $_->baseUnits . "/" . $_->rateUnits;
						} else { $units = $_->baseUnits; }
						my $sensor_string = $_->sensorType . "==" . &newBullet( ($_->name .": ". $reading ." ". $units), &rep_color($_->healthState->key) );
						push @sensors,$sensor_string;
						if($_->healthState->label ne 'Green') { $err_count += 1; }					
					}
				}
			}
		}
 
 
		#######################
		# CHECK CPU/RAM USAGE
		#######################
 
		my $memTotalSize = round( $host_view->summary->hardware->memorySize/1024/1024 );
		my $memCurrentUse = $host_view->summary->quickStats->overallMemoryUsage;
		my $cpuTotalSpeed = round( $host_view->hardware->cpuInfo->hz *
					$host_view->hardware->cpuInfo->numCpuCores / 1000000 );
		my $cpuCurrentLoad = $host_view->summary->quickStats->overallCpuUsage;
 
		my $memUse = &check_use($memCurrentUse,$memTotalSize,$memwarnpc);
		my $cpuUse = &check_use($cpuCurrentLoad,$cpuTotalSpeed,$cpuwarnpc);
 
		if ($cpuUse ne 'Green') { $err_count +=1; }; 
		if ($memUse ne 'Green') { $err_count +=1; };
 
 
		#######################
		# CHECK DATASTORE USAGE
		#######################
 
		my $DSs = Vim::get_views(mo_ref_array => $host_view->datastore);
		my $totalDSs = 0;
		my $Accessible = "";
		my $capacity = 0;
		my $free = 0;
		my ($dsstring, $dscolour, $dsavailable);
		foreach(@$DSs) {
			$totalDSs += 1;
			if($_->summary->accessible) { $Accessible = "Accessible"; }
			else { $Accessible = "Inaccessible"; }
 
			$capacity = (($_->summary->capacity)/1073741824);
			$free = (($_->summary->freeSpace)/1073741824);
			$dsavailable = 0;
 
			if ($_->summary->accessible) {
				$dsavailable = ($free/$capacity);
				if ($dsavailable < $DsCriticalPC) {
					$dscolour = 'RED';
				} elsif ($dsavailable < $DsWarnPC) {
					$dscolour = 'YELLOW';
				} else {
					$dscolour = 'GREEN';
				}
			} else {
				#inaccessible datastores will listed according to $DsInactiveColour;
				$dscolour = $DsInactiveColour;
			}
 
			if ($_->summary->name !~ /$exclude/) {
				if ($dscolour ne 'GREEN' || $debug eq 1) {
					# only report if it doesn't match the exclude line
				 	if ($dscolour ne 'GREEN') {
				 		$err_count += 1;
				 	}
					if ($Accessible eq 'Accessible') {
						$dsstring = &newBullet( ($_->summary->name ." : ".
								&commify(int($free))."GB free (".int(100*$dsavailable)."%) / ".
								&commify(int($capacity))."GB"),&rep_color($dscolour) );
					} else {
						$dsstring = &newBullet( ($_->summary->name ." (".$Accessible.")"),
								&rep_color($dscolour) );
					}
					push @datastores,$dsstring;
				}					
			}					
		}
 
		#######################
		# CHECK VMs FOR SNAPSHOTS, IF REQUESTED
		#######################
 
		if ($warnofsnapshots) {
			my $vms = Vim::get_views(mo_ref_array => $host_view->vm,
						 properties => ['name','runtime.powerState','snapshot']);
			foreach(@$vms) {
				if ( ($_->{'runtime.powerState'}->val eq "poweredOn") && $_->{'snapshot'} ) {
					push @vmsnaps, &newBullet( ($_->{'name'}),&rep_color('YELLOW') );
					$err_count += 1;
				}
			}
		}
 
		#######################
		# PRINT SUMMARY
		#######################
 
		my $build = $host_view->summary->config->product->fullName if($host_view->summary->config->product->fullName);
 
		# output title for hostname
		print "Processing $host_name ($build): $err_count alerts.\n";
		print REPORT_OUTPUT "<div style='border:none;border-top:solid windowtext 1.0pt;padding:1.0pt 0cm 0cm 0cm'>\n";
		print REPORT_OUTPUT "<h2 style='border:none;padding:0cm'>$host_name</h2>\n";
		print REPORT_OUTPUT "</div>\n";
		print REPORT_OUTPUT "<p class=MsoNormal>$build: ";
 
		#everything okay?
 
		if ($err_count) {
			my $plural = "";
			if ($err_count > 1) {
				$plural = "s";
			}
			print REPORT_OUTPUT "<span style=\"color:FireBrick\">Host has $err_count alert".$plural.":</span></b></p>\n";
             	} else {
			print REPORT_OUTPUT "<span style=\"color:DarkGreen\">Host is healthy.</span></b></p>\n";
		}
 
		#CPU and Memory info lines, coloured as required.  Concise exludes these, unless there is a warning.
 
		if ($cpuUse ne 'Green' || $memUse ne 'Green' || $debug eq 1) {
			print REPORT_OUTPUT "<br>\n";
			print REPORT_OUTPUT &htmlHeading("CURRENT USAGE");
			if (($cpuUse ne 'Green') || ($debug eq 1)) {
				print REPORT_OUTPUT &newBullet("CPU: "
							.round($cpuCurrentLoad/$cpuTotalSpeed*100)
							."%",&rep_color($cpuUse));
			}
			if (($memUse ne 'Green') || ($debug eq 1)) {
				print REPORT_OUTPUT &newBullet("RAM: "
							.round($memCurrentUse/$memTotalSize*100)
							."%",&rep_color($memUse));
			}
		}
 
		#check categories for problems
		my ($warnings, $criticals, $title);
 
		if($cpu) {
			$warnings = &checkItems($cpu, "DarkGoldenRod");
			$criticals = &checkItems($cpu, "FireBrick");
			$title = &prepareTitle( "CPU COMPONENTS", $warnings, $criticals );
 
			print REPORT_OUTPUT "<br>\n";
			print REPORT_OUTPUT &htmlHeading($title);
			print REPORT_OUTPUT $cpu;
		}
		if($mem) {
			$warnings = &checkItems($mem, "DarkGoldenRod");
			$criticals = &checkItems($mem, "FireBrick");
			$title = &prepareTitle( "MEMORY COMPONENTS", $warnings, $criticals );		
			print REPORT_OUTPUT "<br>\n";
			print REPORT_OUTPUT &htmlHeading($title);
			print REPORT_OUTPUT $mem; 
		}
		if($storage) {
			$warnings = &checkItems($storage, "DarkGoldenRod");
			$criticals = &checkItems($storage, "FireBrick");
			$title = &prepareTitle( "STORAGE COMPONENTS", $warnings, $criticals );
			print REPORT_OUTPUT "<br>\n";
			print REPORT_OUTPUT &htmlHeading($title);
			print REPORT_OUTPUT $storage; 
		}
		if(@datastores) {
			$warnings = 0;
			$criticals = 0;
			foreach(@datastores) {
				$warnings += &checkItems($_, "DarkGoldenRod");
				$criticals += &checkItems($_, "FireBrick");
			}
			$title = &prepareTitle( "DATASTORES", $warnings, $criticals );
			print REPORT_OUTPUT "<br>\n";
			print REPORT_OUTPUT &htmlHeading($title);
			foreach(@datastores) {
				print REPORT_OUTPUT $_;
			}
		}
		if(@vmsnaps) {
			$warnings = 0;
			$criticals = 0;
			foreach(@vmsnaps) {
				$warnings += &checkItems($_, "DarkGoldenRod");
				$criticals += &checkItems($_, "FireBrick");
			}
			$title = &prepareTitle( "RUNNING VMs WITH SNAPSHOTS", $warnings, $criticals );
			print REPORT_OUTPUT "<br>\n";
			print REPORT_OUTPUT &htmlHeading($title);
			foreach(@vmsnaps) {
				print REPORT_OUTPUT $_;
			}
		}
 
		if(@sensors) {
			my %seen;
			foreach(@sensors) {
				my ($component,$sensor) = split('==',$_);
				$warnings = &checkItems($sensor, "DarkGoldenRod");
				$criticals = &checkItems($sensor, "FireBrick");
				if(!$seen{$component}) {
					$seen{$component} = "yes";
					my $type = uc $component;
					$title = &prepareTitle( "$type COMPONENTS", $warnings, $criticals );
					print REPORT_OUTPUT "<br>\n";
					print REPORT_OUTPUT &htmlHeading($title);
				}
				if($seen{$component}) { 
					print REPORT_OUTPUT $sensor;
				}
			}
			print REPORT_OUTPUT "<br>\n";
			print REPORT_OUTPUT "</span></p>\n";
 
		}
		print REPORT_OUTPUT "</div>\n"	
	}
 
return $err_count;
 
}
 
 
 
 
########################
# HELPER FUNCTIONS
########################
 
 
sub checkItems {
	my ($list, $search) = @_;
	my $items = 0;
 
	while ($list =~ /$search/g) { $items++ }
 
	return ($items / 2);
}
 
 
sub prepareTitle {
	my ($title, $warnings, $criticals) = @_;
	my $returnStr = $title;
 
	if ($warnings) { $returnStr = $returnStr . " - ". $warnings . " warning "; }
	if ($warnings && $criticals) { $returnStr = $returnStr . " and "; }
	if (!$warnings) { $returnStr = $returnStr . " - ";}
	if ($criticals) { $returnStr = $returnStr . $criticals . " critical "; }
 
	if ($warnings || $criticals) {	
		$returnStr = $returnStr . "item";
		if ($warnings + $criticals > 1) {
			$returnStr = $returnStr . "s";
		}
		$returnStr = $returnStr . ":";
	}
	else { $returnStr = $returnStr . "Healthy"; }
 
	return $returnStr;
}
 
 
 
sub alertschange {
	my ($newalerts) = @_;
	my $oldalerts;
	my $returnval = 0;
 
	# first open the file for append - this is to ensure it exists
	open( HANDLE, ">> ".$STATUS_FILE);
	close( HANDLE );
 
	# now open the file for read, and read the line in
	open( HANDLE, "< ".$STATUS_FILE);
	$oldalerts=<HANDLE>;
	close( HANDLE );
 
	unless ($oldalerts) { $oldalerts = 0; }
	chomp($oldalerts);
 
	# compare the value
	if ($oldalerts!=$newalerts) { $returnval = 1; }
 
	# then replace the value in the file
	open( HANDLE, "> ".$STATUS_FILE);
	print HANDLE $newalerts;
	close( HANDLE );
 
	# and return the result
	return $returnval;
} # end sub alertchange
 
 
 
sub rep_color {
	my $inputStr = uc($_[0]);
	my $outputStr = 'FireBrick';
 
	if (lc($inputStr) eq 'green') {$outputStr = 'DarkGreen'}
	elsif (lc($inputStr) eq 'yellow') {$outputStr = 'DarkGoldenRod'}
 
	return $outputStr;
}
 
 
 
sub check_use {
	my $use = $_[0];
	my $capacity = $_[1];
	my $threshold = $_[2];
 
	if ($use*100/$capacity > $threshold) {return 'Yellow'}
	else {return 'Green'}
 
}
 
 
 
sub round {
    my($number) = shift;
    return int($number + .5);
}
 
 
 
sub sendMail {
        my $alerts = $_[0];
        my $smtp = Net::SMTP->new($EMAIL_HOST ,Hello => $EMAIL_DOMAIN, Timeout => 30,);
 
        unless($smtp) {
		&writelog("ERROR: Unable to connect to email server $EMAIL_HOST.");
                die "Error: Unable to setup connection with email server: \"" . $EMAIL_HOST . "\"!\n";
        }
 
        $smtp->mail($EMAIL_FROM);
 
	my $primaryemail = '';
        my @maillist = split(';', $EMAIL_TO);
 
        foreach (@maillist) {        
        	$smtp->to($_);
        	unless ($primaryemail) {
        		$primaryemail = $_;
        	}
	}
 
        $smtp->data();
        $smtp->datasend('From: '.$EMAIL_FROM."\n");
        $smtp->datasend('To: '.$primaryemail."\n");
        if ($alerts) {
        	$smtp->datasend('Subject: '.$EMAIL_SUBJECT_ALERTS."\n");
        } else {
        	$smtp->datasend('Subject: '.$EMAIL_SUBJECT_NORMAL."\n");      
        }
   	$smtp->datasend("MIME-Version: 1.0\n");
   	$smtp->datasend("Content-Type: text/html; charset=us-ascii\n");
   	$smtp->datasend("\n");
 
        open (HANDLE, $reportname) or
		&writelog("ERROR: Email not sent - unable to open report file $reportname."),
		die("ERROR: Can not locate report file \"$reportname\"!\n");
 
        my @lines = <HANDLE>;
        close(HANDLE);
        foreach my $line (@lines) {
                $smtp->datasend($line);
        }
 
	eval {
	        $smtp->dataend();
        	$smtp->quit;
	};
	if($@) {
		&writelog("ERROR: Unable to send email via $EMAIL_HOST.");
		die "Error: Unable to send report \"$reportname\"!\n";
	} else {
		&writelog("Email sent ".&giveMeDate('DMY')." at ".&giveMeDate('HMS')." to $primaryemail.");
	        #`del $reportname`;
	}
}
 
 
 
# Subroutine to process the input file
sub processFile {
        my ($vmlist) =  @_;
        my $HANDLE;
        open (HANDLE, $vmlist) or
		&writelog("ERROR: Cannot locate $vmlist input file."),
		die("ERROR: Cannot locate \"$vmlist\" input file!\n");
 
        my @lines = <HANDLE>;
        my @errorArray;
        my $line_no = 0;
 
        close(HANDLE);
        foreach my $line (@lines) {
                $line_no++;
                &TrimSpaces($line);
 
                if($line) {
                        if($line =~ /^\s*:|:\s*$/){
                                print "Error in Parsing File at line: $line_no\n";
                                print "Continuing to the next line\n";
				&writelog("WARNING: Ignored lines in host list.");
                                next;
                        }
                        my $host = $line;
                        &TrimSpaces($host);
                        push @host_list,$host;
                }
        }
}
 
 
 
sub TrimSpaces {
        foreach (@_) {
                s/^\s+|\s*$//g
        }
}
 
 
 
sub startReportCreation {
	print "Generating $report_name \"$reportname\" .\n";
	open(REPORT_OUTPUT, ">$reportname");
 
	my $date = giveMeDate('DMY');
	my $time = giveMeDate('HMS');
	my $html_start = <<HTML_START;
<html>
 
<head>
 
<style>
<!--
 /* Style Definitions */
 p.MsoNormal, li.MsoNormal, div.MsoNormal
	{margin-top:0cm;
	margin-right:0cm;
	margin-bottom:10.0pt;
	margin-left:0cm;
	line-height:115%;
	font-size:10.0pt;
	font-family:"Calibri","sans-serif";}
h1
	{mso-style-link:"Heading 1 Char";
	margin-top:24.0pt;
	margin-right:0cm;
	margin-bottom:0cm;
	margin-left:0cm;
	margin-bottom:.0001pt;
	line-height:115%;
	page-break-after:avoid;
	font-size:14.0pt;
	font-family:"Cambria","serif";
	color:#365F91;
	font-weight:bold;}
h2
	{mso-style-link:"Heading 2 Char";
	margin-top:10.0pt;
	margin-right:0cm;
	margin-bottom:0cm;
	margin-left:0cm;
	margin-bottom:.0001pt;
	line-height:115%;
	page-break-after:avoid;
	font-size:13.0pt;
	font-family:"Cambria","serif";
	color:#4F81BD;
	font-weight:bold;}
h3
	{mso-style-link:"Heading 3 Char";
	margin-top:10.0pt;
	margin-right:0cm;
	margin-bottom:0cm;
	margin-left:0cm;
	margin-bottom:.0001pt;
	line-height:115%;
	page-break-after:avoid;
	font-size:11.0pt;
	font-family:"Cambria","serif";
	color:#4F81BD;
	font-weight:bold;}
h4
	{mso-style-link:"Heading 4 Char";
	margin-top:10.0pt;
	margin-right:0cm;
	margin-bottom:0cm;
	margin-left:0cm;
	margin-bottom:.0001pt;
	line-height:115%;
	page-break-after:avoid;
	font-size:11.0pt;
	font-family:"Cambria","serif";
	color:#4F81BD;
	font-weight:bold;
	font-style:italic;}
p.MsoTitle, li.MsoTitle, div.MsoTitle
	{mso-style-link:"Title Char";
	margin-top:0cm;
	margin-right:0cm;
	margin-bottom:15.0pt;
	margin-left:0cm;
	border:none;
	padding:0cm;
	font-size:26.0pt;
	font-family:"Cambria","serif";
	color:#17365D;
	letter-spacing:.25pt;}
p.MsoTitleCxSpFirst, li.MsoTitleCxSpFirst, div.MsoTitleCxSpFirst
	{mso-style-link:"Title Char";
	margin:0cm;
	margin-bottom:.0001pt;
	border:none;
	padding:0cm;
	font-size:26.0pt;
	font-family:"Cambria","serif";
	color:#17365D;
	letter-spacing:.25pt;}
p.MsoTitleCxSpMiddle, li.MsoTitleCxSpMiddle, div.MsoTitleCxSpMiddle
	{mso-style-link:"Title Char";
	margin:0cm;
	margin-bottom:.0001pt;
	border:none;
	padding:0cm;
	font-size:26.0pt;
	font-family:"Cambria","serif";
	color:#17365D;
	letter-spacing:.25pt;}
p.MsoTitleCxSpLast, li.MsoTitleCxSpLast, div.MsoTitleCxSpLast
	{mso-style-link:"Title Char";
	margin-top:0cm;
	margin-right:0cm;
	margin-bottom:15.0pt;
	margin-left:0cm;
	border:none;
	padding:0cm;
	font-size:26.0pt;
	font-family:"Cambria","serif";
	color:#17365D;
	letter-spacing:.25pt;}
p.MsoSubtitle, li.MsoSubtitle, div.MsoSubtitle
	{mso-style-link:"Subtitle Char";
	margin-top:0cm;
	margin-right:0cm;
	margin-bottom:10.0pt;
	margin-left:0cm;
	line-height:115%;
	font-size:12.0pt;
	font-family:"Cambria","serif";
	color:#4F81BD;
	letter-spacing:.75pt;
	font-style:italic;}
p
	{margin-right:0cm;
	margin-left:0cm;
	font-size:12.0pt;
	font-family:"Times New Roman","serif";}
p.MsoNoSpacing, li.MsoNoSpacing, div.MsoNoSpacing
	{margin:0cm;
	margin-bottom:.0001pt;
	font-size:11.0pt;
	font-family:"Calibri","sans-serif";}
p.MsoListParagraph, li.MsoListParagraph, div.MsoListParagraph
	{margin-top:0cm;
	margin-right:0cm;
	margin-bottom:10.0pt;
	margin-left:36.0pt;
	line-height:115%;
	font-size:11.0pt;
	font-family:"Calibri","sans-serif";}
p.MsoListParagraphCxSpFirst, li.MsoListParagraphCxSpFirst, div.MsoListParagraphCxSpFirst
	{margin-top:0cm;
	margin-right:0cm;
	margin-bottom:0cm;
	margin-left:36.0pt;
	margin-bottom:.0001pt;
	line-height:115%;
	font-size:11.0pt;
	font-family:"Calibri","sans-serif";}
p.MsoListParagraphCxSpMiddle, li.MsoListParagraphCxSpMiddle, div.MsoListParagraphCxSpMiddle
	{margin-top:0cm;
	margin-right:0cm;
	margin-bottom:0cm;
	margin-left:36.0pt;
	margin-bottom:.0001pt;
	line-height:115%;
	font-size:11.0pt;
	font-family:"Calibri","sans-serif";}
p.MsoListParagraphCxSpLast, li.MsoListParagraphCxSpLast, div.MsoListParagraphCxSpLast
	{margin-top:0cm;
	margin-right:0cm;
	margin-bottom:10.0pt;
	margin-left:36.0pt;
	line-height:115%;
	font-size:11.0pt;
	font-family:"Calibri","sans-serif";}
span.MsoSubtleEmphasis
	{color:gray;
	font-style:italic;}
span.MsoIntenseEmphasis
	{color:#4F81BD;
	font-weight:bold;
	font-style:italic;}
span.Heading1Char
	{mso-style-name:"Heading 1 Char";
	mso-style-link:"Heading 1";
	font-family:"Cambria","serif";
	color:#365F91;
	font-weight:bold;}
span.Heading2Char
	{mso-style-name:"Heading 2 Char";
	mso-style-link:"Heading 2";
	font-family:"Cambria","serif";
	color:#4F81BD;
	font-weight:bold;}
span.Heading3Char
	{mso-style-name:"Heading 3 Char";
	mso-style-link:"Heading 3";
	font-family:"Cambria","serif";
	color:#4F81BD;
	font-weight:bold;}
span.Heading4Char
	{mso-style-name:"Heading 4 Char";
	mso-style-link:"Heading 4";
	font-family:"Cambria","serif";
	color:#4F81BD;
	font-weight:bold;
	font-style:italic;}
span.TitleChar
	{mso-style-name:"Title Char";
	mso-style-link:Title;
	font-family:"Cambria","serif";
	color:#17365D;
	letter-spacing:.25pt;}
span.SubtitleChar
	{mso-style-name:"Subtitle Char";
	mso-style-link:Subtitle;
	font-family:"Cambria","serif";
	color:#4F81BD;
	letter-spacing:.75pt;
	font-style:italic;}
.MsoChpDefault
	{font-size:10.0pt;}
div.Section1
	{page:Section1;}
 /* List Definitions */
 ol
	{margin-bottom:0cm;}
ul
	{margin-bottom:0cm;}
-->
</style>
 
</head>
 
<body lang=EN-GB>
 
<div class=Section1>
 
<h1>vm<span style='font-weight:normal'>ware Host Hardware Health Report</span> </h1>
 
<p class=MsoNormal>Metrics gathered $date at $time</p>
 
<div style='border:none;border-top:solid windowtext 1.0pt;padding:1.0pt 0cm 0cm 0cm'>
 
HTML_START
 
	print REPORT_OUTPUT $html_start;
}
 
 
 
sub endReportCreation {
	my $html_end = <<HTML_END;
<p class=MsoNormal>&nbsp;</p>
 
<p class=MsoNormal>End of Report.</p>
 
</div>
 
</body>
 
</html>
 
HTML_END
	print REPORT_OUTPUT $html_end;
	close(REPORT_OUTPUT);
}
 
 
 
sub newBullet {
# Returns the text as an HTML formatted bullet of the specified colour
        my ($sensor,$sensorColor) = @_;
	my $bulletCode;
 
	$bulletCode =  "<p class=MsoListParagraphCxSpMiddle style='margin-left:72.0pt;text-indent:-18.0pt;\n";
	$bulletCode .= "line-height:normal'><span style='font-size:9.0pt;font-family:\"Courier New\";\n";
	$bulletCode .= "color:$sensorColor'>o<span style='font:7.0pt \"Times New Roman\"'>&nbsp;&nbsp;&nbsp;\n";
	$bulletCode .= "</span></span><span style='font-size:9.0pt;color:$sensorColor'>\n";
	$bulletCode .= "$sensor</span></p>\n";
 
	return $bulletCode;
}
 
 
 
sub htmlHeading {
# Returns the text as an HTML formatted heading
	my $headingCode;
 
	$headingCode =  "<p class=MsoListParagraphCxSpFirst style='text-indent:-18.0pt;line-height:normal'><span\n";
	$headingCode .= "style='font-size:9.0pt;font-family:Symbol'>·<span style='font:7.0pt \"Times New Roman\"'>";
	$headingCode .= "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\n";
	$headingCode .= "</span></span><b><span style='font-size:9.0pt'>@_</span></b></p>\n";
 
	return $headingCode;
}
 
 
 
sub writelog {
# Appends specified text to the log file
	open (LOGFILE, ">>$LOG_FILE");
	print LOGFILE "@_\n";
	close (LOGFILE); 
}
 
 
 
sub giveMeDate {
        my ($date_format) = @_;
        my %dttime = ();
	my $my_time;
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
 
        ### begin_: initialize DateTime number formats
        $dttime{year }  = sprintf "%04d",($year + 1900);  ## four digits to specify the year
        $dttime{mon  }  = sprintf "%02d",($mon + 1);      ## zeropad months
        $dttime{mday }  = sprintf "%02d",$mday;           ## zeropad day of the month
        $dttime{wday }  = sprintf "%02d",$wday + 1;       ## zeropad day of week; sunday = 1;
        $dttime{yday }  = sprintf "%02d",$yday;           ## zeropad nth day of the year
        $dttime{hour }  = sprintf "%02d",$hour;           ## zeropad hour
        $dttime{min  }  = sprintf "%02d",$min;            ## zeropad minutes
        $dttime{sec  }  = sprintf "%02d",$sec;            ## zeropad seconds
        $dttime{isdst}  = $isdst;
 
        if($date_format eq 'MDYHMS') {
                $my_time = "$dttime{mon}-$dttime{mday}-$dttime{year} $dttime{hour}:$dttime{min}:$dttime{sec}";
        }
        elsif ($date_format eq 'YMD') {
                $my_time = "$dttime{year}-$dttime{mon}-$dttime{mday}";
        }
        elsif ($date_format eq 'DMY') {
                $my_time = "$dttime{mday}-$dttime{mon}-$dttime{year}";
        }
        elsif ($date_format eq 'HMS') {
                $my_time = "$dttime{hour}:$dttime{min}:$dttime{sec}";
        }
        return $my_time;
}
 
 
 
sub validateConnection {
        my ($host_version,$host_license,$host_type) = @_;
        my $service_content = Vim::get_service_content();
        my $licMgr = Vim::get_view(mo_ref => $service_content->licenseManager);
 
        ########################
        # CHECK HOST VERSION
        ########################
        if(!$service_content->about->version ge $host_version) {
                Util::disconnect();
                print "This script requires your ESX(i) host to be greater than $host_version\n\n";
                exit 1;
        }
 
        ########################
        # CHECK HOST LICENSE
        ########################
        my $licenses = $licMgr->licenses;
        foreach(@$licenses) {
                if($_->editionKey eq 'esxBasic' && $host_license eq 'licensed') {
                        Util::disconnect();
                        print "This script requires your ESX(i) be licensed, the free version will not allow you to perform any write operations!\n\n";
                        exit 1;
                }
        }
 
        ########################
        # CHECK HOST TYPE
        ########################
        if($service_content->about->apiType ne $host_type && $host_type ne 'both') {
                Util::disconnect();
                print "This script needs to be executed against $host_type\n\n";
                exit 1
        }
 
        return $service_content->about->apiType;
}
 
 
sub commify {
    local($_) = shift;
    1 while s/^(-?\d+)(\d{3})/$1,$2/;
    return $_;
} 
 
####################
## END OF SCRIPT
####################