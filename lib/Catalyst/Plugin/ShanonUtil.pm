package Catalyst::Plugin::ShanonUtil;

use strict;
use warnings;
use Encode;
use DateTime;
use Date::Parse;
use Date::Calc;
use Module::Refresh;

my ($Revision) = '$Id: ShanonUtil.pm,v 1.20 2006/04/11 04:32:37 shimizu Exp $';
our $VERSION = '0.01';

=head1 NAME

Catalyst::Plugin::ShanonUtil - ���֤��̲ߤ�������ޤ�

=head1 SYNOPSIS

use Catalyst qw/ShanonUtil/

=head1 DESCRIPTION

���֤��̲��Ѥ������ʥ᥽�åɤ򽸤�Ƥ��ޤ���

=head1 METHODS

=head2 date2str

DB�����֤äƤ��������ॹ����פ� YYYY-MM-DD �����ˤ����֤��ޤ�
�Ѵ��Ǥ��ʤ��ä��Ȥ��Ϥ��Τޤ��֤��ޤ�

=cut

sub date2str {
    my ( $self, $value ) = @_;
    my (@array) = Date::Parse::strptime($value);
    if ( scalar(@array) == 0 ) {
        return $value;
    }
    else {

        #my $datefmt = SC->get_property($self, 'SYSTEM_SETTING_DATE_FORMAT');
        # $sec, $min, $hour, $day, $month, $year, $zone
        #if ($datefmt eq 'YYYY/MM/DD') {
        #    return sprintf("%04d/%02d/%02d", (1900 + $array[5]), (1 + $array[4]), $array[3])
        #} elsif ($datefmt eq 'YYYY-MM-DD') {
        #    return sprintf("%04d-%02d-%02d", (1900 + $array[5]), (1 + $array[4]), $array[3])
        #} elsif ($datefmt eq 'YYYYǯMM��DD��') {
        #    return sprintf("%04dǯ%02d��%02d��", (1900 + $array[5]), (1 + $array[4]), $array[3])
        #} elsif ($datefmt eq 'YY/MM/DD') {
        #    return sprintf("%02d-%02d-%02d", ($array[5] - 100), (1 + $array[4]), $array[3])
        #} elsif ($datefmt eq 'YYǯMM��DD��') {
        #    return sprintf("%02dǯ%02d��%02d��", ($array[5] - 100), (1 + $array[4]), $array[3])
        #} else {
        return sprintf( "%04d-%02d-%02d", ( 1900 + $array[5] ), ( 1 + $array[4] ), $array[3] )

            #}
    }
}

=head2 time2str

DB�����֤äƤ��������ॹ����פ� HH:MM �����ˤ����֤��ޤ�
�Ѵ��Ǥ��ʤ��ä��Ȥ��Ϥ��Τޤ��֤��ޤ�

=cut

sub time2str {
    my ( $self, $value ) = @_;
    my (@array) = Date::Parse::strptime($value);
    if ( scalar(@array) == 0 ) {
        return $value;
    }
    else {

        #my $timefmt = SC->get_property($self, 'SYSTEM_SETTING_DATE_FORMAT');
        # $sec, $min, $hour, $day, $month, $year, $zone
        #if ($timefmt eq 'HH::MM:SS') {
        #    return sprintf("%02d:%02d:%02d", $array[2], $array[1], $array[0]);
        #} elsif ($timefmt eq 'HH��MMʬSS��') {
        #    return sprintf("%02d��%02dʬ%02d��", $array[2], $array[1], $array[0]);
        #} elsif ($timefmt eq 'HH:MM') {
        #    return sprintf("%02d:%02d", $array[2], $array[1]);
        #} elsif ($timefmt eq 'HH��MMʬ') {
        #    return sprintf("%02d��%02dʬ", $array[2], $array[1]);
        #} else {
        return sprintf( "%02d:%02d", $array[2], $array[1] );

        #}
    }
}

=head2 date_valid

���ꤷ�����դ���������Τ��ɤ������֤�
XXXX-XX-XX �˥ޥå�
����͡�
 0 - �������ʤ�
 1 - ������

=cut

sub date_valid {
    my ( $self, $value ) = @_;
    my (@array) = Date::Parse::strptime($value);
    return Date::Calc::check_date( $array[5], $array[4], $array[3] );
}

=head2 date_valid

���ꤷ�����֤���������Τ��ɤ������֤�
XX:XX �˥ޥå�
����͡�
 0 - �������ʤ�
 1 - ������

=cut

sub time_valid {
    my ( $self, $value ) = @_;
    my (@array) = Date::Parse::strptime($value);
    Date::Calc::check_time( $array[2], $array[1], $array[0] );
}

=head2 timestamp_compare

���ꤷ��2�ĤΥ����ॹ����פ��羮���֤�
����:
 $date1 - �����ॹ����ף�
 $date2 - �����ॹ����ף�
�����:
   -1 - $date1 < $dat32
    0 - $date1 = $date2
    1 - $date1 > $date2
undef - $date1 �ޤ��� $date2 ��̵��

=cut

sub timestamp_compare {
    my ( $self, $date1, $date2 ) = @_;

    #    $self->log->debug('�������� date1: ', $date1);
    #    $self->log->debug('�������� date2: ', $date2);

    # $sec, $min, $hour, $day, $month, $year, $zone
    my (@array1) = Date::Parse::strptime($date1);
    my (@array2) = Date::Parse::strptime($date2);
    return undef if ( scalar(@array1) == 0 || scalar(@array2) == 0 );

    # �����ॹ����ף�
    my $dt1;
    eval {
        $dt1 = DateTime->new(
            year   => $array1[5] + 1900,
            month  => $array1[4] + 1,
            day    => $array1[3],
            hour   => ( $array1[2] == 0 ) ? '0' : $array1[2],
            minute => ( $array1[1] == 0 ) ? '0' : $array1[1],
            second => ( $array1[0] == 0 ) ? '0' : $array1[0]
        );
    };
    return undef if ($@);

    # �����ॹ����ף�
    my $dt2;
    eval {
        $dt2 = DateTime->new(
            year   => $array2[5] + 1900,
            month  => $array2[4] + 1,
            day    => $array2[3],
            hour   => ( $array2[2] == 0 ) ? '0' : $array2[2],
            minute => ( $array2[1] == 0 ) ? '0' : $array2[1],
            second => ( $array2[0] == 0 ) ? '0' : $array2[0]
        );
    };
    return undef if ($@);

    my $duration = $dt1 - $dt2;
    if ( $duration->is_positive() ) {
        return 1;
    }
    elsif ( $duration->is_zero() ) {
        return 0;
    }
    elsif ( $duration->is_negative() ) {
        return -1;
    }
    else {
        return undef;
    }
}

=head2 date_compare

���ꤷ��2�Ĥ����դ��羮���֤�
����:
 $date1 - ���գ�
 $date2 - ���գ�
�����:
   -1 - $date1 < $date2
    0 - $date1 = $date2
    1 - $date1 > $date2
undef - $date1 �ޤ��� $date2 ��̵��

=cut

sub date_compare {
    my ( $self, $date1, $date2 ) = @_;
    my $ts1 = sprintf( "%s 00:00:00+09", $date1 );
    my $ts2 = sprintf( "%s 00:00:00+09", $date2 );
    return $self->timestamp_compare( $ts1, $ts2 );
}

=head2 get_with_comma

���Ϥ��줿ʸ�����3��Ƕ��ڤ�

=cut

sub get_with_comma {
    my ( $c, $num ) = @_;
    no warnings;
    if ( int($num) eq '0' ) {
        return $num;
    }
    else {
        $num =~ s/(\d{1,3})(?=(?:\d\d\d)+(?!\d))/$1,/g;
        return $num;
    }
}

=head2 money2str

���ͤ�3��Ƕ��ڤ�Ƭ���̲ߵ������Ϳ���ޤ�

=cut

sub money2str {
    my ( $c, $value ) = @_;
    $value =~ s/\\//g;
    my $val = $c->get_with_comma($value);

    # TODO DB�����̲ߵ�������
    return '\\0' if !$val;
    return '\\' . $val;

    #return '$' . $val;
    #return '��' . $val; # ���
    #return '&euro;' . $val; # �桼��
    #return '&pound;' . $val; # �ݥ��
}

=head2 urlencode

URL�����˥��󥳡��ɤ��ޤ�

=cut

sub urlencode {
    my ( $c, $str ) = @_;
    $str =~ s/(\W)/'%'.unpack("H2", $1)/ego;
    $str =~ tr/ /+/;
    return $str;
}

=head2 xml_encode

XML����(UTF-8)�˥��󥳡��ɤ��ޤ�

=cut

sub xml_encode {
    my ( $self, $string ) = @_;
    return '' if ( length($string) == 0 );
    my @array = split( //, Encode::decode( 'euc-jp', $string ) );
    my $str;
    foreach my $c (@array) {
        $str .= sprintf( "&#x%x;", ord($c) );
    }
    return $str;
}

=head2 urldecode

URL��������ǥ����ɤ��ޤ�

=cut

sub urldecode {
    my ( $c, $str ) = @_;
    $str =~ tr/+/ /;
    $str =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/ego;
    return $str;
}

=head2 blank

�֥�󥯤�Ĵ�٤ޤ���

=cut

sub blank {
    return ( !defined $_[0] || $_[0] eq '' );
}

=head2 redirect_with_message

��å�������ɽ�����ơ�����URL��˥�����쥯�Ȥ��ޤ���

=cut

sub redirect_with_message {
    my ( $c, $message, $url ) = @_;
    die 'not found message' unless ($message);
    die 'not found url'     unless ($url);
    $c->res()->header( 'Content-Type' => 'text/html; charset=EUC-JP' );
    my $line = <<"EOF";
<html>
<head>
<title>�����ƥ��å�����</title>
<meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">
</head>
<body bgcolor="#FFFFFF" text="#000000">
<script type="text/javascript" language="JavaScript"><!--
alert("$message");
location.replace("$url");
//--></script>
</body>
</html>
EOF
    $c->res()->body($line);
}

=head2 date_time_now

���ߤλ��֤� YYYY-MM-DD HH:MM:SS+09 �������֤��ޤ���

=cut

sub date_time_now {
    my ( $c, $time ) = @_;
    if ($time) {
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime($time);
        my $date_time = sprintf( "%04d-%02d-%02d %02d:%02d:%02d+09", 1900 + $year, 1 + $mon, $mday, $hour, $min, $sec );
        return $date_time;
    }
    else {
        my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime();
        my $date_time = sprintf( "%04d-%02d-%02d %02d:%02d:%02d+09", 1900 + $year, 1 + $mon, $mday, $hour, $min, $sec );
        return $date_time;
    }
}

=head2 check_modules_update

�ǽ������������֤��ǽ��������֤Τۤ����������ե���������ɤ��ޤ���

=cut

sub check_modules_update {
    my ($c) = @_;
    unless ( exists $c->session->{last_access_date} ) {
        $c->session->{last_access_date} = $c->date_time_now();
    }
    my @list = $c->_reload_module( $c->config->{home} . 'lib/' . $c->config->{name} );
    $c->log->info("++++++ check_modules_update ++++++");
    for my $item (@list) {
        $c->log->info( "+ refresh: " . $item );
    }
    $c->log->info("++++++++++++++++++++++++++++++++++");
    $c->session->{last_access_date} = $c->date_time_now();
}

=head2 _reload_module

��������Ƥ���⥸�塼����Ҥ�ü�������ɤ��ޤ���
check_modules_update ����ƤФ�������ؿ��Ǥ���

=cut

sub _reload_module {
    my ( $c, $base ) = @_;
    my @list;
    my $lib_dir = $c->config->{home} . 'lib';
    for my $dir ( glob( $base . '*' ) ) {
        if ( -d $dir ) {
            push( @list, $c->_reload_module( $dir . '/' ) );
        }
        else {
            my $file_name = $dir;
            unless ( $file_name =~ /CVS/ ) {
                $file_name =~ m/$lib_dir\/(.+)$/xms;
                my $load_file = $1;
                my $last_update = $c->date_time_now( ( stat($file_name) )[10] );
                if ( $c->timestamp_compare( $c->session->{last_access_date}, $last_update ) <= 0 ) {
                    push( @list, $load_file );
                    Module::Refresh->new->refresh_module($load_file);
                }
            }
        }
    }
    return @list;
}

1;
