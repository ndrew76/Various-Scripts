#!/usr/bin/perl -w

# check_hp_icf_sensors Nagios Plugin
# Checks the sensors on a HP-ICF-CHASSIS compliant device
# Type check_hp_icf_sensors --help for getting more info and examples.
#
# This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY.
# It may be used, redistributed and/or modified under the terms of the GNU 
# General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).
#
# TComm - Oscar Navalon Claramunt
# Submit bugs to oscar.navalon@tcomm.es
# Get last version in www.tcomm.es


# MODULE DECLARATION

use strict;

use Nagios::Plugin;
use Net::SNMP qw(SNMP_VERSION_2C);


# FUNCTION DECLARATION

sub CreateNagiosManager ();
sub CheckArguments ();
sub TestHost ();
sub PerformCheck ();


# CONSTANT DEFINITION

use constant MODE_TEST => 1;
use constant MODE_CHECK => 2;
use constant NAME => 	'check_hp_icf_sensors';
use constant VERSION => '0.1b';
use constant USAGE => 	"Usage:\n".
								"check_hp_icf_sensors -H <hostname>\n" .
								"\t\t[-C <SNMP Community>] [-e <SNMP Version>] [-P <SNMP port>] [-t <SNMP timeout>]\n" .
								"\t\t[-w <sensor status id threshold list> -c <sensor status id threshold list>]\n" .
								"\t\t[-i <sensor ids list>]\n".
								"\t\t[-T]\n".
								"\t\t[-V <version>]\n";
use constant BLURB => 	"This plugin checks the sensors on a HP-ICF-CHASSIS compliant device.";
use constant LICENSE => "This nagios plugin is free software, and comes with ABSOLUTELY NO WARRANTY\n".
								"It may be used, redistributed and/or modified under the terms of the GNU\n".
								"General Public Licence (see http://www.fsf.org/licensing/licenses/gpl.txt).\n";
use constant EXAMPLE => "\n\n".
								"Examples:\n".
								"\n".
								"check_hp_icf_sensors -H 192.168.0.4 -T\n".
								"\n".
								"Test Mode that checks the compatibility of the plugin on a host with address 192.168.0.4\n".
								"using SNMP protocol version 1 and 'public' as community\n".
								"Plugin returns OK if it is a HP-ICF-CHASSIS compliant device, and a list of all sensors\n".
								"with their id and description is returned. If it is not compatible returns UNKNOWN\n".
								"\n".
								"check_hp_icf_sensors -H 192.168.0.4\n".
								"\n".
								"Checks all present sensors avaliable on a host with address 192.168.0.4\n".
								"using SNMP protocol version 1 and 'public' as community\n".
								"Plugin returns CRITICAL if any sensor has a status value equal to Bad\n".
								", WARNING if any sensor has a status value equal to Unknown or Warning.\n".								
								"In other case it returns OK if check has been performed or UNKNOWN.\n".
								"\n".
								"check_hp_icf_sensors -H 192.168.0.4 -w Warning -c Bad\n".
								"\n".
								"Checks all present sensors avaliable on a host with address 192.168.0.4\n".
								"using SNMP protocol version 1 and 'public' as community\n".
								"Plugin returns CRITICAL if any sensor has a status value equal to Bad\n".
								", WARNING if any sensor has a status value equal to Warning.\n".
								"In other case it returns OK if check has been performed or UNKNOWN.\n".
								"\n".
								"check_hp_icf_sensors -H 192.168.0.4 -i 1,3 -w Warning -c Bad\n".
								"\n".
								"Checks sensors with id equal to 1 and 3 on a host with address 192.168.0.4\n".
								"using SNMP protocol version 1 and 'public' as community\n".
								"Plugin returns CRITICAL if any sensor to check (1 or 3) has a status value equal to Bad\n".
								", WARNING if any sensor to check (1 or 3) has a status value equal to Warning\n".
								"and UNKNOWN if any sensor to check (1 or 3) has a status value equal to NotPresent\n".
								"In other case it returns OK if check has been performed or UNKNOWN.\n".								
								"\n";


# VARIABLE DEFINITION

my $Nagios;
my $Error;
my $PluginMode;
my $PluginReturnValue, my $PluginOutput;


# MAIN FUNCTION

# Get command line arguments
$Nagios = &CreateNagiosManager(USAGE, VERSION, BLURB, LICENSE, NAME, EXAMPLE);
eval {$Nagios->getopts};

if (!$@) {
	# Command line parsed
	if (&CheckArguments($Nagios, $Error, $PluginMode)) {
		# Argument checking passed
		if ($PluginMode == MODE_TEST) {
			$PluginReturnValue = &TestHost($Nagios, $PluginOutput);
			$PluginOutput = "TEST MODE\n\n" . $PluginOutput;
		}
		else {
			$PluginReturnValue = &PerformCheck($Nagios, $PluginOutput)
		}
		
	}
	else {
		# Error checking arguments
		$PluginOutput = $Error;
		$PluginReturnValue = UNKNOWN;
	}
	$Nagios->nagios_exit($PluginReturnValue,$PluginOutput);
}
else {
	# Error parsing command line
	$Nagios->nagios_exit(UNKNOWN,$@);
}

		
	
# FUNCTION DEFINITIONS

# Creates and configures a Nagios plugin object
# Input: strings (usage, version, blurb, license, name and example) to configure argument parsing functionality
# Return value: reference to a Nagios plugin object

sub CreateNagiosManager() {
	# Create GetOpt object
	my $Nagios = Nagios::Plugin->new(usage => $_[0], version =>  $_[1], blurb =>  $_[2], license =>  $_[3], plugin =>  $_[4], extra =>  $_[5]);
	
	# Add argument hostname
	$Nagios->add_arg(spec => 'hostname|H=s',
				help => 'SNMP agent hostname or IP address',
				required => 1);				
					
	# Add argument community
	$Nagios->add_arg(spec => 'community|C=s',
				help => 'SNMP agent community (default: public)',
				default => 'public',
				required => 0);				
	# Add argument version
	$Nagios->add_arg(spec => 'snmpver|E=s',
				help => 'SNMP protocol version (default: 1)',
				default => '1',
				required => 0);				
	# Add argument port
	$Nagios->add_arg(spec => 'port|P=i',
				help => 'SNMP agent port (default: 161)',
				default => 161,
				required => 0);
	#Add argument test mode
	$Nagios->add_arg(spec => 'test|T',
				help => 'Test Mode',
				required => 0);
				
	#Add argument index sensors 
	$Nagios->add_arg(spec => 'ids|i=s',
				help => 'Comma separated sensor id list',
				required => 0);	
	# Add argument warning
	$Nagios->add_arg(spec => 'warning|w=s',
				help => "Comma separated sensor status names threshold list. ".	
						"Valid status names are: Unknown, Bad, Warning, Good",
				required => 0);
	# Add argument critical
	$Nagios->add_arg(spec => 'critical|c=s',
				help => "Comma separated sensor status names threshold list. ".	
						"Valid status names are: Unknown, Bad, Warning, Good",
				required => 0);
								
	# Return value
	return $Nagios;
}


# Checks argument values and sets some default values
# Input: Nagios Plugin object
# Output: Error description string, Plugin mode
# Return value: True if arguments ok, false if not

sub CheckArguments() {
	my $Nagios = $_[0];
	
	# Check if agent port number is > 0
	if ( $Nagios->opts->port <= 0 ) {
		$_[1] = "Invalid SNMP agent port: must be greater than zero";
		return 0;
	}
	if (defined($Nagios->opts->test)){
		$_[2] = MODE_TEST;
		return 1;
	}
	if (defined ($Nagios->opts->ids)){
		if ( $Nagios->opts->ids !~ /^((\d+,)*\d+)$/) {
			$_[1] = "Invalid sensor ids list: must be a comma separated id list";
			return 0;
		}	
	}
	

	if ( (defined($Nagios->opts->warning)) && (defined($Nagios->opts->critical))) {
		my %Status = ("Unknown", 1 , "Bad", 2 , "Warning" , 3 ,  "Good" , 4 );

		# Check warning value list
		if ( $Nagios->opts->warning !~ /^(\w+,)*\w+$/) {
			$_[1] = "Invalid warning threshold list: must be a comma separated sensor status names";
			return 0;
		}
		else{
			my @statusList=split(/,/, $Nagios->opts->warning);
			for (my $i=0;$i<=$#statusList;$i++){
				if (!exists $Status{$statusList[$i]}){
					my $ErrorOutput = "Valid names are = ";
					foreach (keys %Status){
						$ErrorOutput .= $_.", ";
					}
					substr($ErrorOutput,-2)='';#erases last comma and blank
					$_[1]= "Invalid sensor status name: $ErrorOutput";
					return 0;
				}
			}
		}

		# Check critical value list
		if ( $Nagios->opts->critical !~/^(\w+,)*\w+$/) {
			$_[1] = "Invalid critical threshold list: must be a comma separated sensor status names";
			return 0;
		}
		else{
			my @statusList=split(/,/, $Nagios->opts->critical);
			for (my $i=0;$i<=$#statusList;$i++){
				if (!exists $Status{$statusList[$i]}){
					my $ErrorOutput = "Valid names are = ";
					foreach (keys %Status){
						$ErrorOutput .= $_.", ";
					}
					substr($ErrorOutput,-2)='';#erases last comma and blank
					$_[1]= "Invalid sensor status name: $ErrorOutput";
					return 0;
				}
			}
		}

	}
	elsif ( (defined($Nagios->opts->warning)) || (defined($Nagios->opts->critical))) {
			$_[1] = "No valid combination. Warning and critical thresold must be defined both, or neither.";
			return 0;
		}
	$_[2] = MODE_CHECK;
	return 1;
}

# Checks if host supports HP-ICF-CHASSIS MIB related info.
# If true, it returns info about sensors id and description.
# Input: Nagios Plugin object
# Output: Test output string
# Return value: OK if test passed, UNKNOWN if not.

sub TestHost() {
	my $SNMPSession;
	my $SNMPError;
	my $OID_hpicfSensorEntry= "1.3.6.1.4.1.11.2.14.11.1.2.6.1";
	my $OID_hpicfSensorIndex= $OID_hpicfSensorEntry.".1";
	my $OID_hpicfSensorDescr= $OID_hpicfSensorEntry.".7";
	my $Output="";
	my $PluginReturnValue;
	
	($SNMPSession, $SNMPError) = Net::SNMP->session(-hostname => $Nagios->opts->hostname, -community => $Nagios->opts->community, -version => $Nagios->opts->snmpver, -port => $Nagios->opts->port, -timeout => $Nagios->opts->timeout);
	
	if (defined($SNMPSession)) {
		my $RequestResultIndex = $SNMPSession->get_entries(-columns => [$OID_hpicfSensorIndex]);
		my $RequestResultDesc = $SNMPSession->get_entries(-columns => [$OID_hpicfSensorDescr]);
		
		if ((defined $RequestResultDesc)&&(defined $RequestResultIndex)) {
			my $description;
			my $status;
			my $id;
			my $Oid;
			$Output = "HP ICF SENSORS DATA\n";
			foreach  $Oid (keys %{$RequestResultIndex}){
				$id = $RequestResultIndex->{$Oid};
				$description = $RequestResultDesc->{$OID_hpicfSensorDescr.".$id"};
				$Output.= "Sensor Id = $id \t\t\t  Sensor Description = \"$description\"\n";
			}
			$PluginReturnValue = OK;
		}
		else {
			$PluginReturnValue = UNKNOWN;
		}
		$SNMPSession->close();
	}
	else {
		$PluginReturnValue = UNKNOWN;
	}
	$_[1]=$Output;
	
	return $PluginReturnValue;
}



# Performs whole check: 
# Input: Nagios Plugin object
# Output: Plugin output string
# Return value: Plugin return value

sub PerformCheck() {
	my $OID_hpicfSensorEntry= "1.3.6.1.4.1.11.2.14.11.1.2.6.1";
	my $OID_hpicfSensorDescr= $OID_hpicfSensorEntry.".7";
	my $OID_hpicfSensorStatus= $OID_hpicfSensorEntry.".4";
	
	my @SensorStates;
	$SensorStates[1]="unknown";
	$SensorStates[2]="bad";
	$SensorStates[3]="warning";
	$SensorStates[4]="good";
	$SensorStates[5]="not present";
	
	my %SensorStatus = ("Unknown", 1 , "Bad", 2 , "Warning" , 3 ,  "Good" , 4 );
	
	my $Nagios = $_[0];
	
	my $SNMPSession;
	my $SNMPError;
	my @RequestData;
	my $RequestResultDesc;
	my $RequestResultStatus;
	my $CriticalOutput="";
	my $WarningOutput="";
	my @WarningStatus; 
	my @CriticalStatus; 
	
	# Start new SNMP session
	($SNMPSession, $SNMPError) = Net::SNMP->session(-hostname => $Nagios->opts->hostname, -community => $Nagios->opts->community, -version => $Nagios->opts->snmpver, -port => $Nagios->opts->port, -timeout => $Nagios->opts->timeout);
	
	if (defined($SNMPSession)) {

		$RequestResultDesc = $SNMPSession->get_entries(-columns => [$OID_hpicfSensorDescr]);
		$RequestResultStatus = $SNMPSession->get_entries(-columns => [$OID_hpicfSensorStatus]);
		if ((defined $RequestResultDesc)&&(defined $RequestResultStatus)) {
			
			my $description;
			my $status;
			my $id;
			my $Oid;
			my @match;
			
			#Default warning and critical status if they are not defined
			
			if (defined($Nagios->opts->warning)){
				@WarningStatus=split(/,/, $Nagios->opts->warning);
				for (my $i=0;$i<=$#WarningStatus;$i++){
					$WarningStatus[$i]=$SensorStatus{$WarningStatus[$i]};
				}	
			}
			else{
				@WarningStatus=("1","3");  #By default Unknown or Warning 
			}
			if (defined($Nagios->opts->critical)){
				@CriticalStatus=split(/,/, $Nagios->opts->critical);
				for (my $i=0;$i<=$#CriticalStatus;$i++){
					$CriticalStatus[$i]=$SensorStatus{$CriticalStatus[$i]};
				}	
			}
			else{
				@CriticalStatus=("2"); #By default Bad
			}
			#~ @WarningStatus=  (defined($Nagios->opts->warning)) ? split(/,/, $Nagios->opts->warning) : ("1","3");
			#~ @CriticalStatus= (defined($Nagios->opts->critical)) ? split(/,/, $Nagios->opts->critical) : ("2");
			
			#Recovering data of all sensors
			if (!defined $Nagios->opts->ids){
				foreach  $Oid (keys %{$RequestResultDesc}){
					if ($Oid =~ /$OID_hpicfSensorDescr.(\d+)/){
						$id=$1;
						$description = $RequestResultDesc->{$Oid};
						$status = $RequestResultStatus ->{$OID_hpicfSensorStatus.".$id"};
						if( (!defined($description)) || (!defined($status) ) ){
							$SNMPSession->close();
							$_[1] = "Error recovering description and/or status of the sensor with id $id.";
							return UNKNOWN;
						}
						elsif ($status == 5){ #No present					
							next;
						}
					}
					@match =  grep (/$status/,@CriticalStatus);
					if ($#match >= 0){ 
						$CriticalOutput .= "$description has a critical state ($SensorStates[$status]); ";
					}
					else{
						@match =  grep (/$status/,@WarningStatus);
						if ($#match >= 0){ 
							$WarningOutput .= "$description has a warning state ($SensorStates[$status]); ";
						}
					}
				}
			}
			else{
				my @ids = split(/,/, $Nagios->opts->ids);
				for (my $i=0;$i<=$#ids;$i++){
					$id=$ids[$i];
					$description = $RequestResultDesc->{$OID_hpicfSensorDescr.".$id"};
					$status = $RequestResultStatus ->{$OID_hpicfSensorStatus.".$id"};
					if( (!defined($description)) || (!defined($status) ) ){
						$SNMPSession->close();
						$_[1] = "Error recovering description and/or status of the sensor with id $id.\n";
						$_[1] .= "If you want to know the existent sensor ids, just type 'check_hp_icf_sensors -H hostaddress -T' for test mode ";
						return UNKNOWN;
					}
					elsif ($status == 5){ #No present
						$SNMPSession->close();
						$_[1] = "Sensor with id $id is not present\n	";
						$_[1] .= "If you want to know the existent sensor ids, just type 'check_hp_icf_sensors -H hostaddress -T' for test mode ";
						return UNKNOWN;
					}
					@match =  grep (/$status/,@CriticalStatus);
					if ($#match >= 0){ 
						$CriticalOutput .= "$description has a critical state ($SensorStates[$status]); ";
					}
					else{
						@match =  grep (/$status/,@WarningStatus);
						if ($#match >= 0){ 
							$WarningOutput .= "$description has a warning state ($SensorStates[$status]); ";
						}
					}
				}				
			}
			if ($CriticalOutput ne ''){
				$PluginOutput = $CriticalOutput;
				$PluginReturnValue = CRITICAL;
			}
			elsif ($WarningOutput ne ''){
				$PluginOutput = $WarningOutput;
				$PluginReturnValue = WARNING;
			}
			else{
				$PluginOutput="All the sensors have the status value as 'good'";
				$PluginReturnValue=OK;
			}	

		}
		else {
			$_[1] = "Error '$SNMPError' requesting sensor status data ".
					"from agent $Nagios->{opts}->{hostname}:$Nagios->{opts}->{port} ".
					"using protocol $Nagios->{opts}->{snmpver} ". 
					"and community string **hidden for security**";
			return 0;
		}
		
		$SNMPSession->close();
	}
	else {
		# Error starting SNMP session;
		$PluginOutput = "Error '$SNMPError' starting session";
		return 0;	
	}
	$_[1]=$PluginOutput;
	return $PluginReturnValue;
}
