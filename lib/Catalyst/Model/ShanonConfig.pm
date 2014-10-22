package Catalyst::Model::ShanonConfig;

use 5.008002;
use strict;
use warnings;

my ($Revision) = '$Id: ShanonConfig.pm,v 1.2 2006/02/14 04:19:13 shimizu Exp $';
our $VERSION = '0.01';

=head1 NAME

Catalyst::Model::ShanonConfig - Catalyst::Plugin::ClassConfig ��ĥ

=head1 SYNOPSIS

  use base qw(Catalyst::Model::ShanonConfig);
  sub initialize {
    my($self,$c) = @_;
    # do something
  }

=head1 DESCRIPTION

Catalyst::Plugin::ClassConfig ���б��Ǥ��ʤ��������ѡ�
����ȥ���ȥӥ塼�Ϥ��Υ⥸�塼��Υ᥽�åɷ�ͳ�ǥ���ե�����������롣

=head1 METHODS

=head2 initalize

 �������᥽�åɡ�
 ���̽�����᥽�å�
 �����С��饤����

=cut

sub initialize {
    my $self = shift;
    my $c    = shift;

    # do nothing
}

=head2 get_clc

 �������᥽�åɡ�
 ���饹����ե������������
 �����С��饤����

=cut

sub get_clc {
    my $self = shift;
    my $c    = shift;
    return $c->clc($self);
}

=head2 get_view

 �������᥽�åɡ�
 �ӥ塼��̾�����������
 �����С��饤����

=cut

sub get_view {
    my $self = shift;
    my $c    = shift;
    my $view = shift;
    my $type = shift;    # add �Ȥ� delete �Ȥ�

    if ( $self->get_clc($c)->getView() ) {
        $view->[0] = $self->get_clc($c)->getView();
        $view->[1] = $type;
    }
}

=head2 get_model

 �������᥽�åɡ�
 ��ǥ��̾�����������
 �����С��饤����

=cut

sub get_model {
    my $self = shift;
    my $c    = shift;
    return $self->get_clc($c)->getModel();
}

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jun Shimizu, E<lt>shimizu@shanon.co.jpE<gt> and Shanon Inc.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
__END__
