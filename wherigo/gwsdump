#!/usr/bin/perl
# $Id: gwsdump.pl,v 1.13 2008/04/24 11:02:05 misch Exp misch $
use strict;
use Data::Dumper;
use Fcntl qw(:seek);
use Archive::Tar;
use File::Temp;
use XML::Writer;

my $buf;
open (F, '<', $ARGV[0]) || die;
binmode(F) || die;

our $doc = new XML::Writer(NEWLINES => 0, DATA_MODE => 1, DATA_INDENT => 3);
$doc->xmlDecl("UTF-8");
$doc->startTag("savegame", original_filename => $ARGV[0]);

# reset na pocatecni pozici:
sysseek(F, 0, SEEK_SET);

# identifikace cartridge:
sysread(F, $buf, 7);	# 02 0a "SYNC" 00
die "not a cartridge" if $buf ne pack('H*', '020a53594e4300');

sysread(F, $buf, 4);	# 75 00 00 00
my ($hdrlen) = unpack('L', $buf);

sysread(F, $buf, $hdrlen);
my ($name, $u, $u2, $player, $device, $device_id, $v,$v2, $savename, $N, $E, $h) = 
	unpack('Z* LL Z*Z*Z* LL Z* ddd', $buf);

$doc->startTag("header");
$doc->dataElement(name => $name);
$doc->dataElement(player => $player);
$doc->dataElement(devicetype => $device);
$doc->dataElement(deviceid => $device_id);
$doc->dataElement(savename => $savename);
$doc->dataElement(coords => undef, latitude => $N, longitude => $E, height => $h);
$doc->dataElement(foo1 => $u);
$doc->dataElement(foo2 => $u2);
$doc->dataElement(foo3 => $v);
$doc->dataElement(foo4 => $v2);
$doc->endTag();

# V .GWC soubory zacinaji identifikatory objektu od 1-ky (nula je vyhrazeny pro
# Lua bytecode). A protoze i zde se vyskytuji ty stejne identifikatory, znamena
# to ze samotne Media objekty by taky mely zacinat od jednicky. To odpovida
# skutecnosti.
# Objekt s cislem "-1" je nejake obecne kratke info o sejvnute hre (pozice, cas, ...),
# a objekt s cislem "0" je cartridge samotna.

sysread(F, $buf, 4);
my $pocet_objektu = unpack('L', $buf);
$doc->startTag("object_types", count => $pocet_objektu);
our %objtype_by_num = ();
for (my $i=1; $i<=$pocet_objektu; $i++) {
	sysread(F, $buf, 4);
	my $len = unpack('L', $buf);
	sysread(F, $buf, $len);
	#print "$i) $buf\n";
	$objtype_by_num{$i} = $buf;	# napr. $objtype_by_num{1} = 'ZMedia'
	$doc->dataElement('type', $buf, cnt => $i);
};
$doc->endTag();

sub dd($) {
	my ($txt) = unpack('H*', $_[0]);
	my $ret = '';
	while ((my $x = substr($txt, 0, 2, '')) ne '') {
		$ret .= $x . ' ';
	};
	return $ret;
};


sub read_one_element { # {{{
	my $buf;

	my $numread = sysread(F, $buf, 1);
	return if $numread <= 0;	# EOF;

	my $type = unpack('C', $buf);
	my $ttype = '?';
	my $value = undef;
	my $buf1 = $buf; $buf = '';

	#print "type=$type".sprintf(", pos=%04x\n", sysseek(F, 0, SEEK_CUR));
	if ($type == 0x01) { # bool
		sysread(F, $buf, 1);
		$ttype = 'bool';
		$value = unpack('C', $buf);	# 0/1
	} elsif ($type == 0x02) { # 8 bajtu cehosi? IMHO float
		sysread(F, $buf, 8);
		$ttype = 'number';
		$value = unpack('d', $buf);
	} elsif ($type == 0x03) { # binarni string, zadne ASCIIZ
		sysread(F, $buf, 4);
		my $len = unpack('L', $buf);
		sysread(F, $buf, $len);
		$ttype = 'string';
		$value = $buf;
	} elsif ($type == 0x04) { # lua bytecode
		sysread(F, $buf, 4);
		my $len = unpack('L', $buf);
		sysread(F, $buf, $len);
		$ttype = 'lua_bytecode';
		$value = $buf;
	} elsif ($type == 0x05) {
		$ttype = "PUSH";
		$value = $ttype;
	} elsif ($type == 0x06) {
		$ttype = "POP";
		$value = $ttype;
	} elsif ($type == 0x07) {
		sysread(F, $buf, 2);
		$ttype = 'object_id';	# pouziva se u medii, atd.
		$value = unpack('s', $buf);
	} elsif ($type == 0x08) {	# strasne podobne trojce, fakt nevim jaky je v nich rozdil :(
		sysread(F, $buf, 4);
		my $len = unpack('L', $buf);
		sysread(F, $buf, $len);
		$ttype = 'OBJECT';
		$value = $buf;
	} else {
		sysread(F, $buf, 30);
		die dd($buf1.$buf)."unknown type=$type, sample=".unpack('H*', $buf).sprintf(", pos=%04x\n", sysseek(F, 0, SEEK_CUR));
	};

	return ($type, $ttype, $value);
};	# }}}

sub read_structure {
	for (;;) {
		# KLIC:
		my ($type, $ttype, $value) = read_one_element();
		die "unexpected eof!" if !defined $type; # EOF;

		if ($type == 5) { # push
			die "unexpected double push";
		} elsif ($type == 6) { # pop
			last;
		} elsif (($type == 3) || ($type == 2)) {	# jen string nebo cislo smi byt indexem tabulky
			my $name = $value;

			# HODNOTA:
			my ($type2, $ttype2, $value2) = read_one_element();
			die "unexpected eof!" if !defined $type2; # EOF;

			if ($type2 == 5) { # push
				$doc->startTag('element', name => $name, namekind => $ttype, type => 'table');
				read_structure();	# rekurze :)
				$doc->endTag();
			} elsif ($type2 == 6) { # pop
				die "cannot assign POP to an element!";
			} elsif ($type2 == 8) { # pretypovani?
				my $newtype = $value2;
				my ($type4, $ttype4, $value4) = read_one_element();
				die "expected push" if $type4 != 5;
				$doc->startTag('element', name => $name, namekind => $ttype, type => 'object', objecttype => $newtype);
				read_structure();	# rekurze :)
				$doc->endTag();
			} else {
				if ($ttype2 eq 'lua_bytecode') {
					$doc->dataElement('element', unpack('H*',$value2), name => $name, namekind => $ttype, type => $ttype2, encoding => 'hex');

					my $fh = new File::Temp();
					binmode($fh);
					print $fh $value2;
					$fh->flush;
					if (open (DISASM, "luac -l - <" . $fh->filename . " |")) {
						my $lua_decompiled = '';
						while (<DISASM>) {
							$lua_decompiled .= $_;
						};
						close DISASM || warn "error running luac -l: $!";
						$doc->comment("Disassembled bytecode:\n$lua_decompiled");
					};
					undef $fh;	# automaticky smaze i ten docasny soubor
				} else {
					$doc->dataElement('element', $value2, name => $name, namekind => $ttype, type => $ttype2);
				};
				if ($ttype2 eq 'object_id') {
					$doc->comment('^ expected object type is ' . $objtype_by_num{$value2});
				};
			};
		} else {
			die "unknown element type at this point: $ttype";
		};
	};
};

$doc->startTag("data");
my $next_objtype = undef;
for (my $i=-1; $i<$pocet_objektu; $i++) {	# ano, nacitam o jeden vic, proste tam je :(
	my ($type, $ttype, $value) = read_one_element();
	die "unexpected eof!" if !defined $type; # EOF;
	die "first element should be push, not $ttype ($type)" if $type != 5;

	$doc->dataElement("type_of_next_object", $next_objtype, "id" => $i);
	$doc->startTag("saved_element", "id" => $i, "type_from_main_table" => $objtype_by_num{$i});
	read_structure();
	$doc->endTag;

	if ($i < ($pocet_objektu-1)) {
		sysread(F, $buf, 4);
		my $len = unpack('L', $buf);
		sysread(F, $buf, $len);
		$next_objtype = $buf;
	} else {
		# Tohle by se spravne uz melo IGNOROVAT a ani nikam nezapisovat. Je to jen jakysi zbytek,
		# ktery byl do GWS nejspis zapsany omylem:
		# nactu cely zbytek bufferu
		sysread(F, $buf, 99999); # cokoliv, nema to zadnou strukturu
		$next_objtype = undef;	
		$doc->startTag("final_dummy_data", encoding => "hex", "id" => $i);
		$doc->cdata(unpack('H*', $buf));	# tady jsou binarni hovadiny
		$doc->endTag;
	};
};
$doc->endTag();

$doc->endTag();
$doc->end;	# final checks

exit;


##############################################################################
