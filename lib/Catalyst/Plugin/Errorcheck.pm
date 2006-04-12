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

Catalyst::Plugin::Errorcheck - Errorチェックです

=head1 SYNOPSIS

use Catalyst qw/Errorcheck/

=head1 DESCRIPTION

いつものやつです
よーするにこいつを呼ぶだけです。

=cut

=over 2

=item checkErrors

#-------------
どんなチェックをしてくれるかは
$c->clc($self) からよべる class config に従ってチェックします。

#------------
入力は
$c->checkErros($self,@checklist);
チェックするデータは
$c->req()
をdefaultで利用しています。
もしも、
$c->stash->{check_errors_data} に HASHデータがあれば、それをチェックします。

#-------------
出力は
1 エラーがある場合
0 無い場合
ある場合は、
$c->stash->{find_errors}に ARRAY ref ではいっています。

=cut

=item setup

Catalyst起動時の処理です。
checkErrorsが内部で利用するオブジェクトを作成します。

=cut

sub setup {
    my $c = shift;
    $c->log->debug('Create Catalyst::Errorcheck object') if ( $c->debug );
    my $obj = Catalyst::Errorcheck::Object->new();
    $c->_check_error_obj($obj);
    $c->NEXT::setup(@_);
}

=item check_all_errors

トリガーは
    $self->call_trigger('check_all_errors_before', $c,\@errors);
エラーチェックを特別なものを行いたい場合にどうぞ!

=cut

sub check_all_errors {
    my ( $c, $self, @notchecklist ) = @_;
    $c->log->debug('Errorcheck.pm : check_all_errors');
    $c->ceo($self);

    #--------------------------------
    # チェックする データをきめる
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
    # チェックする項目を取得
    $self->call_trigger( 'get_check_item_list_before', $c, \@notchecklist );
    my (%schema) = $c->ceo($self)->get_check_item_list( \@notchecklist );
    $self->call_trigger( 'get_check_item_list_after', $c, \%schema );

    #    $c->log->debug('--------------------------------------------------------なにをチェックする');
    #    $c->log->dumper(\%schema);
    my (@errors);    # エラーを一時的にいれるハコ
    $self->call_trigger( 'check_all_errors_before', $c, \@errors );

    #--------------------------------
    # エラーチェック実行
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

    # 複合型に対応するために
    $c->ceo($self)->push_my_errors( \@array );

    #     return (@{$c->stash->{'find_errors'}->{$namespace}->{$plus_str}}) ? 1 : 0;
    return ( ref( $c->stash->{'find_errors'} ) eq 'HASH' ) ? 1 : 0;    # エラーがあると1ないと0
}

=item check_error

トリガーは
    $self->call_trigger('check_error_before', $c,\@errors);
エラーチェックを特別なものを行いたい場合にどうぞ!

=cut

sub check_error {
    my ( $c, $self, $name ) = @_;

    $c->ceo($self);

    die "Can't find check schema" unless $name;

    #--------------------------------
    # チェックする データをきめる
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
    my (@errors);    # エラーを一時的にいれるハコ
    $self->call_trigger( 'check_error_before', $c, \@errors );

    #--------------------------------
    # エラーチェック実行
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

    # 複合型に対応するために
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

# Errorcheckの中でつかうもの
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
                message => '半角カタカナは使用できません',
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
                message => sprintf( '%dバイト以内で入力してください（全角文字: 2バイト、半角英数字: 1バイト）',
                    $schema->{'sql'}->{'length'} ),
                append => $schema->{'form'}->{'error'}->{'append'}
            }
        );
    }

    #    $c->log->dumper('必須かどうか'.$schema->{'sql'}->{'notnull'});
    #    $c->log->dumper('必須かどうかで値'.length($value));
    if ( ( $schema->{'sql'}->{'notnull'} or $schema->{'form'}->{'notnull'} ) and length($value) == 0 ) {

        #	$c->log->dumper('必須じゃー00ぼけ');
        push(
            @{$errors},
            {   name    => $name,
                message => '必ず入力してください',
                append  => $schema->{'form'}->{'error'}->{'append'}
            }
        );
    }
}

sub _generateErrorMessages {
    my ( $this, $errors ) = @_;
    my (%message) = ( ja => '入力にエラーがありました。下記の項目について再度ご入力ください。' );
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

sub _checkErrorsByRegexp {    # まだ
    my ( $this, $name, $value, $regexp ) = @_;
    my ($routine) = sub {
        my ( $this, $name, $value ) = @_;
        return '不正な入力です' unless $value =~ /^$regexp$/;
    };
    return checkErrorsByName( $this, $name, $value, $routine );
}

#-------------------
# チェック関数だ

sub _id {
    my ( $this, $name, $val ) = @_;
    return '必ず入力してください' if length($val) == 0;
    return '半角英数字で入力してください' unless $val =~ /^[\w_\.\-]+$/;
    return '6文字以上かつ16文字以内で入力してください' if length($val) < 6 or length($val) > 16;
    return;
}

sub _digit {
    my ( $this, $name, $val ) = @_;
    return '半角数字で入力してください' if $val and $val !~ /^\d+$/;
    return;
}

sub _password {
    my ( $this, $name, $val ) = @_;
    return '半角文字で入力してください' unless $val =~ /^[\w]+$/;
    return '半角英数字6〜20文字で入力してください' if length($val) < 6 or length($val) > 20;
    return;
}

sub _hiragana {
    my ( $this, $name, $val ) = @_;
    return 'ひらがなで入力してください' unless $this->is_in_set_of( $val, 'zhiragana', -add => 'ー' );
    return;
}

sub _zkatakana {
    my ( $this, $name, $val ) = @_;
    return '全角カタカナで入力してください' unless $this->is_in_set_of( $val, 'zkatakanaext' );    #, -add => 'ー'
    return;
}

sub _haneisu {
    my ( $this, $name, $val ) = @_;
    ## 半角英数字のチェック
    return unless $val;
    return '半角英数字で入力してください' if $val =~ /[\x8E\xA1-\xFE]/os;
    return;
}

sub _email {
    my ( $this, $name, $val ) = @_;
    return unless $val;
    return '不正なアドレスです' unless Email::Valid->address( -address => $val );
    return;
}

sub _zip {
    my ( $this, $name, $value ) = @_;
    return 'ハイフン "-" を入れ、半角数字で入力してください。',
        if $value
        and $value !~ /^[\+]?[\d]+([\-][\d]+){1,5}$/;
}

sub _tel {
    my ( $this, $name, $value ) = @_;
    return 'ハイフン "-" を入れ、半角数字で入力してください。',
        if $value
        and $value !~ /^[\+]?[\d]+([\-][\d]+){1,5}$/;
}

sub _url {
    my ( $this, $name, $value ) = @_;
    return '無効なデータです。',
        if $value
        and $value !~ m#^s?https?://[-_.!~*'()a-zA-Z0-9;/?:\@&=+\$,%\#]+$#;
}

sub _code_ne {
    my ( $this, $name, $val ) = @_;
    return unless $val;
    return '半角大文字英字と半角英数字のみで入力してください'
        unless ( $val =~ /[A-Z0-9]/ );
    if ( $this->schema($name)->{'form'} and $this->schema($name)->{'form'}->{'maxlength'} ) {
        return sprintf( '%d文字で入力してください', $this->schema($name)->{'form'}->{'maxlength'} )
            unless ( length($val) == $this->schema($name)->{'form'}->{'maxlength'} );
    }
    return;
}

sub _code_nhe {
    my ( $this, $name, $val ) = @_;
    return unless $val;
    return '半角大文字英字と半角英数字と-(ハイフン)のみで入力してください'
        unless ( $val =~ /[A-Z0-9-]/ );
    if ( $this->schema($name)->{'form'} and $this->schema($name)->{'form'}->{'maxlength'} ) {
        return sprintf( '%d文字で入力してください', $this->schema($name)->{'form'}->{'maxlength'} )
            unless ( length($val) == $this->schema($name)->{'form'}->{'maxlength'} );
    }
    return;
}

# date 型のチェック
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
    return '無効なデータです。' if ($check);
}

# timestamp 型のチェック
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
    return '無効なデータです。' if ($check);
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
        hkatakana    => '(\x8E[\xA6-\xDF])',                           # 半角カタカナ [ヲ-゜]
        zalphabet    => '(\xA3[\xC1-\xDA\xE1-\xFA])',                  # 全角アルファベット [Ａ-Ｚａ-ｚ]
        zenkaku      => '[\xA1-\xFE]',                                 # 全角文字
        zdigit       => '(\xA3[\xB0-\xB9])',                           # 全角数字 [０-９]
        zhiragana    => '(\xA4[\xA1-\xF3])',                           # 全角ひらがな [ぁ-ん]
        zhiraganaext => '(\xA4[\xA1-\xF3]|\xA1[\xAB\xAC\xB5\xB6])',    # 全角ひらがな(拡張) [ぁ-ん゛゜ゝゞ]
        zkatakana    => '(\xA5[\xA1-\xF6])',                           # 全角カタカナ [ァ-ヶ]
        zkatakanaext => '(\xA5[\xA1-\xF6]|\xA1[\xA6\xBC\xB3\xB4])',    # 全角カタカナ(拡張) [ァ-ヶ・ーヽヾ]
        zlletter     => '(\xA3[\xE1-\xFA])',                           # 全角小文字 [ａ-ｚ]
        zspace       => '(\xA1\xA1)',                                  # 全角スペース
        zuletter     => '(\xA3[\xC1-\xDA])',                           # 全角大文字 [Ａ-Ｚ]
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
