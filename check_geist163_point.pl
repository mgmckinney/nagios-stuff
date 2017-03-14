#!/usr/bin/perl

use Getopt::Long qw(:config no_ignore_case);

$get_cmd = "/usr/bin/snmpget";

GetOptions('h:s' => \$o_host,'c:s' => \$o_community, 'O:s' => \$o_oid, 'S:s' => \$o_state);

if( !($o_host) || !($o_community)  || !($o_oid) || !($o_state))
{
	die "Usage: check_geist163_point.pl -h host -c snmp_community -O oid -S state(Open/Closed)\n";
}

$snmp_get_oid = `$get_cmd -v 2c -Ovq -c $o_community $o_host $o_oid`;
chomp($snmp_get_oid);

if (!($snmp_get_oid =~ /^[0-9]+$/ ) || ( $? != 0)) { exit 3 };

$nag_exit = 0;

if (( lc $o_state eq "open" ) && ( int($snmp_get_oid) == 0 )) { $nag_exit = 0; }
elsif (( lc $o_state eq "open" ) && ( int($snmp_get_oid) >= 95 )) { $nag_exit = 2; }
elsif (( lc $o_state eq "closed" ) && ( int($snmp_get_oid) >= 95 )) { $nag_exit = 0; }
elsif (( lc $o_state eq "closed" ) && ( int($snmp_get_oid) < 95 )) { $nag_exit = 2; }
else { $nag_exit = 3; }

if ($nag_exit == 0) { print "OK : Sensor State Ok - $o_state\n"; }
if ($nag_exit == 1) { print "Warning : Sensor State Warning - $o_state\n"; }
if ($nag_exit == 2) { print "Critical : Sensor State Critical - $o_state\n"; }
if ($nag_exit == 3) { print "Unknown : Sensor State Unknown\n"; }

exit $nag_exit;
