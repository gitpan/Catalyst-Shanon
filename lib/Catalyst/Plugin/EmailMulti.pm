package Catalyst::Plugin::EmailMulti;

use strict;
use Email::Send;
use Email::MIME;
use Email::MIME::Creator;
use Jcode;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Plugin::Email - Send emails with Catalyst

=head1 SYNOPSIS

    use Catalyst 'EmailMulti';

    __PACKAGE__->config->{email} = [qw/SMTP mail.shanon.co.jp/];

    $c->email(
        header => [
            From    => 'sri@oook.de',#日本語番もOK
            To      => 'sri@cpan.org',#日本語番もOK
            Subject => 'Hello!'#日本語番もOK
        ],
        body => 'Hello sri',# 本文
	multi => [{body=>$data->body(),# 添付ファイルの中身
		   filename=>$data->name(). '.' .$data->extention(),#ファイル名
		  },
                  {body=>$data->body(),
		   filename=>$data->name(). '.' .$data->extention(),
		  },
		  ]
             );

=head1 DESCRIPTION

Send emails with Catalyst and L<Email::Send> and L<Email::MIME::Creator>.

=head1 USING WITH A VIEW


=head1 METHODS

=head2 email

=cut

sub email {
    my $c     = shift;
    my $email = $_[1] ? {@_} : $_[0];

    #    $c->log->dumper($email);
    my @parts;
    if ( ref $email->{multi} eq 'ARRAY' ) {
        foreach ( @{ $email->{multi} } ) {
            my %tmp;
            my $encoding     = ( $_->{encoding} )       ? $_->{encoding}     : 'base64';
            my $content_type = ( $_->{"content_type"} ) ? $_->{content_type} : 'application/x-binary';
            next unless ( $_->{body} );
            my $body;

#	    $c->log->dumper('-------------------------------------------------------------------------どないやねん',$encoding);
            if ( $content_type =~ /html/ ) {
                $c->log->dumper(
                    '-------------------------------------------------------------------------どないやねんくそ',
                    $content_type );
                $body = Jcode::convert( $_->{body}, 'jis', 'euc' );
                $tmp{charset} = 'ISO-2022-JP';
            }
            else {

#		$c->log->dumper('-------------------------------------------------------------------------どないやねんはげ',$encoding);
                $body = $_->{body};
            }
            push(
                @parts,
                Email::MIME->create(
                    attributes => {
                        content_type => $content_type,
                        encoding     => $encoding,
                        filename     => Jcode::convert( $_->{filename}, 'jis', 'euc' ),
                        %tmp,
                    },
                    body => $body,
                )
            );
        }
        delete $email->{multi};
        if ( $email->{body} ) {
            push(
                @parts,
                Email::MIME->create(
                    attributes => {
                        content_type => 'text/plain',
                        charset      => 'ISO-2022-JP',
                    },
                    body => Jcode::convert( $email->{body}, 'jis', 'euc' ),
                )
            );
            delete $email->{body};
        }
    }
    my (%tmp) = @{ $email->{header} };
    foreach ( keys %tmp ) {
        $tmp{$_} = Jcode::convert( $tmp{$_}, 'jis', 'euc' );
    }
    $email->{body}   = Jcode::convert( $email->{body}, 'jis', 'euc' );
    $email->{header} = [%tmp];
    $email->{parts}  = [@parts] if (@parts);
    $email           = Email::MIME->create( %{$email} );
    my $args = $c->config->{email} || [];
    my $data = SS::Model::ShanonDBI::SystemSettingData->retrieve( SC->SYSTEM_SETTING_MAIL_SERVER );
    my $tmp  = $data->value;

    if ($tmp) {
        $args = [ split ' ', $tmp ];
    }
    my @args = @{$args};
    my $class;
    unless ( $class = shift @args ) {
        $class = 'SMTP';
        unshift @args, 'localhost';
    }
    $c->log->dumper( '-------------------------------------------------------------------- SEND ',  $email );
    $c->log->dumper( '-------------------------------------------------------------------- class ', $class );
    $c->log->dumper( '-------------------------------------------------------------------- class ', @args );
    $Email::Send::Qmail::QMAIL = '/usr/bin/qmail/qmail-inject';
    send $class => $email, @args;
}

=head1 SEE ALSO

L<Catalyst>,
L<Catalyst::Plugin::SubRequest>,
L<Email::Send>,
L<Email::MIME::Creator>

=head1 AUTHOR

nakamura kenichiro <nakamura@shanon.co.jp>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut

1;

__END__
    my $content_type =   ($body =~ /\0/)
                       ? 'application/x-binary'
                       : 'text/plain';
    
    Email::MIME->create(
        attributes => {
            content_type => $content_type,
            encoding     => 'base64', # be safe
        },
        body => $body,
    );
