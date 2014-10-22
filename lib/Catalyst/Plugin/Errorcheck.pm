package Catalyst::Plugin::Errorcheck;

use strict;
use warnings;
use Email::Valid;
use Data::Dumper;
use Date::Parse;

# Time-stamp: "05/12/08 22:16:32 nakamura" last modified.

use base 'Class::Data::Inheritable';
use NEXT;

__PACKAGE__->mk_classdata('_check_error_obj');

our $VERSION = '0.01';

=head1 NAME

Catalyst::Plugin::Errorcheck - Error�����å��Ǥ�

=head1 SYNOPSIS

use Catalyst qw/Errorcheck/

=head1 DESCRIPTION

���Ĥ�Τ�ĤǤ�
�衼����ˤ����Ĥ�Ƥ֤����Ǥ���

=cut

=over 2

=item checkErrors

#-------------
�ɤ�ʥ����å��򤷤Ƥ���뤫��
$c->clc($self) �����٤� class config �˽��äƥ����å����ޤ���

#------------
���Ϥ�
$c->checkErros($self,@checklist);
�����å�����ǡ�����
$c->req()
��default�����Ѥ��Ƥ��ޤ���
�⤷�⡢
$c->stash->{check_errors_data} �� HASH�ǡ���������С����������å����ޤ���

#-------------
���Ϥ�
1 ���顼��������
0 ̵�����
������ϡ�
$c->stash->{find_errors}�� ARRAY ref �ǤϤ��äƤ��ޤ���

=cut

=item setup

Catalyst��ư���ν����Ǥ���
checkErrors�����������Ѥ��륪�֥������Ȥ�������ޤ���

=cut

sub setup {
    my $c = shift;
    $c->log->debug('Create Catalyst::Errorcheck object') if ( $c->debug );
    my $obj = Catalyst::Errorcheck::Object->new();
    $c->_check_error_obj($obj);
    $c->NEXT::setup(@_);
}

=item check_all_errors

�ȥꥬ����
    $self->call_trigger('check_all_errors_before', $c,\@errors);
���顼�����å������̤ʤ�Τ�Ԥ��������ˤɤ���!

=cut

sub check_all_errors {
    my ( $c, $self, @notchecklist ) = @_;
    $c->log->debug('Errorcheck.pm : check_all_errors');
    $c->ceo($self);

    #--------------------------------
    # �����å����� �ǡ����򤭤��
    my (%value);
    if ( $c->stash->{'error_check_data'} ) {
        %value = ( ref $c->stash->{'error_check_data'} eq 'HASH' )
            ? %{ $c->stash->{'error_check_data'} }
            : die 'data type is not HASH ref !!';
        delete $c->stash->{'error_check_data'};
    }
    else {
        %value = %{ $c->clc($self)->req_params() };
    }

    #--------------------------------
    # �����å�������ܤ����
    $self->call_trigger( 'get_check_item_list_before', $c, \@notchecklist );
    my (%schema) = $c->ceo($self)->get_check_item_list( \@notchecklist );
    $self->call_trigger( 'get_check_item_list_after', $c, \%schema );

    #    $c->log->debug('--------------------------------------------------------�ʤˤ�����å�����');
    #    $c->log->dumper(\%schema);
    my (@errors);    # ���顼����Ū�ˤ����ϥ�
    $self->call_trigger( 'check_all_errors_before', $c, \@errors );

    #--------------------------------
    # ���顼�����å��¹�
    foreach my $name ( keys %schema ) {
        my ($value)  = $value{$name};
        my ($schema) = $schema{$name};
        $c->_check_error_obj->_check_error_main( $c, $name, $value, $schema, \@errors );
    }
    $self->call_trigger( 'check_all_errors_after', $c, \@errors );
    my (@array);
    foreach my $e (@errors) {
        push( @array, $e );
        $c->log->debug(
            sprintf(
                "Input Error: %s => %s",
                exists $e->{'name'}    ? $e->{'name'}    : '',
                exists $e->{'message'} ? $e->{'message'} : '',
            )
        );
    }

    #     $c->stash->{find_errors} = \@array;
    #    return (@array) ? 1 : 0;

    # ʣ�緿���б����뤿���
    $c->ceo($self)->push_my_errors( \@array );

    #     return (@{$c->stash->{'find_errors'}->{$namespace}->{$plus_str}}) ? 1 : 0;
    return ( ref( $c->stash->{'find_errors'} ) eq 'HASH' ) ? 1 : 0;    # ���顼�������1�ʤ���0
}

=item check_error

�ȥꥬ����
    $self->call_trigger('check_error_before', $c,\@errors);
���顼�����å������̤ʤ�Τ�Ԥ��������ˤɤ���!

=cut

sub check_error {
    my ( $c, $self, $name ) = @_;

    $c->ceo($self);

    die "Can't find check schema" unless $name;

    #--------------------------------
    # �����å����� �ǡ����򤭤��
    my ($value);
    if ( $c->stash->{'error_check_data'} ) {
        $value =
            ( ref $c->stash->{'error_check_data'} eq 'HASH' )
            ? $c->stash->{'error_check_data'}->{$name}
            : die 'data type is not HASH ref !!';
        delete $c->stash->{'error_check_data'}->{$name};
    }
    else {
        $value = $c->clc($self)->req_params($name);
    }

    # trriger
    my (@errors);    # ���顼����Ū�ˤ����ϥ�
    $self->call_trigger( 'check_error_before', $c, \@errors );

    #--------------------------------
    # ���顼�����å��¹�
    my ($schema) = $c->clc($self)->schema($name);
    $c->_check_error_obj->_check_error_main( $c, $name, $value, $schema, \@errors );
    my (@array);
    foreach my $e (@errors) {
        push( @array, $e );
        $c->log->debug("Input Error: $e->{'name'} => $e->{'message'}");
    }

    #     $c->stash->{find_errors} =[] unless(ref $c->stash->{find_errors} eq 'ARRAY');
    #     push(@{$c->stash->{find_errors}},\@array);
    #     return (@array) ? 1 : 0;

    # ʣ�緿���б����뤿���
    $c->ceo($self)->push_my_errors( \@array );

    #     return (@{$c->stash->{'find_errors'}->{$namespace}->{$plus_str}}) ? 1 : 0;
    return ref( $c->stash->{'find_errors'} ) eq 'HASH' ? 1 : 0;
}

sub ceo {
    my ( $c, $self ) = @_;
    die "\$self is undefined" unless ($self);
    $c->_check_error_obj()->_c($c);
    $self = ref($self) if ( ref($self) );
    $c->_check_error_obj()->_self($self);
    return $c->_check_error_obj();
}

1;

package Catalyst::Errorcheck::Object;

# Errorcheck����ǤĤ������
use strict;
use base 'Class::Accessor::Fast';
use Data::Dumper;
use Date::Calc qw(:all);

sub new {
    my ($pkg) = @_;
    my $this = bless( {}, $pkg );
    $this->mk_accessors( '_c', '_self' );
    return $this;
}

sub get_my_errors {
    my ($this) = @_;

    my $c         = $this->_c();
    my $self      = $this->_self;
    my $namespace = $c->clc($self)->get_namespace();
    my $plus_str  = $c->clc($self)->get_form_plus_str();
    return undef unless ( $c->stash->{'find_errors'} );
    return undef unless ( $c->stash->{'find_errors'}->{$namespace} );
    return $c->stash->{'find_errors'}->{$namespace}->{$plus_str};
}

sub push_my_errors {
    my ( $this, $errors ) = @_;
    return unless ( @{$errors} );
    my $c         = $this->_c;
    my $self      = $this->_self;
    my $namespace = $c->clc($self)->get_namespace();

    my $plus_str = $c->clc($self)->get_form_plus_str();
    $c->stash->{'find_errors'} = {}
        unless ( $c->stash->{'find_errors'} );
    $c->stash->{'find_errors'}->{$namespace} = {}
        unless ( $c->stash->{'find_errors'}->{$namespace} );
    $c->stash->{'find_errors'}->{$namespace}->{$plus_str} = []
        unless ( $c->stash->{'find_errors'}->{$namespace}->{$plus_str} );
    push( @{ $c->stash->{'find_errors'}->{$namespace}->{$plus_str} }, @{$errors} );

    return 1;
}

sub get_check_item_list {
    my $this         = shift;
    my $notchecklist = shift;
    my $c            = $this->_c();
    my $self         = $this->_self();
    my (%schema);
    foreach ( $c->clc($self)->schema() ) {
        $schema{ $_->{'name'} } = $_ if ( defined $_->{'name'} );
    }
    delete $schema{$_} foreach ( @{$notchecklist} );
    return %schema;
}

sub _check_error_main {
    my ( $this, $c, $name, $value, $schema, $errors ) = @_;
    my ($check_routine)
        = ( defined $schema->{'form'}->{'error'}->{'check'} ) ? $schema->{'form'}->{'error'}->{'check'} : 0;
    if ($check_routine) {
        my (%check_result);
        if ( ref($check_routine) eq 'CODE' ) {
            %check_result = $check_routine->( $name, $value );
        }
        elsif ( $check_routine eq 'ignore' ) {
            next;
        }
        elsif ( $check_routine =~ /^regexp:(.+)$/ ) {
            %check_result = checkErrorsByRegexp( $name, $value, $1 );
        }
        else {
            %check_result = $c->_check_error_obj->_checkErrorsByName( $name, $value, $check_routine );
        }
        push(
            @{$errors},
            {   name    => $name,
                message => ( exists $check_result{'message'} ) ? $check_result{'message'} : '',
                append  => ( exists $schema->{'form'}->{'error'}->{'append'} )
                ? $schema->{'form'}->{'error'}->{'append'}
                : '',
            }
            )
            if ( $check_result{'status'} );
    }
    elsif ( $value and index( $value, "\x8E" ) >= $[ ) {
        push(
            @{$errors},
            {   name    => $name,
                message => 'Ⱦ�ѥ������ʤϻ��ѤǤ��ޤ���',
                append  => $schema->{'form'}->{'error'}->{'append'}
            }
        );
    }
    if (    exists $schema->{'sql'}->{'type'}
        and index( $schema->{'sql'}->{'type'}, 'char' ) >= $[
        and length($value) > $schema->{'sql'}->{'length'} )
    {
        push(
            @{$errors},
            {   name    => $name,
                message => sprintf( '%d�Х��Ȱ�������Ϥ��Ƥ�������������ʸ��: 2�Х��ȡ�Ⱦ�ѱѿ���: 1�Х��ȡ�',
                    $schema->{'sql'}->{'length'} ),
                append => $schema->{'form'}->{'error'}->{'append'}
            }
        );
    }

    #    $c->log->dumper('ɬ�ܤ��ɤ���'.$schema->{'sql'}->{'notnull'});
    #    $c->log->dumper('ɬ�ܤ��ɤ�������'.length($value));
    if ( ( $schema->{'sql'}->{'notnull'} or $schema->{'form'}->{'notnull'} ) and length($value) == 0 ) {

        #	$c->log->dumper('ɬ�ܤ��㡼00�ܤ�');
        push(
            @{$errors},
            {   name    => $name,
                message => 'ɬ�����Ϥ��Ƥ�������',
                append  => $schema->{'form'}->{'error'}->{'append'}
            }
        );
    }
}

sub _generateErrorMessages {
    my ( $this, $errors ) = @_;
    my (%message) = ( ja => '���Ϥ˥��顼������ޤ����������ι��ܤˤĤ��ƺ��٤����Ϥ���������' );
    my (%hash_errors) = map { $_->{'name'} => $_ } @{$errors};
    my (@order);
    foreach my $p ( $this->properties() ) {
        push( @order, $p ) if grep( $p eq $_, keys(%hash_errors) );
    }
    push( @order, differ( [ keys(%hash_errors) ], \@order ) );
    return join(
        "<br>\n",
        $message{ $ENV{'LANG'} },
        '',
        map( sprintf( '%s (%s)',
                html_escape( $_->{'label'} || $this->gettext( $ENV{'LANG'}, $_->{'name'} ), $_->{'message'} ) ),
            grep { not $_->{'ignorelist'} } map( $hash_errors{$_}, @order ) )
    );
}

sub _appendErrorMessages {
    my ( $this, $c, $FORM ) = @_;
    my $errors = $this->get_my_errors();
    return unless ( ref($errors) eq 'ARRAY' );

    my (%done);
    my %message;
    foreach my $e ( @{$errors} ) {
        my ($name) = $e->{'append'} || $e->{'name'};
        next if $done{$name}->{ $e->{message} };
        my $error_tag = $c->stash->{error_tag} || '<span class="errorMsg">$FORM{message}</span>';
        $error_tag =~ s/\$FORM{message}/$e->{message}/ig;
        push( @{ $message{$name} }, $error_tag );

        #	$FORM->{$name} = sprintf('%s<br>%s', $error_tag, $FORM->{$name});

        $done{$name}->{ $e->{message} }++;
    }

    foreach my $i ( keys %message ) {
        $FORM->{$i} = sprintf( '%s<br>%s', join '<br>', @{ $message{$i} }, $FORM->{$i} );
    }
}

sub _checkErrorsByName {
    my ( $this, $name, $value, $routine ) = @_;
    my $type = sprintf( '_%s', $routine );
    if ( $this->can($type) ) {    # can check routine
        my $message = $this->$type( $name, $value );
        return (
            status  => 1,
            message => $message
            )
            if $message;
        return ( status => 0 );
    }
    else {
        die "Error check code $routine($type) is not defined!!";
    }
}

sub _checkErrorsByRegexp {    # �ޤ�
    my ( $this, $name, $value, $regexp ) = @_;
    my ($routine) = sub {
        my ( $this, $name, $value ) = @_;
        return '���������ϤǤ�' unless $value =~ /^$regexp$/;
    };
    return checkErrorsByName( $this, $name, $value, $routine );
}

#-------------------
# �����å��ؿ���

sub _id {
    my ( $this, $name, $val ) = @_;
    return 'ɬ�����Ϥ��Ƥ�������' if length($val) == 0;
    return 'Ⱦ�ѱѿ��������Ϥ��Ƥ�������' unless $val =~ /^[\w_\.\-]+$/;
    return '6ʸ���ʾ夫��16ʸ����������Ϥ��Ƥ�������' if length($val) < 6 or length($val) > 16;
    return;
}

sub _digit {
    my ( $this, $name, $val ) = @_;
    return 'Ⱦ�ѿ��������Ϥ��Ƥ�������' if $val and $val !~ /^\d+$/;
    return;
}

sub _password {
    my ( $this, $name, $val ) = @_;
    return 'Ⱦ��ʸ�������Ϥ��Ƥ�������' unless $val =~ /^[\w]+$/;
    return 'Ⱦ�ѱѿ���6��20ʸ�������Ϥ��Ƥ�������' if length($val) < 6 or length($val) > 20;
    return;
}

sub _hiragana {
    my ( $this, $name, $val ) = @_;
    return '�Ҥ餬�ʤ����Ϥ��Ƥ�������' unless $this->is_in_set_of( $val, 'zhiragana', -add => '��' );
    return;
}

sub _zkatakana {
    my ( $this, $name, $val ) = @_;
    return '���ѥ������ʤ����Ϥ��Ƥ�������' unless $this->is_in_set_of( $val, 'zkatakanaext' );    #, -add => '��'
    return;
}

sub _haneisu {
    my ( $this, $name, $val ) = @_;
    ## Ⱦ�ѱѿ����Υ����å�
    return unless $val;
    return 'Ⱦ�ѱѿ��������Ϥ��Ƥ�������' if $val =~ /[\x8E\xA1-\xFE]/os;
    return;
}

sub _email {
    my ( $this, $name, $val ) = @_;
    return unless $val;
    return '�����ʥ��ɥ쥹�Ǥ�' unless Email::Valid->address( -address => $val );
    return;
}

sub _zip {
    my ( $this, $name, $value ) = @_;
    return '�ϥ��ե� "-" �����졢Ⱦ�ѿ��������Ϥ��Ƥ���������',
        if $value
        and $value !~ /^[\+]?[\d]+([\-][\d]+){1,5}$/;
}

sub _tel {
    my ( $this, $name, $value ) = @_;
    return '�ϥ��ե� "-" �����졢Ⱦ�ѿ��������Ϥ��Ƥ���������',
        if $value
        and $value !~ /^[\+]?[\d]+([\-][\d]+){1,5}$/;
}

sub _url {
    my ( $this, $name, $value ) = @_;
    return '̵���ʥǡ����Ǥ���',
        if $value
        and $value !~ m#^s?https?://[-_.!~*'()a-zA-Z0-9;/?:\@&=+\$,%\#]+$#;
}

sub _code_ne {
    my ( $this, $name, $val ) = @_;
    return unless $val;
    return 'Ⱦ����ʸ���ѻ���Ⱦ�ѱѿ����Τߤ����Ϥ��Ƥ�������'
        unless ( $val =~ /[A-Z0-9]/ );
    if ( $this->schema($name)->{'form'} and $this->schema($name)->{'form'}->{'maxlength'} ) {
        return sprintf( '%dʸ�������Ϥ��Ƥ�������', $this->schema($name)->{'form'}->{'maxlength'} )
            unless ( length($val) == $this->schema($name)->{'form'}->{'maxlength'} );
    }
    return;
}

sub _code_nhe {
    my ( $this, $name, $val ) = @_;
    return unless $val;
    return 'Ⱦ����ʸ���ѻ���Ⱦ�ѱѿ�����-(�ϥ��ե�)�Τߤ����Ϥ��Ƥ�������'
        unless ( $val =~ /[A-Z0-9-]/ );
    if ( $this->schema($name)->{'form'} and $this->schema($name)->{'form'}->{'maxlength'} ) {
        return sprintf( '%dʸ�������Ϥ��Ƥ�������', $this->schema($name)->{'form'}->{'maxlength'} )
            unless ( length($val) == $this->schema($name)->{'form'}->{'maxlength'} );
    }
    return;
}

# date ���Υ����å�
sub _date {
    my ( $this, $name, $val ) = @_;
    return unless $val;
    my @day;
    my $check;
    if ( $val =~ /^(\d{4})-(\d{2}|\d)-(\d{2}|\d)$/ ) {
        $check = check_date( $1, $2, $3 ) ? '' : 1;
    }
    else {
        $check = 1;
    }
    return '̵���ʥǡ����Ǥ���' if ($check);
}

# timestamp ���Υ����å�
sub _timestamp {
    my ( $this, $name, $val ) = @_;
    return unless $val;
    my @day;
    my $check;
    if ( $val =~ /^(\d{4})-(\d{2}|\d)-(\d{2}|\d)\s(\d{2}|\d):(\d{2}|\d):(\d{2}|\d)$/ ) {
        $check = check_date( $1, $2, $3 ) && check_time( $4, $5, $6 ) ? '' : 1;
    }
    elsif ( $val =~ /^(\d{4})-(\d{2}|\d)-(\d{2}|\d)$/ ) {
        $check = check_date( $1, $2, $3 ) ? '' : 1;
    }
    else {
        $check = 1;
    }
    return '̵���ʥǡ����Ǥ���' if ($check);
}

sub is_in_set_of {
    my ( $this, $line, $set, %opt ) = @_;
    my (@add);
    if ( $opt{'-add'} ) {
        foreach my $c ( $this->split_string( $opt{'-add'} ) ) {
            push( @add, join( '', map( sprintf( '\\x%X', $_ ), unpack( 'C*', $c ) ) ) );
        }
    }
    $set = [$set] unless ref($set) eq 'ARRAY';
    my $character_set = $this->get_character();
    my ($regex) = join( '|', map( $character_set->{$_}, @{$set} ), @add );
    return $line =~ /^(?:$regex)*$/s;
}

sub get_character {
    return {
        hkatakana    => '(\x8E[\xA6-\xDF])',                           # Ⱦ�ѥ������� [��-��]
        zalphabet    => '(\xA3[\xC1-\xDA\xE1-\xFA])',                  # ���ѥ���ե��٥å� [��-�ڣ�-��]
        zenkaku      => '[\xA1-\xFE]',                                 # ����ʸ��
        zdigit       => '(\xA3[\xB0-\xB9])',                           # ���ѿ��� [��-��]
        zhiragana    => '(\xA4[\xA1-\xF3])',                           # ���ѤҤ餬�� [��-��]
        zhiraganaext => '(\xA4[\xA1-\xF3]|\xA1[\xAB\xAC\xB5\xB6])',    # ���ѤҤ餬��(��ĥ) [��-�󡫡�����]
        zkatakana    => '(\xA5[\xA1-\xF6])',                           # ���ѥ������� [��-��]
        zkatakanaext => '(\xA5[\xA1-\xF6]|\xA1[\xA6\xBC\xB3\xB4])',    # ���ѥ�������(��ĥ) [��-����������]
        zlletter     => '(\xA3[\xE1-\xFA])',                           # ���Ѿ�ʸ�� [��-��]
        zspace       => '(\xA1\xA1)',                                  # ���ѥ��ڡ���
        zuletter     => '(\xA3[\xC1-\xDA])',                           # ������ʸ�� [��-��]
        ascii        => '[\x00-\x7F]',
        twoBytes     => '[\x8E\xA1-\xFE][\xA1-\xFE]',
        threeBytes   => '\x8F[\xA1-\xFE][\xA1-\xFE]',
    };
}

sub split_string {
    my $this          = shift;
    my $character_set = $this->get_character();
    return $_[0] =~ /$character_set->{'ascii'}|$character_set->{'twoBytes'}|$character_set->{'threeBytes'}/og;
}
