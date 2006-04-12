package Catalyst::Helper::Model::ShanonDBI;

use strict;
use Data::Dumper;
use Class::DBI::ViewLoader;
use DirHandle;
use FileHandle;

=head1 NAME

Catalyst::Helper::Model::ShanonDBI - Helper for ShanonDBI Models

=head1 SYNOPSIS

    script/create.pl model ShanonDBI ShanonDBI dsn user password

=head1 DESCRIPTION

Helper for ShanonDBI Model.

=head2 METHODS

=over 4

=item mk_compclass

Reads the database and makes a main model class as well as placeholders
for each table.

=back 

=cut

sub load_views {
    my $self = shift;

    my @views = $self->get_views;

    my $classes;

    for my $view ( $self->_filter_views(@views) ) {
        my @cols = $self->get_view_cols($view);
        $classes->{$view} = \@cols;
    }

    return $classes;
}

# user_master -> User
sub get_class_name {
    my ( $this, $str ) = @_;
    my @array = split( //, $str );
    for ( my $i = 0; $i < scalar(@array); $i++ ) {
        if ( $i == 0 ) {
            $array[$i] = uc $array[$i];
        }
        elsif ( $array[$i] eq '_' ) {
            $array[ $i + 1 ] = uc $array[ $i + 1 ];
        }
    }
    my $result = join( '', @array );
    $result =~ s/_//g;
    $result =~ s/Master//g;
    return $result;
}

sub mk_compclass {
    my ( $self, $helper, $dsn, $user, $pass, @limited_file ) = @_;
    print "==========================================================\n";

    # dsn is necessary
    unless ($dsn) {
        die "usage: ss_create.pl model ShanonDBI ShanonDBI \"dbi:Pg:dbname=smart_seminar;host=ookami;\" user pass\n";
        return 1;
    }

    # generate model from a configuration files
    # search file from config directory
    my $dir = sprintf( "%s/config", $helper->{base} );
    my $conf_dir = DirHandle->new($dir) or die "can't open dir, $!";
    my @files = sort grep -f, map "$dir/$_", $conf_dir->read;

    # create Model directory
    $helper->mk_dir(
        sprintf( "%s/lib/%s/%s/%s",
            $helper->{'base'}, $helper->{'app'}, $helper->{'type'}, ucfirst( $helper->{'name'} ) )
    );

    # only selected class
    my %limit;
    $limit{$_} = 1 foreach (@limited_file);

    # output view file
    if ( $limited_file[0] =~ /^[a-z]/ ) {
        my $file   = $limited_file[0];
        my $loader = Class::DBI::ViewLoader->new(
            dsn      => $dsn,
            username => $user,
            password => $pass
        );
        my $classes = &load_views($loader);

        my $dir = $self->get_class_name($file);

        # template variables
        my %vars;
        $vars{'class'} = sprintf( "%s::%s::%s::%s", $helper->{'app'}, $helper->{'type'}, $helper->{'name'}, $dir );
        $vars{'app'}   = $helper->{'app'};
        $vars{'type'}  = $helper->{'type'};
        $vars{'name'}  = $helper->{'name'};
        $vars{'table'} = $file;
        $vars{'cols'}  = join( ' ', @{ $classes->{$file} } );

        # file name
        my $class_path = sprintf( "%s/lib/%s/%s/%s/%s.pm",
            $helper->{'base'}, $helper->{'app'}, $helper->{'type'}, $helper->{'name'}, ucfirst($dir) );

        # generate file
        $helper->render_file( 'view_class', $class_path, \%vars );

        return 1;
    }

    # output all table files
    foreach my $file (@files) {

        # create config_name directory
        my @tmp = split '/', $file;
        my $dir = $tmp[-1];
        $dir =~ s/\.pl$//;

        # only selected class
        if ( scalar @limited_file ) {
            next unless ( $limit{$dir} );
        }

        # read config
        my $config = do "$file";

        # template variables
        my %vars;

        #$vars{'class'} = sprintf("%s::%s::%s::%s",
        #                     $helper->{'app'}, $helper->{'type'}, ucfirst($helper->{'name'}), ucfirst($dir)
        #                 );
        $vars{'class'} = sprintf( "%s::%s::%s::%s", $helper->{'app'}, $helper->{'type'}, $helper->{'name'}, $dir );
        $vars{'app'}   = $helper->{'app'};
        $vars{'type'}  = $helper->{'type'};
        $vars{'name'}  = $helper->{'name'};
        $vars{'table'} = $config->{'table'};

        my @columns;
        my @seqs;
        my @refs;

        foreach my $schema ( @{ $config->{'schema'} } ) {
            next if ( $schema->{'temporary'} );
            push @columns, $schema->{'name'};

            # primary key
            if ( defined $schema->{'sql'}->{'primarykey'} && $schema->{'sql'}->{'primarykey'} eq '1' ) {
                $vars{'primarykey'} = sprintf( qq!__PACKAGE__->columns('Primary' => '%s');!, $schema->{'name'} );
            }

            # sequence
            if ( $schema->{'sql'}->{'type'} eq 'serial' ) {
                push @seqs, sprintf( "__PACKAGE__->sequence('%s_%s_seq');", $config->{'table'}, $schema->{'name'} );
            }

            # has_a
            if ( $schema->{'sql'}->{'references'} ) {
                push @refs,
                    sprintf( "__PACKAGE__->has_a(%s => '%s');",
                    $schema->{'name'}, $schema->{'sql'}->{'references'}->{'class'} );
            }
        }
        $vars{'seq'}  = join( "\n", @seqs );
        $vars{'refs'} = join( "\n", @refs );
        $vars{'cols'} = join( ' ',  @columns );

        # file name
        my $class_path = sprintf( "%s/lib/%s/%s/%s/%s.pm",
            $helper->{'base'}, $helper->{'app'}, $helper->{'type'}, $helper->{'name'}, ucfirst($dir) );

        # generate file
        $helper->render_file( 'model_class', $class_path, \%vars );
    }

    # output Class::DBI config
    unless (@limited_file) {

        # template variables
        my %vars;
        $vars{'class'} = sprintf( "%s::%s::%s", $helper->{'app'}, $helper->{'type'}, $helper->{'name'} );
        $vars{'dsn'}   = $dsn;
        $vars{'user'}  = $user;
        $vars{'pass'}  = $pass;
        $vars{'rel'}   = $dsn =~ /sqlite|pg|mysql/i ? 1 : 0;

        # file name
        my $class_path = sprintf( "%s/lib/%s/%s/%s.pm", $helper->{'base'}, $helper->{'app'}, $helper->{'type'},
            $helper->{'name'} );

        # generate file
        $helper->render_file( 'config_class', $class_path, \%vars );
    }

    print "==========================================================\n";
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>

=head1 AUTHOR

Jun Shimizu, C<shimizu@shanon.co.jp>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__config_class__
package [% class %];

use strict;
use base qw(Catalyst::Model::ShanonDBI);
use Class::DBI::AbstractSearch;

# for Catalyst::Model::ShanonDBI
__PACKAGE__->connection('[% dsn %]',
                        '[% user %]',
                        '[% pass %]');

# for Catalyst::Model::ShanonDBI::Loader
#__PACKAGE__->config(
#    dsn           => '[% dsn %]',
#    user          => '[% user %]',
#    password      => '[% pass %]',
#    options       => {},
#    relationships => [% rel %]
#);

=head1 NAME

[% class %] - Catalyst::Model::ShanonDBI Model Component

=head1 SYNOPSIS

See L<Catalyst::Model::ShanonDBI>

=head1 DESCRIPTION

Catalyst::Model::ShanonDBI Model Component.

=head1 AUTHOR

Jun Shimizu, C<shimizu@shanon.co.jp>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__model_class__
package [% class %];

use strict;
use base '[% app %]::Model::[% name %]';

__PACKAGE__->table('[% table %]');
[% primarykey %]
__PACKAGE__->columns('All' => qw([% cols %]));
[% seq %]
[% refs %]

=head1 NAME

[% class %] - [% app %]::Model::[% name %] Table Class

=head1 SYNOPSIS

See L<[% app %]::Model::[% name %]>

=head1 DESCRIPTION

[% app %]::Model::[% name %] Table Class.

=cut

# ##################################################
# # 登録用コールバック群
# ##################################################
# __PACKAGE__->add_trigger(create_before => \&create_before);
# sub create_before {
#     my $self = shift;
#     my $c = shift;
#     my $hash = shift;
# }
# 
# __PACKAGE__->add_trigger(create_after => \&create_after);
# sub create_after {
#     my $self = shift;
#     my $c = shift;
#     my $hash = shift;
#     my $result = shift;
# }

# ##################################################
# # 更新用コールバック群
# ##################################################
# __PACKAGE__->add_trigger(update_before => \&update_before);
# sub update_before {
#     my $self = shift;
#     my $c = shift;
# }
# 
# __PACKAGE__->add_trigger(update_after => \&update_after);
# sub update_after {
#     my $self = shift;
#     my $c = shift;
#     my $result = shift;
# }

# ##################################################
# # 削除用コールバック群
# ##################################################
# __PACKAGE__->add_trigger(delete_before => \&delete_before);
# sub delete_before {
#     my $self = shift;
#     my $c = shift;
# }
# 
# __PACKAGE__->add_trigger(delete_after => \&delete_after);
# sub delete_after {
#     my $self = shift;
#     my $c = shift;
#     my $result = shift;
# }

=head1 AUTHOR

Jun Shimizu, C<shimizu@shanon.co.jp>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
__view_class__
package [% class %];

use strict;
use base '[% app %]::Model::[% name %]';

__PACKAGE__->table('[% table %]');
__PACKAGE__->columns(Primary => 'id');
__PACKAGE__->columns(All => qw([% cols %]));

=head1 NAME

[% class %] - [% app %]::Model::[% name %] View Class

=head1 SYNOPSIS

See L<[% app %]::Model::[% name %]>

=head1 DESCRIPTION

[% app %]::Model::[% name %] View Class.

=cut

##################################################
# ビューは読み取り専用
##################################################
sub create {
    die "this model is select only.";
}

##################################################
# ビューは読み取り専用
##################################################
sub update {
    die "this model is select only.";
}

##################################################
# ビューは読み取り専用
##################################################
sub delete {
    die "this model is select only.";
}

=head1 AUTHOR

Jun Shimizu, C<shimizu@shanon.co.jp>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
