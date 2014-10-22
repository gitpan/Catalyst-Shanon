package Catalyst::Controller::ADVEL::Multi;

use strict;
use warnings;
use base 'Catalyst::Controller::ADVEL';
use Class::Trigger;

use Data::Dumper;

my ($Revision) = '$Id: Multi.pm,v 1.31 2006/02/25 07:44:20 shimizu Exp $';
our $VERSION = '0.01';

=head1 NAME

Catalyst::Controller::ADVEL::Multi - Support Multi Class ADVEL for One Page.

=head1 SYNOPSIS

  package MyApp::Controller::MyMultiController;
  use base 'Catalyst::Controller::ADVEL::Multi';
  

=head1 DESCRIPTION

Stub documentation for Catalyst::Controller::ADVEL::Multi, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 METHODS

=head2 call_multi_action

=cut

sub call_multi_action : Private {
    my $self   = shift;
    my $c      = shift;
    my $action = shift;

    # �ƥ���ȥ���ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    # input => confirm => do_add�� ʣ����ƤӽФ��줿�Ȥ���
    # �ե�����̾������뤫�饯�ꥢ���Ƥ��
    $self->get_clc($c)->clear_form_plus_str();

    # �֤��ͤϥǥե����0
    $c->stash->{'multi_returns'} = 0;

    # ����config->{'multi'}��夫���˲󤷤Ƥ�����
    my @array = $self->call_single_action( $c, $action, $self->get_clc($c)->config->{'multi'}, '' );

    # ����Ū�ˤ���-������Ȼפ����ɡ�����
    # ���顼�����ä����ä������
    if ( ref( $c->stash->{'find_errors'} ) eq 'HASH' ) {
        $self->get_clc($c)->clear_form_plus_str();
        @array = $self->call_single_action( $c, $action, $self->get_clc($c)->config->{'multi'}, '' );
    }
    $self->call_trigger( 'call_multi_action_after_get_array', $c, \@array );

    # �֤äƤ�����̤�ɥɥ�ȤޤȤ��
    $c->stash->{'FORM'}->{'multi'} = join( "\n", @array );

    # �֤��ͤ���פ򥲥åȡ����쥤���쥤
    my $rt = $c->stash->{'multi_returns'};
    delete $c->stash->{'multi_returns'};

    return $rt;
}

=head2 call_single_action

=cut

sub call_single_action : Private {
    my $self         = shift;
    my $c            = shift;
    my $action       = shift;
    my $array        = shift;
    my $base_class   = shift;
    my $parent_class = shift;

    my $parent_model = $c->stash->{'multi_before_model'};
    $c->stash->{'multi_before_model'} = undef;

    my @ary;

    foreach my $line ( @{$array} ) {
        $c->log->info( 'ADVEL::Multi : class = ' . $line->{'class'} . ' : action = ' . $action );

        # config��ref���ʤ��Ƥ��оݤ�config��references���������������
        if ( $parent_class and !( $line->{'ref'} ) ) {
            foreach my $p ( $c->clc( $line->{'class'} )->schema() ) {
                if (    $p->{'sql'}
                    and ref( $p->{'sql'}->{'references'} ) eq 'HASH'
                    and $parent_class                      eq $p->{'sql'}->{'references'}->{'class'} )
                {

                    #		    $c->log->debug($line->{'class'}.' : 3 : '.$p->{'sql'}->{'references'}->{'class'});
                    my $primary_key = $c->clc( $p->{'sql'}->{'references'}->{'class'} )->getModel->primary_column();
                    $line->{'ref'} = [] unless ( $line->{'ref'} );
                    push(
                        @{ $line->{'ref'} },
                        { $p->{'name'} => $p->{'sql'}->{'references'}->{'name'} || $primary_key }
                    );
                }
            }
        }

        my @ids_for_update;

        # input�ǥѥ�᡼��������Ǥ��� �Ĥޤ��retrieve������
        if (    grep( $action eq $_, qw(input preview pre_delete pre_disable) )
            and $c->req->args->[0]
            and $c->req->args->[0] =~ /^\d+$/
            and ref($parent_model) )
        {
            my %where;
            foreach my $ref ( @{ $line->{'ref'} } ) {
                while ( my ( $to, $from ) = each( %{$ref} ) ) {
                    if ( $parent_model->can($from) ) {
                        $where{$to} = [ $parent_model->$from() ];
                    }
                    else {
                        $where{$to} = $from;
                    }
                }
            }
            $self->ids_for_update_main( $c, \%where, $line, \@ids_for_update );

            #	    my $model = $c->clc($line->{'class'})->getModel;
            #	    my $primary = $model->primary_column;
            #    my @data = $model->search_where(\%where, {order_by => "$primary"});
            #	    foreach(@data) {
            #		push(@ids_for_update, $_->$primary);
            #	    }

        }

        for ( my $i = 0; $i < $line->{'count'}; $i++ ) {
            $c->log->info( 'ADVEL::Multi : count = ' . $i );

            # body����ʤ��äƤ����˵ͤ�ơ�
            my $stock_pos = sprintf( 'multi_%s_%d', $line->{'class'}, $i );
            $c->stash->{'set_view_target'} = $stock_pos;
            $c->log->debug( 'ADVEL::Multi : ' . $line->{'class'} . ' : set view to : ' . $stock_pos );

            # �ե�����̾����餻�ʤ������
            $c->clc( $line->{'class'} )->set_form_plus_str( $c->clc( $line->{'class'} )->get_next_plus_str );

            # �����������Class��ͭ�ˤ������ä���_no
            my $old_action = $c->req->param('action');
            $c->log->debug( '$self : action : ' . $self->get_clc($c)->get_namespace . '/' . $action );
            if (    $c->req->param('action')
                and $c->req->param('action') eq $self->get_clc($c)->get_namespace . '/' . $action )
            {
                $c->req->param( 'action', $c->clc( $line->{'class'} )->get_namespace . '/' . $action );
                $c->log->debug(
                    $line->{'class'} . ' : action : ' . $c->clc( $line->{'class'} )->get_namespace . '/' . $action );
            }

            # ��multi�δ�Ϣ�դ��Τ����
            my $plus_req = undef;
            if ( ref( $line->{'ref'} ) eq 'ARRAY' ) {

                # input�ǥѥ�᡼��������Ǥ��� �Ĥޤ��update�ξ��
                if (    grep( $action eq $_, qw(input preview pre_disable pre_delete) )
                    and $c->req->args->[0]
                    and $c->req->args->[0] =~ /^\d+$/
                    and ref($parent_model) )
                {
                    $plus_req = [ $ids_for_update[$i] || '' ];
                }

                # do_add �ξ��
                elsif ( $action eq 'do_add' and ref($parent_model) ) {
                    foreach my $ref ( @{ $line->{'ref'} } ) {
                        while ( my ( $to, $from ) = each( %{$ref} ) ) {

                            # can �Ǥ�����᥽�åɤȤ��Ƽ¹�
                            if ( $parent_model->can($from) ) {
                                $c->log->info( 'ADVEL::Multi : '
                                        . $line->{'class'}
                                        . ' : call_single_action : ref(method) : '
                                        . $parent_model->$from . ' => '
                                        . $to );
                                $c->clc( $line->{'class'} )->set_req_param( $to, $parent_model->$from );
                            }

                            # �Ǥ��ʤ��ä�������Ȥ����ͤù���
                            else {
                                $c->log->info( 'ADVEL::Multi : '
                                        . $line->{'class'}
                                        . ' : call_single_action : ref(static) : '
                                        . "$from => $to" );
                                $c->clc( $line->{'class'} )->set_req_param( $to, $from );
                            }
                        }
                    }
                }
            }

            # ���٤ƤΥƥ�ץ졼�Ȥ�plain�ˤ���
            $c->stash->{ $c->action->name . '_file' } = 'plain';

            # �����Υ�������������
            # action���֤��ͤ���פ���� ����ʤ��ȼ��ʤ����ʤޤʤ��ä���Ǥ��ʤ�
            $c->stash->{'multi_returns'} += $c->forward( $line->{'class'}, $action, $plus_req );

            # �ƥ�ץ졼�Ȥ򸵤��᤹
            delete $c->stash->{ $c->action->name . '_file' };

            # �Ȥä���ǥ���äƤ���
            $c->stash->{'multi_models'} = {} unless ( $c->stash->{'multi_models'} );
            $c->stash->{'multi_models'}->{ $c->clc( $line->{'class'} )->get_namespace } = {};
            $c->stash->{'multi_models'}->{ $c->clc( $line->{'class'} )->get_namespace }
                ->{ $c->clc( $line->{'class'} )->get_form_plus_str } = $c->stash->{'model'};
            $c->stash->{'multi_before_model'} = $c->stash->{'model'};
            $c->stash->{'model'}              = undef;
            $c->stash->{'form_data'}          = undef;

            # ������������ᤵ�ʤ��㡦����
            $c->req->param( 'action', $old_action );

            # ����˷�̤�ͤ�Ƥ���
            push( @ary, $c->stash->{$stock_pos} );

            #	    $c->stash->{'multi_FORM'}->{$stock_pos} = $c->stash->{$stock_pos};
            $c->stash->{'multi_FORM'}->{ sprintf( 'multi_%s%s_%d-', $base_class, $line->{'class'}, $i ) }
                = $c->stash->{$stock_pos};
            delete $c->stash->{$stock_pos};

            # �⤷�Ҷ�������褦���ä��顢�����Ĥ�ƤӽФ��Ƥ��
            push(
                @ary,
                $self->call_single_action(
                    $c, $action, $line->{'child'}, sprintf( '%s%s_%d_', $base_class, $line->{'class'}, $i ),
                    $line->{'class'}
                )
                )
                if ( ref( $line->{'child'} ) eq 'ARRAY' );

            # ����˵ͤޤä���̤�FORM�˵ͤ�Ƥ��ޤ��礦
            $c->stash->{'multi_FORM'}->{ sprintf( 'multi_%s%s_%d', $base_class, $line->{'class'}, $i ) }
                = join( "\n", @ary );
        }
    }

    # ���ֿƤ���θƤӽФ����ä��顢multi_FORM��FORM�˰ܤ��Ƥ��
    if ( length($base_class) < 1 ) {
        $c->stash->{'FORM'} = $c->stash->{'multi_FORM'};
        delete $c->stash->{'multi_FORM'};
    }
    return @ary;

}

=head2 ids_for_update_main

 for override

=cut

sub ids_for_update_main : Private {
    my $self           = shift;
    my $c              = shift;
    my $where          = shift;
    my $line           = shift;
    my $ids_for_update = shift;

    my $model   = $c->clc( $line->{'class'} )->getModel;
    my $primary = $model->primary_column;

    my (@data) = $model->search_where( $where, { order_by => "$primary" } );
    foreach (@data) {
        push( @{$ids_for_update}, $_->$primary );
    }
    $line->{'count'} = scalar @data if ( scalar @data > $line->{'count'} );
}

=head2 input

���ϲ��̤�ɽ�����뤿����������������

�ȥꥬ����

=over 3

=item $self->input_before($c);

=item $self->input_after_gen_first_data($c);

=item $self->input_after($c);

=back

=cut

sub input : Private {
    my $self = shift;
    my $c    = shift;

    # �ǽ������ȥꥬ��
    $self->call_trigger( 'input_before', $c );

    # input�������������ä����Ȥ��Τ餻��
    $c->log->info( 'ADVEL::Multi : ' . ref($self) . ' : input' );

    my $rt = $self->call_multi_action( $c, 'input' );
    return 0 unless ($rt);

    # ���β��̤�ï�������ꤹ��
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );

    # namespace ------------------------------
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/input';
    $self->call_trigger( 'input_after_gen_first_data', $c );

    $c->stash()->{'add_file'} = 'add';
    $c->forward( $self->get_clc($c)->getView, 'input' );

    # �Ǹ������ȥꥬ��
    $self->call_trigger( 'input_after', $c );

    return 1;
}

=head2 confirm

��ǧ���̤�ɽ�����뤿����������������Ǥ���

�ȥꥬ����

=over 2

=item $self->confirm_before($c);

=item $self->confirm_after($c);

=back

=cut

sub confirm : Private {
    my $self = shift;
    my $c    = shift;

    # �ǽ������ȥꥬ��
    $self->call_trigger( 'confirm_before', $c );

    # confirm�������������ä����Ȥ��Τ餻��
    $c->log->info( 'ADVEL::Multi : ' . ref($self) . ' : confirm' );

    my $rt = $self->call_multi_action( $c, 'confirm' );
    return 0 unless ($rt);

    # ���β��̤�ï�������ꤹ��
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );

    # namespace ------------------------------
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/confirm';

    $c->stash()->{'add_file'} = 'add';
    $c->forward( $self->get_clc($c)->getView, 'confirm' );

    # �Ǹ������ȥꥬ��
    $self->call_trigger( 'confirm_after', $c );

    return 1;
}

=head2 do_add

�ºݤ���Ͽ��Ԥ�����λ���̤�ɽ�����뤿����������������

�ȥꥬ����

=over 2

=item $self->do_add_before($c);

=item $self->do_add_after($c, \$commit_flg);

=back

=cut

sub do_add : Private {
    my $self = shift;
    my $c    = shift;

    # �ǽ������ȥꥬ��
    $self->call_trigger( 'do_add_before', $c );

    # do_add�������������ä����Ȥ��Τ餻��
    $c->log->info( 'ADVEL::Multi : ' . ref($self) . ' : do_add' );

    my $rt = $self->call_multi_action( $c, 'do_add' );
    return 0 unless ($rt);

    # ���β��̤�ï�������ꤹ��
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/do_add';

    $c->stash()->{'add_file'} = 'add';
    $c->forward( $self->get_clc($c)->getView, 'do_add' );

    # View�ˤ����Ф���
    my $body = $c->stash->{'FORM'}->{'multi'};
    $body =~ s/��Ͽ��λ���ޤ�����//g;

    #$body .= '��Ͽ��λ���ޤ�����';
    $c->stash->{'body'} .= $body;

    # �Ǹ������ȥꥬ��
    $self->call_trigger( 'do_add_after', $c );

    return 1;
}

=head2 pre_disable

̵�����γ�ǧ���̤�ɽ�����뤿����������������

�ȥꥬ����

=over 3

=item $self->pre_disable_before($c);

=item $self->pre_disable_after_form_data($c);

=item $self->pre_disable_after($c);

=back

=cut

sub pre_disable : Private {
    my $self = shift;
    my $c    = shift;

    # �ǽ������ȥꥬ��
    $self->call_trigger( 'pre_disable_before', $c );

    # pre_disable�������������ä����Ȥ��Τ餻��
    $c->log->info( 'ADVEL::Multi : ' . ref($self) . ' : pre_disable' );

    my $rt = $self->call_multi_action( $c, 'pre_disable' );
    return 0 unless ($rt);

    # ���β��̤�ï�������ꤹ��
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/pre_disable';
    $self->call_trigger( 'pre_disable_after_form_data', $c );

    $c->stash()->{'disable_file'} = 'disable';
    $c->forward( $self->get_clc($c)->getView, 'pre_disable' );

    # �Ǹ������ȥꥬ��
    $self->call_trigger( 'pre_disable_after', $c );

    return 1;
}

=head2 do_disable

�ºݤ�̵������Ԥ�����λ���̤�ɽ�����뤿����������������

�ȥꥬ����

=over 2

=item $self->do_disable_before($c);

=item $self->do_disable_after($c);

=back

=cut

sub do_disable : Private {
    my $self = shift;
    my $c    = shift;

    # �ǽ������ȥꥬ��
    $self->call_trigger( 'do_disable_before', $c );

    # do_disable�������������ä����Ȥ��Τ餻��
    $c->log->info( 'ADVEL::Multi : ' . ref($self) . ' : do_disable' );

    my $rt = $self->call_multi_action( $c, 'do_disable' );
    return 0 unless ($rt);

    # ���β��̤�ï�������ꤹ��
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/do_disable';

    $c->stash()->{'disable_file'} = 'disable';
    $c->forward( $self->get_clc($c)->getView, 'do_disable' );

    # �Ǹ������ȥꥬ��
    $self->call_trigger( 'do_disable_after', $c );

    return 1;
}

=head2 pre_delete

����γ�ǧ���̤�ɽ�����뤿����������������

�ȥꥬ����

=over 3

=item $self->pre_delete_before($c);

=item $self->pre_delete_after_form_data($c);

=item $self->pre_delete_after($c);

=back

=cut

sub pre_delete : Private {
    my $self = shift;
    my $c    = shift;

    # �ǽ������ȥꥬ��
    $self->call_trigger( 'pre_delete_before', $c );

    # pre_delete�������������ä����Ȥ��Τ餻��
    $c->log->info( 'ADVEL::Multi : ' . ref($self) . ' : pre_delete' );

    my $rt = $self->call_multi_action( $c, 'pre_delete' );
    return 0 unless ($rt);

    # ���β��̤�ï�������ꤹ��
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/pre_delete';
    $self->call_trigger( 'pre_delete_after_form_data', $c );

    $c->stash()->{'delete_file'} = 'delete';
    $c->forward( $self->get_clc($c)->getView, 'pre_delete' );

    # �Ǹ������ȥꥬ��
    $self->call_trigger( 'pre_delete_after', $c );

    return 1;
}

=head2 do_delete

�ºݤ˺����Ԥ�����λ���̤�ɽ�����뤿����������������

�ȥꥬ����

=over 2

=item $self->do_delete_before($c);

=item $self->do_delete_after($c);

=back

=cut

sub do_delete : Private {
    my $self = shift;
    my $c    = shift;

    # �ǽ������ȥꥬ��
    $self->call_trigger( 'do_delete_before', $c );

    # do_delete�������������ä����Ȥ��Τ餻��
    $c->log->info( 'ADVEL::Multi : ' . ref($self) . ' : do_delete' );

    my $rt = $self->call_multi_action( $c, 'do_delete' );
    return 0 unless ($rt);

    # ���β��̤�ï�������ꤹ��
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/do_delete';

    $c->stash()->{'delete_file'} = 'delete';
    $c->forward( $self->get_clc($c)->getView, 'do_delete' );

    # �Ǹ������ȥꥬ��
    $self->call_trigger( 'do_delete_after', $c );

    return 1;
}

=head2 preview

��ǧ���̤�ɽ�����뤿����������������

�ȥꥬ����

=over 3

=item $self->preview_before($c);

=item $self->preview_after_form_data($c);

=item $self->preview_after($c);

=back

=cut

sub preview : Private {
    my $self = shift;
    my $c    = shift;

    # �ǽ������ȥꥬ��
    $self->call_trigger( 'preview_before', $c );

    # preview�������������ä����Ȥ��Τ餻��
    $c->log->info( 'ADVEL::Multi : ' . ref($self) . ' : preview' );

    my $rt = $self->call_multi_action( $c, 'preview' );

    return 0 unless ($rt);

    # ���β��̤�ï�������ꤹ��
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/preview';
    $self->call_trigger( 'preview_after_form_data', $c );

    $c->stash()->{'preview_file'} = 'preview';
    $c->log->debug( $self->get_clc($c)->getView, 'preview' );
    $c->forward( $self->get_clc($c)->getView, 'preview' );

    # �Ǹ������ȥꥬ��
    $self->call_trigger( 'preview_after', $c );

    return 1;
}

=head1 SEE ALSO

��Ǥ����ȥɥ�����Ƚ񤫤ʤ���ʤ�

=head1 AUTHOR

Shota Takayama, E<lt>takayama@shanon.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Shota Takayama and Shanon, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
__END__

