#!/usr/bin/perl

use Getopt::Long qw(:config no_ignore_case);

$walk_cmd = "/usr/bin/snmpwalk";

GetOptions('h:s' => \$o_host,'c:s' => \$o_community, 'W:i' => \$o_warnTemp, 'C:i' => \$o_critTemp);

if( !($o_host) || !($o_community)  || !($o_warnTemp) || !($o_critTemp))
{
	die "Usage: check_geist163_temp.pl -h host -c snmp_community -W warnTemp -C critTemp\n";
}

@snmp_sensor_names = split /\n/, `$walk_cmd -v 2c -Ovq -c $o_community $o_host .1.3.6.1.4.1.21239.2.5.1.3`;

if ( $? != 0) { exit 3 };

@snmp_sensor_tempF = split /\n/, `$walk_cmd -v 2c -Ovq -c $o_community $o_host .1.3.6.1.4.1.21239.2.5.1.6`;

$sensor = 0;
$nag_exit = 0;
$out_text = '';

foreach $snmp_sensor_name (@snmp_sensor_names) {
	$snmp_sensor_names[$sensor] =~ s/"//g;
	if ($snmp_sensor_tempF[$sensor] >= $o_critTemp) { 
		$nag_exit = 2; 
		$out_text .= "$snmp_sensor_names[$sensor] : Critical " . $snmp_sensor_tempF[$sensor] . "F >= " . $o_critTemp ."F\n";
	} elsif ($snmp_sensor_tempF[$sensor] >= $o_warnTemp) {
		if ($nag_exit < 2) { $nag_exit = 1; } 
		$out_text .= "$snmp_sensor_names[$sensor] : Warning " . $snmp_sensor_tempF[$sensor] . "F >= " . $o_warnTemp ."F\n";
	} else {
		$out_text .= "$snmp_sensor_names[$sensor] : OK : " . $snmp_sensor_tempF[$sensor] . "F\n";
	}
	$sensor++;
} 

if ($nag_exit == 0) { print "OK : $sensor sensors monitored\n"; }
if ($nag_exit == 1) { print "Warning : Sensor(s) above warning threshold\n"; }
if ($nag_exit == 2) { print "Critical : Sensor(s) above critical threshold\n"; }

print $out_text;

exit $nag_exit;
