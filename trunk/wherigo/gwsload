#!/usr/bin/perl
# $Id: gwsimport.pl,v 1.2 2008/04/24 11:02:05 misch Exp misch $
use strict;
use Data::Dumper;
use Fcntl qw(:seek);
use Archive::Tar;
use File::Temp;
use XML::Twig;
use Encode;
use utf8;

open (OUT, ">$ARGV[1]") || die "$!: output file";
binmode(OUT, ':raw');	# at to neprekodovava do utf8

print OUT pack('H*', '020a53594e4300');	# 02 0a "SYNC" 00

my $t= XML::Twig->new(
	twig_handlers   => {
		'/savegame' => sub {},
		'/savegame/header' => sub {
			my ($t, $elt) = @_;

			# element->(tag|name|text|attr|...)
			my $name = $elt->first_child('name')->text;
			my $u = $elt->first_child('foo1')->text;
			my $u2 = $elt->first_child('foo2')->text;
			my $v = $elt->first_child('foo3')->text;
			my $v2 = $elt->first_child('foo4')->text;
			my $player = $elt->first_child('player')->text;
			my $device = $elt->first_child('devicetype')->text;
			my $device_id = $elt->first_child('deviceid')->text;
			my $savename = $elt->first_child('savename')->text;

			# float hodnoty se neulozi vzdy presne stejne, ale s tim nic nenadelam
			my $N = $elt->first_child('coords')->att('latitude');
			my $E = $elt->first_child('coords')->att('longitude');
			my $h = $elt->first_child('coords')->att('height');

			my $buf = pack('Z* LL Z*Z*Z* LL Z* ddd', 
				$name, $u, $u2, $player, $device, $device_id, $v,$v2, $savename, $N, $E, $h);

			print OUT pack('L', length($buf));
			print OUT $buf;
			$t->purge;	# uvolnim pamet
		},
		'/savegame/object_types' => sub {
			my ($t, $elt) = @_;
			# <object_types count="53">
			#       <type cnt="1">ZMedia</type>
			#             <type cnt="2">ZMedia</type>
			my $cnt = $elt->att('count');
			my @types = ();

			foreach my $t ($elt->children('type')) {
				my $id = $t->att('cnt');
				my $type = $t->text;
				$types[$id] = $type;
			};

			print OUT pack('L', $cnt);
			for (my $i=1; $i<=$cnt; $i++) {
				print OUT pack('L', length($types[$i]));
				print OUT $types[$i];
			};
			$t->purge;	# uvolnim pamet
		},
		'/savegame/data/type_of_next_object' => sub {
			my ($t, $elt) = @_;
			# id ignoruji
			my $typ = $elt->text;
			if ($typ ne '') {
				print OUT pack('L', length($typ)), $typ;
			};
			$t->purge;	# uvolnim pamet
		},
		# FIXME objekty samotne
		'/savegame/data/saved_element' => sub {
			# to hlavni
			my ($t, $elt) = @_;
			#warn "mam saved_element";
			my $bin = '';
			$bin .= pack('C', 5);	# push na zacatku
			foreach my $e ($elt->children('element')) {
				$bin .= compress_one_element($e);
			};
			$bin .= pack('C', 6);	# pop na konci
			die if Encode::is_utf8($bin);
			print OUT $bin;
			$t->purge;	# uvolnim pamet
		},
		'/savegame/data/final_dummy_data' => sub {
			my ($t, $elt) = @_;
			#  id="52"><![CDATA[3536646137323306]]>
			die "unknown encoding" if $elt->att('encoding') ne 'hex';
			# id me nezajima
			#warn "obsah=".$elt->text;
			# C0 je tam proto, aby to neprevedl do unikodu, ale aby to nechal v binarni podobe:
			my $bin = pack('C0H*', $elt->text);
			print OUT $bin;
			$t->purge;	# uvolnim pamet
		}
	},
	twig_print_outside_roots => 0
);
$t->parsefile($ARGV[0]);
$t->purge; # ne $t->flush, ten by to i vytisknul

close OUT;

exit;

#######################################################################################
sub elem_name {
	my ($elt) = @_;
	my $ret = pack('C0');
	my $n = $elt->att('name');
	$n = Encode::encode_utf8($n);	# do binarni podoby!
	if ($elt->att('namekind') eq 'string') {
		$ret .= pack('C', 3);
		$ret .= pack('L', length($n)) . $n;
	} elsif ($elt->att('namekind') eq 'number') {
		$ret .= pack('C', 2);
		$ret .= pack('d', $n);
	} else {
		die "unknown namekind: " . $elt->att('namekind');
	};
	return $ret;
};

sub compress_one_element { # {{{
	my ($elt) = @_;
	my $ret = pack('C0', '');	# at to neni utf8
	#warn Encode::is_utf8($ret);

	my $ttype = $elt->att('type');
	my $name = $elt->att('name');
	my $value = $elt->text;

	if ($ttype eq 'bool') {
		$ret .= elem_name($elt);
		$ret .= pack('C', 1);
		$ret .= pack('C', $value);
	} elsif ($ttype eq 'number') {
		$ret .= elem_name($elt);
		$ret .= pack('C', 2);
		$ret .= pack('d', $value);
	} elsif ($ttype eq 'string') {
		$ret .= elem_name($elt);
		$ret .= pack('C', 3);
		$value = Encode::encode_utf8($value);	# do binarni podoby!
		$ret .= pack('L', length($value)) . $value;
	} elsif ($ttype eq 'lua_bytecode') {
		$ret .= elem_name($elt);
		$ret .= pack('C', 4);
		if ($elt->att('encoding') eq 'hex') {
			# C0 je tam proto, aby to neprevedl do unikodu, ale aby to nechal v binarni podobe:
			#warn substr($value, 0, 182);
			$value = pack('C0H*', $value);
			#warn substr(unpack('H*', $value), 0, 182);
			#die "bc=$value";
		} else {
			die;
		};
		$ret .= pack('L', length($value)) . $value;
	} elsif ($ttype eq 'table') {
		$ret .= elem_name($elt);
		# tabulka podrizenych objektu
		$ret .= pack('C', 5);	# push na zacatku
		foreach my $e ($elt->children('element')) {
			$ret .= compress_one_element($e);
		};
		$ret .= pack('C', 6);	# pop na konci
	} elsif ($ttype eq 'object_id') {
		$ret .= elem_name($elt);
		$ret .= pack('C', 7);
		$ret .= pack('s', $value);
	} elsif ($ttype eq 'object') {
		$ret .= elem_name($elt);
		$ret .= pack('C', 8);
		$value = $elt->att('objecttype');
		$value = Encode::encode_utf8($value);	# do binarni podoby!
		$ret .= pack('L', length($value)) . $value;	# to je ve skutecnosti typ objektu

		# tabulka podrizenych objektu
		$ret .= pack('C', 5);	# push na zacatku
		foreach my $e ($elt->children('element')) {
			$ret .= compress_one_element($e);
		};
		$ret .= pack('C', 6);	# pop na konci
	} else {
		die "unknown type: $ttype";
	};


	#warn Encode::is_utf8($ret);
	#} elsif ($type == 0x08) {	# strasne podobne trojce, fakt nevim jaky je v nich rozdil :(
	#	sysread(F, $buf, 4);
	#	my $len = unpack('L', $buf);
	#	sysread(F, $buf, $len);
	#	$ttype = 'OBJECT';
	#	$value = $buf;
	#} else {
	#	sysread(F, $buf, 30);
	#	die dd($buf1.$buf)."unknown type=$type, sample=".unpack('H*', $buf).sprintf(", pos=%04x\n", sysseek(F, 0, SEEK_CUR));
	#};
	return $ret;
};	# }}}
