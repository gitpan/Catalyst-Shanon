package Catalyst::Controller::ADVEL::Popup;

use strict;
use warnings;

my ($Revision) = '$Id: Popup.pm,v 1.6 2006/02/14 12:36:47 nakamura Exp $';
our $VERSION = '0.01';

use base 'Catalyst::Controller::ADVEL';
use Class::Trigger;
use Data::Dumper;

#------------------------------------------------------------
# 普通の一覧タイプの検索画面を
#
sub popup_slist : Local {
    my $self = shift;
    my $c    = shift;

    # 各コントローラの初期化メソッドを呼ぶ
    $self->initialize($c);
    $c->log->debug('--------------------------- popup_slist にきました');
    $self->call_trigger( 'popup_slist_before', $c );

    my $sortorder = $self->popup_slist_sort($c);
    $self->call_trigger( 'popup_slist_sort_after', $c, \$sortorder );
    $self->get_clc($c)->class_stash->{sortorder} = $sortorder;

    my $where = $self->popup_slist_where($c);
    $self->call_trigger( 'popup_slist_where_after', $c, $where );
    $self->get_clc($c)->class_stash->{where} = $where;

    my ($offset) = '';
    my ($limit)  = '';

    #    $self->set_list_attr($c,\$offset, \$limit);
    #    $self->get_clc($c)->class_stash->{offset} = $offset;
    #    $self->get_clc($c)->class_stash->{limit} = $limit;
    $self->get_clc($c)->class_stash->{model} = $self->get_model($c);

    $self->list_search($c);

    #    $self->list_navigate($c);

    $self->make_meta_row($c);

    # データを取得
    my $data = $self->get_iterators($c);
    $self->get_clc($c)->class_stash->{'popup_slist_data'} = $data;

    #    $self->make_popup_slist($c);

    #    $FORM{'navigate'} = $this->mode_popup_slist_navigate(\%FORM, \$offset, \$limit, \@wheres);

    my @view;
    $self->get_view( $c, \@view, 'popup_slist' );
    $self->call_trigger( 'popup_slist_view', $c, \@view );
    $c->forward(@view);
}

sub make_popup_slist : Private {
    my $self = shift;
    my $c    = shift;

    my $data = $self->get_iterators($c);
    $self->get_clc($c)->class_stash->{'popup_slist_data'} = $data;

    my @view;
    $self->get_view( $c, \@view, 'make_popup_slist' );
    $c->forward(@view);
}

# list のラッパーを作っておく

sub popup_slist_sort {
    my $self = shift;
    return $self->list_sort(@_);
}

sub popup_slist_where {
    my $self = shift;
    return $self->list_where(@_);
}

1;
