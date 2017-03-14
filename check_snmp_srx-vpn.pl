#!/usr/bin/perl

use Getopt::Long qw(:config no_ignore_case);

$walk_cmd = "/usr/bin/snmpwalk";

GetOptions('H:s' => \$o_host,'C:s' => \$o_community);

if( !($o_host) || !($o_community) )
{
	die "Usage: check_snmp_srx-vpn.pl -H host -C snmp_community\n";
}

@snmp_vpn_names = split /\n/, `$walk_cmd -v 2c -Ovq -c $o_community $o_host .1.3.6.1.4.1.2636.3.52.1.1.2.1.14.1.4`;

if ( $? != 0) { exit 3 };

if ( $snmp_vpn_names[0] =~ "No Such Instance.*" ) {
	print "OK: No VPNs configured";
	exit 0;
} 

@snmp_ike_status = split /\n/, `$walk_cmd -v 2c -Ovq -c $o_community $o_host .1.3.6.1.4.1.2636.3.52.1.1.2.1.6`;
@snmp_ipsec_status = split /\n/, `$walk_cmd -v 2c -Ovq -c $o_community $o_host .1.3.6.1.4.1.2636.3.52.1.1.2.1.6`;

$vpn = 0;
$nag_exit = 0;

foreach $snmp_vpn_name (@snmp_vpn_names) {
	$snmp_vpn_names[$vpn] =~ s/"//g;
	$out_text[$vpn] .= "VPN: $snmp_vpn_names[$vpn]";
	if ( length($snmp_vpn_names[$vpn]) < 18 ) { 
		$spaces = 18 - length($snmp_vpn_names[$vpn]);
		while ($spaces > 0) {
			$out_text[$vpn] .= " ";
			$spaces--;
		}
	}
	if ( $snmp_ike_status[$vpn] == 1 ) { 
		$out_text[$vpn] .= " IKE: OK    IPSEC: ";
	} else {
		$out_text[$vpn] .= " IKE: DOWN  IPSEC: ";
		$nag_exit = 1;
	}
	if ( $snmp_ipsec_status[$vpn] == 1 ) {
		$out_text[$vpn] .= "OK";
	} else {
		$out_text[$vpn] .= "DOWN";
		$nag_exit = 1;
	}
	$vpn++;
} 

if ($nag_exit == 0 ) {
	print "OK: All VPNs UP\n";
} else {
	print "WARNING: VPN(s) Down\n";
}

print join("\n",@out_text);

exit $nag_exit;
