#!/usr/bin/env perl

use strict;
use warnings;
use feature qw( say );
use local::lib 'local';

use MaxMind::DB::Reader;
use MaxMind::DB::Writer::Tree;
use Net::Works::Network;

my $filename = 'GeoLite2-ASN-SAP.mmdb';
my $reader   = MaxMind::DB::Reader->new( file => 'GeoLite2-ASN.mmdb' );

my %types = (
    autonomous_system_number        => 'uint32',
    autonomous_system_organization  => 'utf8_string',
);

my %address_for_sap_asn = (
    '10.216.24.0/23'  => asn(4268359786, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD06'),
    '10.236.178.0/24' => asn(4268359782, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD02'),
    '10.236.208.0/21' => asn(4268359781, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD01'),
    '10.236.36.0/22'  => asn(4268359781, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD01'),
    '10.236.40.0/22'  => asn(4268359782, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD02'),
    '10.236.44.0/22'  => asn(4268359783, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD03'),
    '10.236.48.0/22'  => asn(4268359784, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD04'),
    '10.236.52.0/22'  => asn(4268359785, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD05'),
    '10.246.239.0/24' => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.246.26.0/24'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.246.3.0/24'   => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.100.0/23'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.102.0/24'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.104.0/23'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.106.0/24'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.115.0/24'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.116.0/23'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.178.0/24'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.192.0/24'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.209.0/24'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '10.46.68.0/22'   => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '130.214.232.0/28'   => asn(4268359782, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD02'),
    '130.214.232.128/26' => asn(4268359783, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD03'),
    '130.214.232.16/28'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '130.214.232.192/26' => asn(4268359784, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD04'),
    '130.214.232.32/27'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '130.214.232.64/26'  => asn(4268359782, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD02'),
    '130.214.233.0/26'   => asn(4268359785, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD05'),
    '130.214.233.64/28'  => asn(4268359783, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD03'),
    '130.214.233.96/27'  => asn(4268359782, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD02'),
    '147.204.198.0/24'   => asn(4268359786, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD06'),
    '147.204.35.128/27'  => asn(4268360580, 'SAP ConvergedCloud QA-DE-1 CC-MGMT'),
    '147.204.35.160/27'  => asn(4268359786, 'SAP ConvergedCloud QA-DE-1 CC-CLOUD06'),
);


my $tree = MaxMind::DB::Writer::Tree->new(
    database_type => 'GeoIP2-ASN-SAP',
    description =>
        { en => 'GeoIP ASN Data with SAP Custom Additions', },
    ip_version => 6,
    map_key_type_callback => sub { $types{ $_[0] } },
    merge_strategy => 'recurse',
    record_size => 24,
    # Disable reservation of private networks in mmdbs
    remove_reserved_networks => 0,
);

# Maxmind Public IPs from GeoLite2-ASN.mmdb
$reader->iterate_search_tree(
    sub {
        my $ip_as_integer = shift;
        my $mask_length   = shift;
        my $data          = shift;

        my $address = Net::Works::Address->new_from_integer(integer => $ip_as_integer );
        my $ip_version = $address->version;

        my $network = join '/', $address->as_string, $mask_length;
        $tree->insert_network($network, $data);
    }
);

# SAP Custom Private IPs
for my $range (keys %address_for_sap_asn) {
    my $network = Net::Works::Network->new_from_string( string => $range );
    my $data = $address_for_sap_asn{$range};

    print "$network \n";
    $tree->insert_network($network, $data);
}

# Write the database to disk.
open my $fh, '>:raw', $filename;
$tree->write_tree( $fh );
close $fh;

say "$filename has now been created";

sub asn {
    my %format = (
        autonomous_system_number => shift,
        autonomous_system_organization => shift,
    );
    return \%format
}