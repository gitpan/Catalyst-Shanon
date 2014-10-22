package Catalyst::View::ShanonHTML;

use strict;
use warnings;

use base qw(Catalyst::Base Catalyst::Model::ShanonConfig);
use Class::Trigger;
use CGI qw(:form);
use Jcode;

use Data::Dumper;

our $VERSION = '0.01';

=head1 NAME

Catalyst::View::ShanonHTML - Scaffolding View Component (Add Delete View Edit List)

=head1 SYNOPSIS

  use Catalyst::View::ShanonHTML;
  use base 'Catalyst::View::ShanonHTML';

=head1 DESCRIPTION

����Ū�ʡ���Ͽ�סֺ���ס�ɽ���ס��Խ��סְ����פε�ǽ���󶡤��뤿���
�١������֥������ȡ�

    ���ܤΥ᥽�åɤϲ������̤�ˤʤäƤ��롣
    confirm
    do_add
    do_delete
    do_disable
    input
    list
    list_search
    plain
    pre_delete
    pre_disable
    preview
    
    ���ܤλ�����ˡ�ϥ���ȥ��顼����
    $c->forward('Catalyst::View::User','input');
    
    ����
    1. ���饹̾
    2. �ɤΥ᥽�åɤ�¹Ԥ��뤫����ꤷ�ޤ�

    �Ƽ�ȥꥬ���ϲ������̤�
    
    __PACKAGE__->add_trigger(confirm_before_parse_form => &confirm_before_parse_form);
    __PACKAGE__->add_trigger(confirm_after_parse_form => &confirm_after_parse_form);
    __PACKAGE__->add_trigger(confirm_after_makebutton => &confirm_after_makebutton);
    __PACKAGE__->add_trigger(confirm_after_parse_variable => &confirm_after_parse_variable);
    __PACKAGE__->add_trigger(do_add_after => &do_add_after);
    __PACKAGE__->add_trigger(do_delete_after => &do_delete_after);
    __PACKAGE__->add_trigger(do_disable_after => &do_disable_after);
    __PACKAGE__->add_trigger(input_before_parse_form => &input_before_parse_form);
    __PACKAGE__->add_trigger(input_after_parse_form => &input_after_parse_form);
    __PACKAGE__->add_trigger(input_after_makebutton => &input_after_makebutton);
    __PACKAGE__->add_trigger(input_before_parse_variable_change_file => &input_before_parse_variable_change_file);
    __PACKAGE__->add_trigger(input_before_parse_variable => &input_before_parse_variable);
    __PACKAGE__->add_trigger(input_after_parse_variable => &input_after_parse_variable);
    __PACKAGE__->add_trigger(list_createtable_set_hash_columns => &list_createtable_set_hash_columns);
    __PACKAGE__->add_trigger(before_list_createtable_data_escape => &before_list_createtable_data_escape);
    __PACKAGE__->add_trigger(after_list_createtable_data_escape => &after_list_createtable_data_escape);
    __PACKAGE__->add_trigger(list_before_parse_variable => &list_before_parse_variable);
    __PACKAGE__->add_trigger(list_after_parse_variable => &list_after_parse_variable);
    __PACKAGE__->add_trigger(list_search_before_parse_form => &list_search_before_parse_form);
    __PACKAGE__->add_trigger(list_search_after_parse_form => &list_search_after_parse_form);
    __PACKAGE__->add_trigger(list_search_after_makebutton => &list_search_after_makebutton);
    __PACKAGE__->add_trigger(plain_before_parse_variable => &plain_before_parse_variable);
    __PACKAGE__->add_trigger(plain_after_parse_variable => &plain_after_parse_variable);
    __PACKAGE__->add_trigger(pre_delete_before_parse_form => &pre_delete_before_parse_form);
    __PACKAGE__->add_trigger(pre_delete_after_parse_form => &pre_delete_after_parse_form);
    __PACKAGE__->add_trigger(pre_delete_after_makebutton => &pre_delete_after_makebutton);
    __PACKAGE__->add_trigger(pre_delete_after_parse_variable => &pre_delete_after_parse_variable);
    __PACKAGE__->add_trigger(pre_disable_before_parse_form => &pre_disable_before_parse_form);
    __PACKAGE__->add_trigger(pre_disable_after_parse_form => &pre_disable_after_parse_form);
    __PACKAGE__->add_trigger(pre_disable_after_makebutton => &pre_disable_after_makebutton);
    __PACKAGE__->add_trigger(pre_disable_after_parse_variable => &pre_disable_after_parse_variable);
    __PACKAGE__->add_trigger(preview_before_parse_form => &preview_before_parse_form);
    __PACKAGE__->add_trigger(preview_after_parse_form => &preview_after_parse_form);
    __PACKAGE__->add_trigger(preview_after_parse_variable => &preview_after_parse_variable);
    __PACKAGE__->add_trigger(publish_before_parse_form_footer => &publish_before_parse_form_footer);
    __PACKAGE__->add_trigger(publish_after_parse_form_footer => &publish_after_parse_form_footer);
    __PACKAGE__->add_trigger(publish_before_parse_form_header => &publish_before_parse_form_header);
    __PACKAGE__->add_trigger(publish_after_parse_form_header => &publish_after_parse_form_header);
    __PACKAGE__->add_trigger(list_metarow_add_link_after => &list_metarow_add_link_after);

=cut

#sub new {
#    my $self = shift;
#    my $c    = shift;
#    $self = $self->NEXT::new(@_);
#    my $root   = $c->config->{root};
#
#    return $self;
#}
#sub end : Private {
#    my($self, $c) = @_;
#    $c->log->debug('ShanonHTML end : Private');
#    publish($self,$c);
#}

=head1 METHODS

=head2 process

 �������᥽�åɡ�
 HTML�κǽ�����

=cut

sub process : Private {
    my ( $self, $c ) = @_;
    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : process' );
    my %opt;
    %opt = map { $_ => $c->stash->{'tab'}->$_() } qw(menu_class1 menu_class2) if ( $c->stash->{'tab'} );
    $self->publish( $c, %opt );
    return 1;
}

=head2 terminateTask

 �ڴ��ܥ᥽�åɡ�
 ���顼ɽ��
 $c->stash->{'terminateTask_body'}�˥�å�������ͤ����Ǥ���������

�ȥꥬ����

=over 2

=item $self->call_trigger('before_terminateTask', $c, \%FORM);

=item $self->call_trigger('after_terminateTask',$c);

=back

=cut

sub terminateTask : Private {    #: Local
    my ( $self, $c ) = @_;
    my %FORM;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $self->call_trigger( 'before_terminateTask', $c, \%FORM );
    my $stash_target = 'body';
    $FORM{'body_title'} = $self->get_body_title($c);
    $FORM{'body'}       = $c->stash->{'terminateTask_body'};
    $c->stash->{$stash_target} = $self->parse_variable( $self->read_file( $c, $self->get_terminate_file($c) ), %FORM );
    $self->call_trigger( 'after_terminateTask', $c );
    return 1;
}

#--------------------------------------------------------------------------------------------------------------------------
# list �Τ����ޤ� �Ϥ��ޤ�

=head2 csvdownload

 �ڴ��ܥ᥽�åɡ�
 CVS���������

=cut

sub csvdownload : Private {
    my ( $self, $c ) = @_;
    my %FORM;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : csvdownload' );

    # ɬ�פʥ�������Ϥ���ˤ� ? meta_row
    my (@meta_row) = $self->csvdownload_metarow($c);

    # �����Ȥؤ��б�
    # $self->list_metarow_make_sort($c,\@meta_row);

    # �ڡ������ɤ����������?
    # ����Ū�ϡ������mode_list����Ȥ�������ʤ��Ȥ����ʤ��Ȼפ���

    # �ꥹ�����κ���
    my @table;
    my $it = $c->stash->{'csvdownload_data'};
    while ( my $data = $it->next ) {
        push( @table, $self->csvdownload_createtable( $c, \@meta_row, $data ) );
    }

    my $tableclass = '';

    # �إå����Ĥ���
    unshift( @table, [ map { $_->{'value'} } @meta_row ] );

    $FORM{table} = $self->csv_create_table( $c, \@table, %FORM );

    #---------------------------------------------------------------
    # �������줿HMTL�򥻥åȤ���
    my $stash_target = 'body';
    if ( $c->stash->{set_view_target} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{set_view_target};
    }
    $FORM{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );

    $c->stash->{$stash_target} = Jcode::convert( \$FORM{table}, 'sjis', 'euc' );
    $c->stash->{csvdownload_filename} = $c->action()->namespace();
}

=head2 csvdownload

 �ڴ��ܥ᥽�åɡ�
 CVS����������ѹ�����

=cut

sub csvdownload_metarow : Private {
    my ( $self, $c, @array ) = @_;

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : csvdownload_metarow' );

    unless (@array) {
        foreach my $p ( $c->clc($self)->schema ) {
            next if ( $p->{metarow} eq 'invisible' and $p->{sql}->{notnull} != 1 );
            next if ( exists $p->{temporary} && $p->{temporary} == 1 );
            push(
                @array,
                {   field => $p->{name},
                    value => $p->{desc} || $p->{name}
                }
            );
        }
    }
    return @array;
}

=head2 csvdownload_createtable

 �������᥽�åɡ�
 CVS����������ѥơ��֥���������

=cut

sub csvdownload_createtable : Private {
    my ( $self, $c, $meta_row, $model ) = @_;
    my %hash = $model->toHash;

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : csvdownload_createtable' );

    my (@table);
    for ( my ($j) = 0; $j < scalar @{$meta_row}; $j++ ) {

        my $method = $meta_row->[$j]->{'field'};
        my $schema = $c->clc($self)->schema($method);
        next if $schema->{temporary};
        if ( $model->can($method) && ref( $model->$method ) && $model->$method->can('name') ) {
            $table[$j] = $model->$method->name();
        }
        elsif ( exists $c->stash->{'_attribute_data'}->{ $model->id }->{$method} ) {
            if ( $schema->{'list'} ) {
                my @tmp = ( ref $c->stash->{'_attribute_data'}->{ $model->id }->{$method} eq 'ARRAY' )
                    ? @{ $c->stash->{'_attribute_data'}->{ $model->id }->{$method} }
                    : $c->stash->{'_attribute_data'}->{ $model->id }->{$method};
                my @plus;
                foreach my $bit (@tmp) {
                    my @list = @{ $schema->{'list'} };
                IN: foreach my $item (@list) {
                        if ( $item->{'name'} eq $bit ) {
                            push( @plus, $item->{'desc'} );
                            last IN;
                        }
                    }
                }
                $table[$j] = join( ';', @plus );
            }
            else {
                $table[$j] = $c->stash->{'_attribute_data'}->{ $model->id }->{$method};
            }
        }
        elsif ( $schema->{'list'} ) {
            my @list = @{ $schema->{'list'} };
            foreach my $item (@list) {
                if ( $item->{'name'} eq $hash{$method} ) {
                    $table[$j] = $item->{'desc'};
                    last;
                }
            }
        }
        else {
            $table[$j] = $hash{$method};
        }
    }
    return \@table;
}

=head2 csv_create_table

 �������᥽�åɡ�
 CVS���������������

=cut

sub csv_create_table : Private {
    my ( $self, $c, $table, %FORM ) = @_;
    my $line;
    die 'Not Array row' if ( ref $table ne 'ARRAY' );
    foreach my $p ( @{$table} ) {
        die 'Not Array col' if ( ref $p ne 'ARRAY' );
        $line .= join( ',', $self->csv_escape( $c, @{$p} ) ) . "\r\n";
    }
    return $line;
}

=head2 csv_create_table

 �������᥽�åɡ�
 CVS����������ѥ���������

=cut

sub csv_escape : Private {
    my ($self) = shift;
    my ($c)    = shift;
    my (@arg)  = @_;
    my @return;
    foreach my $word (@arg) {
        unless ($word) {
            push( @return, $word );
            next;
        }
        unless ( $word =~ /[\r\n,"]/ ) {
            push( @return, $word );
            next;
        }
        $word = $self->format_linebreak( $word, "\r\n" );
        $word =~ s/"/""/g;    # "
        $word = qq!"$word"!;
        push( @return, $word );
    }
    return wantarray ? @return : $return[0];
}

=head2 popup_slist_metarow

 �������᥽�åɡ�
 �ݥåץ��åפˡ��Խ��פȡ�����פ��ɲä���

=cut

sub popup_slist_metarow : Private {
    my $self = shift;
    my $c    = shift;
    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : popup_slist_metarow' );
    my @array;
    push( @array,
        { field => "id",     value => "ID" },
        { field => "name",   value => "̾��" },
        { field => "select", value => "����" },
    );
    return @array;
}

=head2 popup_slist_createtable

 �������᥽�åɡ�
 �ݥåץ��åפΥꥹ�Ȥ���������

=cut

sub popup_slist_createtable : Private {
    my ( $self, $c, $meta_row, $model ) = @_;
    my %hash;    # = $model->toHash;

    #    $c->log->debug('ShanonHTML : '.ref($self).' : popup_slist_createtable');
    # toHash �ϻȤ鷺�� $meta_row ���������Ƥ����Τ����ͤ��
    for ( my ($j) = 0; $j < scalar @{$meta_row}; $j++ ) {
        my $field = $meta_row->[$j]->{'field'};
        if ( $model->can($field) ) {
            $hash{$field} = $model->$field;
        }
    }
    %hash = map { $_ => $self->escape_html( $hash{$_} ) } keys %hash;

    # popup ���ѥե������!!
    $hash{'name'}   = $model->name();
    $hash{'select'} = sprintf(
        '<input type="button" name="sel_%d" value="����" class="btn" onClick="javascript: popupSelect(%d);">',
        $hash{'id'}, $hash{'id'} );
    $c->stash->{'popup_setting'}->{selback_values}->{ $hash{'id'} } = $self->generate_js_back_value( $c, \%hash );
    my (@table);
    for ( my ($j) = 0; $j < scalar @{$meta_row}; $j++ ) {
        $table[$j]->{'field'} = $meta_row->[$j]->{'field'};
        $table[$j]->{'value'} = $hash{ $meta_row->[$j]->{'field'} };
        $table[$j]->{'class'} = $meta_row->[$j]->{'class'};
        $table[$j]->{'align'} = 'left' if $j == 1;

        my $name = $meta_row->[$j]->{'field'};
        if (   $name eq '_link_view'
            || $name eq '_link_add'
            || $name eq '_link_disable'
            || $name eq '_link_delete' )
        {
            $name =~ s/^_link_//;
            $table[$j]->{'value'} = sprintf(
                '<a href="%s%s/%s/%d">%s</a>',
                $c->can('get_baseurl') ? $c->get_baseurl() : $c->req->base,
                $self->get_namespace, $name, $hash{id}, $meta_row->[$j]->{'value'}
            );
        }
        else {
            $table[$j]->{'value'} = $hash{ $meta_row->[$j]->{'field'} };
        }
    }
    return \@table;
}

=head2 get_namespace

 �������᥽�åɡ�
 �͡��ॹ�ڡ������������

=cut

sub get_namespace {
    my ( $self, $c ) = @_;
    return $c->namespace();
}

=head2 generate_js_back_value

 �������᥽�åɡ�
 Javascropt����������

=cut

sub generate_js_back_value : Private {
    my $self = shift;
    my $c    = shift;
    my $hash = shift;
    my @data;
    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : generate_js_back_value' );
    foreach ( @{ $c->stash->{'popup_setting'}->{p_settings}->{targ_vals} } ) {
        my %h;
        $h{'type'} = $_->{'type'};
        $h{'name'} = $c->clc( $c->stash->{popup_setting}->{p_settings}->{dist_class} )->get_form_prefix . $_->{'name'};
        $h{'value'} = $hash->{ $_->{'realname'} };    #�����������Ȥ�����á������Ф����Τ���
        push( @data, \%h );
    }
    $c->log->debug('-------------------------- generate_js_back_value��̤Ǥ�');
    $c->log->dumper( \@data );
    return \@data;
}

=head2 popup_slist

 �ڴ��ܥ᥽�åɡ�
 �ݥåץ��åײ��̤���������

=cut

sub popup_slist : Private {
    my ( $self, $c ) = @_;
    my %FORM;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : popup_slist' );
    $self->call_trigger( 'popup_slist_before', $c );

    # Config��������
    $self->load_popup_setting_data($c);

    # �������̺���
    $FORM{'search'} = $c->clc($self)->class_stash->{search};    #$self->list_search($c);

    # ɬ�פʥ�������Ϥ���ˤ� ? meta_row
    my (@meta_row) = $self->popup_slist_metarow($c);

    # �ڡ������ɤ����������?
    # ����Ū�ϡ������mode_list����Ȥ�������ʤ��Ȥ����ʤ��Ȼפ���

    # �ꥹ�����κ���
    my @table;
    my $it
        = $self->get_clc($c)->class_stash->{'popup_slist_data'};  #$c->stash->{'popup_slist_data'};# POPUP�Ѥ����ɤߤȤ�
    while ( my $data = $it->next ) {
        push( @table, $self->popup_slist_createtable( $c, \@meta_row, $data ) );
    }

    my $tableclass = '';

    # �إå����Ĥ���
    unshift(
        @table,
        [   map( {  field => $_->{'field'},
                    value => $_->{'value'},
                    class => $tableclass,
                    width => $_->{'width'},
                    align => $_->{'align'} || undef
                },
                @meta_row )
        ]
    );

    # �Ǥ����ǡ�������Ѥ��ơ��ǡ��������
    $c->stash->{'table_file'} = 'popup_table.html';
    $FORM{table} = $self->html_create_table( $c, \@table );

    #---------------------------------------------------------------
    # �������줿HMTL�򥻥åȤ���
    my $stash_target = 'body';
    if ( $c->stash->{set_view_target} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{set_view_target};
    }
    $FORM{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );

    $self->call_trigger( 'list_before_parse_variable', $c, \%FORM );
    $FORM{'body_title'}         = $self->get_body_title($c);
    $FORM{'body_subtitle'}      = $self->get_body_subtitle($c);
    $c->stash->{'body_message'} = "���Ϥ��������ܤΡ�����פ򥯥�å����Ƥ���������";
    $FORM{'body_message'}       = $self->get_body_message($c);
    $FORM{'dist_class'}         = $c->req->param('dist_class');
    $FORM{'dist_name'}          = $c->req->param('dist_name');

    ## ������ؤ�ǡ��Ĥ��ä���Τ�����
    $FORM{'JSValiable'} .= $self->PVtoJSV(
        $c,
        $c->stash->{popup_setting}->{selback_values},
        $c->stash->{popup_setting}->{js_name_hash},
        'selback_values'
    );
    ## javascript ��Ĥ��äƤ���
    $FORM{'form_name'} = $c->stash->{popup_setting}->{p_settings}->{'form_name'} || 'form1';
    $FORM{'selFunction'} = $self->parse_variable( $self->read_file( $c, $self->get_popup_sel_func_file($c) ), %FORM );

    $c->stash->{$stash_target}
        = $self->parse_variable( $self->read_file( $c, $self->get_popup_slist_file($c) ), %FORM );

    #    $c->log->dumper('---------------------------------����');
    #    $c->log->dumper($c->stash->{$stash_target});

    # POPUP���Ѥ� index file ���ѹ�!!
    $c->stash->{index_file_name} = $self->get_popup_index_file($c);

    $self->call_trigger( 'popup_slist_after_parse_variable', $c, \%FORM );
}

=head2 list

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 ��ǧ���̤���������

=cut

sub list : Private {
    my ( $self, $c ) = @_;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : list' );

    my %FORM;

    # make search
    $FORM{search} = $c->clc($self)->class_stash->{search};

    # make navigation
    $FORM{page_num}  = $c->clc($self)->class_stash->{'page_num'};
    $FORM{page_list} = $c->clc($self)->class_stash->{'page_list'};
    $FORM{navigate}  = $c->clc($self)->class_stash->{navigate};

    # make table
    $FORM{table} = $c->clc($self)->class_stash->{table};

    #---------------------------------------------------------------
    # �������줿HMTL�򥻥åȤ���
    my $stash_target = 'body';
    if ( $c->stash->{set_view_target} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{set_view_target};
    }
    $FORM{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );

    $self->call_trigger( 'list_before_parse_variable', $c, \%FORM );
    $FORM{'body_title'}    = $self->get_body_title($c);
    $FORM{'body_subtitle'} = $self->get_body_subtitle($c);
    $c->stash->{'body_message'} = sprintf( qq!%s�ΰ����Ǥ���!, $FORM{'body_title'} );
    $FORM{'body_message'} = $self->get_body_message($c);

    $c->stash->{$stash_target} = $self->parse_variable( $self->read_file( $c, $self->get_list_file($c) ), %FORM );

    $self->call_trigger( 'list_after_parse_variable', $c, \%FORM );
}

=head2 make_metarow

 �������᥽�åɡ�
 �����ιԤ���

=cut

sub make_metarow {
    my $self = shift;
    my $c    = shift;

    #    $c->log->debug('ShanonHTML : '.ref($self).' : make_metarow');

    # meta row
    my (@meta_row) = $self->list_metarow($c);

    # add sort to meta row
    $self->list_metarow_make_sort( $c, \@meta_row );
    $c->clc($self)->class_stash->{metarow} = \@meta_row;
}

=head2 make_list

 �������᥽�åɡ�
 ��������

=cut

sub make_list {
    my $self = shift;
    my $c    = shift;

    #    $c->log->debug('ShanonHTML : '.ref($self).' : make_list');

    my @table;
    my $it = $c->clc($self)->class_stash->{'list_data'};
    if ( defined $it && $it->can('next') ) {
        $it->reset;
        while ( my $data = $it->next ) {
            push( @table, $self->list_createtable( $c, $data ) );
        }
    }

    # header
    $self->make_list_header( $c, \@table );

    # stash �� 'make_list_stash_name' �����ä��餽���Ȥ�
    if ( exists $c->clc($self)->class_stash->{make_list_stash_name} ) {
        my $stash_name = $c->clc($self)->class_stash->{make_list_stash_name};
        $c->clc($self)->class_stash->{$stash_name} = $self->html_create_table( $c, \@table );
    }
    else {
        $c->clc($self)->class_stash->{table} = $self->html_create_table( $c, \@table );
    }
}

=head2 make_metarow

 �������᥽�åɡ�
 �����Υإå�������

=cut

sub make_list_header {
    my $self  = shift;
    my $c     = shift;
    my $table = shift;
    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : make_list_header' );

    my $tableclass = '';
    my $meta_row   = $c->clc($self)->class_stash->{metarow};
    if ( defined $table ) {
        unshift(
            @{$table},
            [   map( {  field => $_->{'field'},
                        value => $_->{'value'},
                        class => $tableclass,
                        width => $_->{'width'},
                        align => $_->{'align'} || undef
                    },
                    @{$meta_row} )
            ]
        );
    }
}

=head2 list_metarow

 �������᥽�åɡ�
 ������ɽ�����������ꤹ��

=cut

sub list_metarow : Private {
    my ( $self, $c, @array ) = @_;
    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : list_metarow' );

    if ( ref $c->clc($self)->class_stash->{meta_obj} eq 'ARRAY' and @{ $c->clc($self)->class_stash->{meta_obj} } ) {

        # column is selected
        foreach my $i ( @{ $c->clc($self)->class_stash->{meta_obj} } ) {
            push(
                @array,
                {   field => $i->column_name,
                    value => $c->clc($self)->schema( $i->column_name )->{'desc'}
                        || $c->clc($self)->schema( $i->column_name )->{'name'}
                }
            );
        }
    }
    else {
        foreach my $p ( $c->clc($self)->schema ) {
            next unless ( $p->{'metarow'} eq 'default' );
            push(
                @array,
                {   field => $p->{name},
                    value => $p->{desc} || $p->{name}
                }
            );
        }
        push( @array,
            { field => "_link_view",    value => "�ܺ�" },
            { field => "_link_add",     value => "�Խ�" },
            { field => "_link_disable", value => "���" },
        );
    }
    $self->call_trigger( 'list_metarow_add_link_after', $c, \@array );
    return @array;
}

=head2 list_metarow_make_sort

 �������᥽�åɡ�
 �ꥹ�Ȥ��¤��ؤ���Ԥ�

=cut

sub list_metarow_make_sort : Private {
    my ( $self, $c, $meta_row ) = @_;
    no warnings;
    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : list_metarow_make_sort' );

    # �ä����������ɲä��Ƥ���������
    my $hidden = [];
    $self->call_trigger( 'list_metarow_make_sort_add_hidden_field', $c, $hidden );

    my $prefix = $c->clc($self)->get_form_prefix;
    my $data   = $c->clc($self)->req_params( 'order', 'order_item' );

    # ���٤������Ѥ���hidden �ե�����ɤ��������
    my $hidden_field = join(
        '',
        map {
            sprintf( qq!<input type="hidden" name="$prefix%s" value="%s">!,
                $self->escape_html( $_->{name}, $_->{data} ) ),

            } (
            { name => 'order_item', data => $data->{"${prefix}order_item"} },
            { name => 'order',      data => $data->{"${prefix}order"} }
            )
    );

    # �����¤��ؤ��ѤΥ�󥯤�Ĥ���
    foreach my $p ( @{$meta_row} ) {
        next if ( grep { $p->{'field'} eq $_ } qw!_link_view _link_add _link_disable _link_delete! );
        next if ( grep ( $p->{'field'} eq $_, @{$hidden} ) );
        my $item = $p->{'field'};
        if ( defined( $p->{'field'} ) && defined( $data->{'order_item'} ) && $p->{'field'} eq $data->{'order_item'} ) {
            if ( $data->{'order'} eq 'desc' ) {
                $p->{'value'} = sprintf(
                    qq[%s&nbsp;<a href="javascript: document.forms[0].${prefix}order_item.value='%s';;document.forms[0].${prefix}order.value='asc';document.forms[0].submit();">��</a>],
                    $p->{value}, $item, $item );
            }
            else {
                $p->{'value'} = sprintf(
                    qq[%s&nbsp;<a href="javascript: document.forms[0].${prefix}order_item.value='%s';document.forms[0].${prefix}order.value='desc';document.forms[0].submit();">��</a>],
                    $p->{value}, $item, $item );
            }
        }
        else {
            $p->{value} = sprintf(
                qq[%s&nbsp;<a href="javascript: document.forms[0].${prefix}order_item.value='%s';document.forms[0].${prefix}order.value='desc';document.forms[0].submit();">��</a>],
                $p->{value}, $item, $item );
        }

        # ���٤������Ѥ���hidden �ե�����ɤ��������
        $p->{value} .= $hidden_field if ($hidden_field);
        undef $hidden_field;
    }
}

=head2 list_search

 �ڴ��ܥ᥽�åɡ�
 �����ե��������

=cut

sub list_search : Private {
    my ( $self, $c ) = @_;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : list_search' );

    #-----------------------------------------------------
    # get request data
    my $data = $c->clc($self)->req_params();
    delete $c->stash->{'form_data'};
    $data = {} unless ($data);

    #-----------------------------------------------------
    # �ѡ����ե�����(�ե��������������)
    # �������� FORM �� parseform �η�̤���ͥ�褵��롣
    my (%TMP) = ( ref $c->stash->{FORM} eq 'HASH' ) ? %{ $c->stash->{FORM} } : ();
    $self->call_trigger( 'list_search_before_parse_form', $c, $data );
    $c->stash->{list_search_now} = 1;
    $self->parse_form( $c, $data );
    delete $c->stash->{list_search_now};
    my (%FORM) = ( ref $c->stash->{parseform_result} eq 'HASH' ) ? %{ $c->stash->{parseform_result} } : ();
    $FORM{$_} = $TMP{$_} foreach ( keys %TMP );
    $self->call_trigger( 'list_search_after_parse_form', $c, \%FORM );

    #-----------------------------------------------------
    # �ǥե���Ȥǥܥ����ɽ������
    $FORM{submit_search} = submit( -name => "submit_search", -value => '����' );
    $self->call_trigger( 'list_search_after_makebutton', $c, \%FORM );
    $c->clc($self)->class_stash->{search}
        = $self->parse_variable( $self->read_file( $c, $self->get_search_file($c) ), %FORM );

}

=head2 html_create_table

�������᥽�åɡ�
 �ǡ�����¤���Ϥ��Ȥ�����˥ơ��֥����
 ��¤Ū�ˤϢ��ΤȤ���
 [[{value => ''}],
  [{value => ''}]]

=cut

sub html_create_table : Private {
    my ( $self, $c, $table, %FORM ) = @_;
    no warnings;
    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : html_create_table' );
    $table ||= [];
    my ($line);
    if ( defined $table ) {
        for ( my ($i) = 0; $i < @{$table}; $i++ ) {
            next unless $table->[$i];
            $line .= sprintf(
                " <tr>\n%s </tr>\n",
                join(
                    '',
                    map( sprintf(
                            qq[  <td class="%s"%s%s%s%s%s%s%s%s%s%s>%s</td>\n],
                            $_->{'class'} || 'tablebody',
                            $_->{'align'}   && ' align="' . $_->{'align'} . '"',
                            $_->{'valign'}  && ' valign="' . $_->{'valign'} . '"',
                            $_->{'colspan'} && ' colspan="' . $_->{'colspan'} . '"',
                            $_->{'rowspan'} && ' rowspan="' . $_->{'rowspan'} . '"',
                            $_->{'width'}   && ' width="' . $_->{'width'} . '"',
                            $_->{'height'}  && ' height="' . $_->{'height'} . '"',
                            $_->{'style'}   && ' style="' . $_->{'style'} . '"',
                            $_->{'onClick'} && ' onClick="' . $_->{'onClick'} . '"',
                            $_->{'nowrap'}  && ' nowrap',
                            $_->{'opt'}     && " " . $_->{'opt'},
                            $self->blank( $_->{'value'} ) ? '&nbsp;' : $_->{'value'}
                        ),
                        @{ $table->[$i] } )
                )
            );
        }
    }
    $FORM{'table'} = $line;
    $FORM{'width'} = sprintf( ' width="%s"', $FORM{'width'} ) if ( defined( $FORM{'width'} ) );

    # make navigation
    $FORM{page_num}  = $c->clc($self)->class_stash->{'page_num'};
    $FORM{page_list} = $c->clc($self)->class_stash->{'page_list'};
    $FORM{navigate}  = $c->clc($self)->class_stash->{navigate};
    $self->call_trigger( 'html_create_table_before_parse_variable', $c, \%FORM );
    return $self->parse_variable( $self->read_file( $c, $self->get_table_file($c) ), %FORM );
}

=head2 list_createtable

 �������᥽�åɡ�
 �ꥹ�Ȥ���������

=cut

sub list_createtable : Private {
    my ( $self, $c, $model ) = @_;
    no warnings;

    #    $c->log->debug('ShanonHTML : '.ref($self).' : list_createtable');

    my %hash;

    # ɽ�����륫�����ɤ߹���
    $self->get_list_data( $c, \%hash, $model );

    # escape
    $self->escape_list_data( $c, \%hash, $model );

    my (@table);
    my $meta_row = $c->clc($self)->class_stash->{metarow};
    for ( my ($j) = 0; $j < scalar @{$meta_row}; $j++ ) {
        my $name = $meta_row->[$j]->{'field'};
        if ( $name eq '_link_view' || $name eq '_link_add' || $name eq '_link_disable' || $name eq '_link_delete' ) {
            my $tmp = $name;
            $tmp =~ s/^_link_//;
            $hash{$name} = sprintf(
                '<a href="%s%s/%s/%d">%s</a>',
                $c->can('get_baseurl') ? $c->get_baseurl() : $c->req->base,
                $c->namespace(), $tmp, $hash{id}, $meta_row->[$j]->{'value'}
            );
        }
        else {
            my $method = $meta_row->[$j]->{'field'};
            my $schema = $c->clc($self)->schema($method);
            if (   !$schema->{temporary}
                && $model->can($method)
                && ref( $model->$method )
                && $model->$method->can('name') )
            {
                $hash{$name} = $model->$method->name();
            }
            elsif ( $schema->{'list'} ) {
                foreach my $item ( @{ $schema->{'list'} } ) {
                    if ( $item->{'name'} eq $hash{$method} ) {
                        $hash{$name} = $item->{'desc'};
                        last;
                    }
                }
            }
            else {
                $hash{$name} = $hash{$method};
            }
        }

        $self->call_trigger( 'list_createtable_set_value', $c, $meta_row->[$j], \%hash );    # �ͤ��ѹ�����������
        $table[$j]->{'field'} = $meta_row->[$j]->{'field'};
        $table[$j]->{'value'} = $hash{ $meta_row->[$j]->{'field'} };
        $table[$j]->{'class'} = $meta_row->[$j]->{'class'};
        $table[$j]->{'align'} = 'left' if $j == 1;
    }
    return \@table;
}

=head2 get_list_data

 �������᥽�åɡ�

=cut

sub get_list_data : Private {
    my $self  = shift;
    my $c     = shift;
    my $hash  = shift;
    my $model = shift;

    #    $c->log->debug('ShanonHTML : '.ref($self).' : get_list_data');

    $self->call_trigger( 'list_createtable_set_hash_columns', $c );
    if ( $c->stash->{list_createtable_set_hash_columns} ) {
        foreach my $i ( @{ $c->stash->{list_createtable_set_hash_columns} } ) {
            $hash->{$i} = $model->$i() if ( $model->can($i) );
        }
    }
    else {
        %{$hash} = $model->toHash;
    }
}

=head2 escape_list_data

 �������᥽�åɡ�

=cut

sub escape_list_data : Private {
    my $self  = shift;
    my $c     = shift;
    my $hash  = shift;
    my $model = shift;

    #    $c->log->debug('ShanonHTML : '.ref($self).' : escape_list_data');

    $self->call_trigger( 'before_list_createtable_data_escape', $c, $hash, $model );
    %{$hash} = map { $_ => $self->escape_html( $hash->{$_} ) } keys %{$hash};
    $self->call_trigger( 'after_list_createtable_data_escape', $c, $hash, $model );
}

=head2 list_navigate

 �������᥽�åɡ�
 �ڡ��������������

=cut

sub list_navigate : Private {
    my ( $self, $c ) = @_;
    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : list_navigate' );
    $c->clc($self)->class_stash->{'page_num'} = popup_menu(
        -name     => 'page_num',
        -values   => [ 1 .. $self->get_clc($c)->class_stash->{max_page} ],
        -onChange => 'submit()',
        -default  => $c->req->param('page_num') || '',
    );
    my %navi_hash = (
        30  => '30��',
        50  => '50��',
        100 => '100��'
    );
    my @navi_ary = qw(30 50 100);
    $c->clc($self)->class_stash->{'page_list'} = popup_menu(
        -name     => 'limit',
        -values   => \@navi_ary,
        -labels   => \%navi_hash,
        -onChange => 'submit()',
        -default  => $c->req->param('limit')
    );

    $c->clc($self)->class_stash->{navigate} = sprintf(
        "<strong>%d</strong>���<strong>%d</strong>�� (��%s��)",
        $c->clc($self)->class_stash->{start_num},
        $c->clc($self)->class_stash->{end_num},
        $c->clc($self)->class_stash->{max_num},
    );
}

# list �Τ����ޤ� �����
#---------------------------------------------------------------------------------------------------

=head2 plain

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 �ץ졼����̤���������

=cut

sub plain : Private {
    my ( $self, $c ) = @_;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : plain' );

    my %FORM = ( ref $c->stash->{FORM} eq 'HASH' ) ? %{ $c->stash->{FORM} } : ();

    #-----------------------------------------------------
    # �������줿HTML�򥻥åȤ���
    my $stash_target = 'body';
    if ( $c->stash->{set_view_target} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{set_view_target};
    }
    $FORM{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );
    $FORM{'body_title'}    = $self->get_body_title($c);
    $FORM{'body_subtitle'} = $self->get_body_subtitle($c);
    $FORM{'body_message'}  = $self->get_body_message($c);
    $self->call_trigger( 'plain_before_parse_variable', $c, \%FORM );
    $c->stash->{$stash_target} = $self->parse_variable( $self->read_file( $c, $self->get_plain_file($c) ), %FORM );
    $self->call_trigger( 'plain_after_parse_variable', $c, \%FORM );
}

=head2 input

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 ���ϲ��̤���������

=cut

sub input : Private {
    my ( $self, $c ) = @_;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : input' );

#-----------------------------------------------------
# Require Model Object
# my $model= $c->stash->{model} || $c->log->debug("\n\n Can't find Model !. If you can't show values of the Model, you must set Model before here !!\n\n");
# $model ='' unless $model;
    my $data = $c->stash->{'form_data'};
    delete $c->stash->{'form_data'};
    $data = {} unless ($data);

    #-----------------------------------------------------
    # �ѡ����ե�����(�ե��������������)
    #
    # �������� FORM �� parseform �η�̤���ͥ�褵��롣
    my (%TMP) = ( ref $c->stash->{FORM} eq 'HASH' ) ? %{ $c->stash->{FORM} } : ();
    my %opt;
    $opt{'hidden_with_label'} = [qw(id)];
    $self->call_trigger( 'input_before_parse_form', $c, $data, \%opt );
    $self->parse_form( $c, $data, { -hidden_with_label => $opt{'hidden_with_label'}, -hidden => $opt{'hidden'} } );
    my (%FORM) = ( ref $c->stash->{parseform_result} eq 'HASH' ) ? %{ $c->stash->{parseform_result} } : ();
    $FORM{$_} = $TMP{$_} foreach ( keys %TMP );
    $self->call_trigger( 'input_after_parse_form', $c, \%FORM );

    #-----------------------------------------------------
    # appendErrorMessages
    # now nothing to do!!
    #    $c->_check_error_obj->_appendErrorMessages($c,\%FORM);
    $c->ceo($self)->_appendErrorMessages( $c, \%FORM );

    #-----------------------------------------------------
    # �ǥե���Ȥǥܥ����ɽ������
    $FORM{submit} = submit( -name => "submit_base", -value => '����', -class => 'btn' ) unless ( $FORM{submit} );
    $self->call_trigger( 'input_after_makebutton', $c, \%FORM );

    #-----------------------------------------------------
    # �������줿HMTL�򥻥åȤ���
    my $stash_target = 'body';
    if ( $c->stash->{set_view_target} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{set_view_target};
    }
    $FORM{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );
    $FORM{'body_title'}    = $self->get_body_title($c);
    $FORM{'body_subtitle'} = $self->get_body_subtitle($c);
    $c->stash->{'body_message'}
        = sprintf( qq!%s����Ͽ���ޤ����Խ���������פ򥯥�å����Ƥ���������!, $FORM{'body_title'} );
    $FORM{'body_message'} = $self->get_body_message($c);
    my ($line) = $self->read_file( $c, $self->get_add_file($c) );
    $self->call_trigger( 'input_before_parse_variable_change_file', $c, \$line );
    $self->call_trigger( 'input_before_parse_variable',             $c, \%FORM );
    $c->stash->{$stash_target} = $self->parse_variable( $line, %FORM );
    $self->call_trigger( 'input_after_parse_variable', $c, \%FORM );
}

=head2 confirm

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 ��ǧ���̤���������

=cut

sub confirm : Private {
    my ( $self, $c, $opt ) = @_;
    my $data = $c->stash->{'form_data'};
    delete $c->stash->{'form_data'};
    $data = {} unless ($data);

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : confirm' );

    #-----------------------------------------------------
    # �ѡ����ե�����(�ե��������������)
    #
    # �������� FORM �� parseform �η�̤���ͥ�褵��롣
    my (%TMP) = ( ref $c->stash->{FORM} eq 'HASH' ) ? %{ $c->stash->{FORM} } : ();
    $self->call_trigger( 'confirm_before_parse_form', $c, $data );
    $self->parse_form( $c, $data, { -hidden_with_label => 1 } );
    my (%FORM) = ( ref $c->stash->{parseform_result} eq 'HASH' ) ? %{ $c->stash->{parseform_result} } : ();
    $FORM{$_} = $TMP{$_} foreach ( keys %TMP );
    $self->call_trigger( 'confirm_after_parse_form', $c, \%FORM );

    # appendErrorMessages

    # �ǥե���Ȥǥܥ����ɽ������
    $FORM{submit} = submit( -name => "submit_base", -value => '��Ͽ', -class => 'btn' );
    $self->call_trigger( 'confirm_after_makebutton', $c, \%FORM );

    # �������줿HMTL�򥻥åȤ���
    my $stash_target = 'body';
    if ( $c->stash->{'set_view_target'} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{'set_view_target'};
    }
    $FORM{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );
    $FORM{'body_title'}         = $self->get_body_title($c);
    $FORM{'body_subtitle'}      = $self->get_body_subtitle($c);
    $c->stash->{'body_message'} = "�������С���Ͽ�פ򥯥�å����Ƥ���������";
    $FORM{'body_message'}       = $self->get_body_message($c);
    my ($line) = $self->read_file( $c, $self->get_add_file($c) );
    $self->call_trigger( 'confirm_before_parse_variable_change_file', $c, \$line );
    $c->stash->{$stash_target} = $self->parse_variable( $line, %FORM );
    $self->call_trigger( 'confirm_after_parse_variable', $c, \%FORM );
}

=head2 do_add

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 ��Ͽ��λ���̤���������

=cut

sub do_add : Private {
    my ( $self, $c ) = @_;
    my $stash_target = 'body';

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : do_add' );

    if ( $c->stash->{'set_view_target'} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{'set_view_target'};
    }

    #$c->stash->{$stash_target} = '��Ͽ��λ���ޤ�����';
    $c->stash->{$stash_target} = hidden(
        -name  => $c->clc($self)->get_form_prefix . 'id',
        -value => $c->stash->{'model'}->id
        )
        if defined( $c->stash->{'model'} ) && $c->stash->{'model'}->can('id');
    unless ( $c->stash->{onload} =~ /alert\(\'��Ͽ��λ���ޤ�����\'\)/ ) {
        $c->stash->{onload} .= sprintf( qq!alert('��Ͽ��λ���ޤ�����');window.location='%s';!,
            join( '/', '', $c->action->namespace, 'list' ) )
            unless $self->get_clc($c)->req_param('return_path');
        $c->stash->{onload} .= sprintf( qq!alert('��Ͽ��λ���ޤ�����');window.location='%s';!,
            $self->get_clc($c)->req_param('return_path') )
            if $self->get_clc($c)->req_param('return_path');
    }
    $self->call_trigger( 'do_add_after', $c );
    $c->stash->{$stash_target} = $c->stash->{'do_add_file'} if ( $c->stash->{'do_add_file'} );
}

=head2 preview

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 �ץ�ӥ塼���̤���������

=cut

sub preview : Private {
    my ( $self, $c ) = @_;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : preview' );

    # �ץ�ӥ塼�Ǥ� prefix suffix �򤱤�
    foreach ( $c->clc($self)->schema() ) {
        delete $_->{form}->{prefix} if exists $_->{form}->{prefix};
        delete $_->{form}->{suffix} if exists $_->{form}->{suffix};
    }

    #-----------------------------------------------------
    # Require Model Object
    my $data = $c->stash->{'form_data'};
    delete $c->stash->{'form_data'};
    $data = {} unless ($data);

    #-----------------------------------------------------
    # �ѡ����ե�����(�ե��������������)
    #
    # �������� FORM �� parseform �η�̤���ͥ�褵��롣
    my (%TMP) = ( ref $c->stash->{FORM} eq 'HASH' ) ? %{ $c->stash->{FORM} } : ();
    my %opt;
    $opt{'-hidden_with_label'} = 1;
    $self->call_trigger( 'preview_before_parse_form', $c, $data, \%opt );
    $self->parse_form( $c, $data, \%opt );

    my (%FORM) = ( ref $c->stash->{parseform_result} eq 'HASH' ) ? %{ $c->stash->{parseform_result} } : ();

    $FORM{$_} = $TMP{$_} foreach ( keys %TMP );
    $self->call_trigger( 'preview_after_parse_form', $c, \%FORM, $data );

    # �������줿HMTL�򥻥åȤ���
    my $stash_target = 'body';
    if ( $c->stash->{'set_view_target'} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{'set_view_target'};
    }
    $FORM{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );
    $FORM{'body_title'}    = $self->get_body_title($c);
    $FORM{'body_subtitle'} = $self->get_body_subtitle($c);
    $c->stash->{'body_message'} = sprintf( qq!%s�ξܺ٤Ǥ���!, $FORM{'body_title'} );
    $FORM{'body_message'} = $self->get_body_message($c);
    my ($line) = $self->read_file( $c, $self->get_preview_file($c) );
    $self->call_trigger( 'preview_before_parse_variable_change_file', $c, \$line );
    $self->call_trigger( 'preview_before_parse_variable',             $c, \%FORM );
    $c->stash->{$stash_target} = $self->parse_variable( $line, %FORM );
    $self->call_trigger( 'preview_after_parse_variable', $c, \%FORM );
}

=head2 pre_delete

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 �����ǧ���̤���������

=cut

sub pre_delete : Private {
    my ( $self, $c ) = @_;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : pre_delete' );

    #-----------------------------------------------------
    # Require Model Object
    my $data = $c->stash->{'form_data'};
    delete $c->stash->{'form_data'};
    $data = {} unless ($data);

    #-----------------------------------------------------
    # �ѡ����ե�����(�ե��������������)
    #
    # �������� FORM �� parseform �η�̤���ͥ�褵��롣
    my (%TMP) = ( ref $c->stash->{FORM} eq 'HASH' ) ? %{ $c->stash->{FORM} } : ();
    $self->call_trigger( 'pre_delete_before_parse_form', $c, $data );
    $self->parse_form( $c, $data, { -hidden_with_label => 1 } );
    my (%FORM) = ( ref $c->stash->{parseform_result} eq 'HASH' ) ? %{ $c->stash->{parseform_result} } : ();
    $FORM{$_} = $TMP{$_} foreach ( keys %TMP );
    $self->call_trigger( 'pre_delete_after_parse_form', $c, \%FORM );

    # appendErrorMessages

    $FORM{submit} = submit( -name => "submit_base", -value => '���', -class => 'btn' );
    $self->call_trigger( 'pre_delete_after_makebutton', $c, \%FORM );

    # �������줿HMTL�򥻥åȤ���
    my $stash_target = 'body';
    if ( $c->stash->{'set_view_target'} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{'set_view_target'};
    }
    $FORM{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );
    $FORM{'body_title'}         = $self->get_body_title($c);
    $FORM{'body_subtitle'}      = $self->get_body_subtitle($c);
    $c->stash->{'body_message'} = "������ޤ����������Сֺ���פ򥯥�å����Ƥ���������";
    $FORM{'body_message'}       = $self->get_body_message($c);
    $c->stash->{$stash_target} = $self->parse_variable( $self->read_file( $c, $self->get_delete_file($c) ), %FORM );
    $self->call_trigger( 'pre_delete_after_parse_variable', $c, \%FORM );
}

=head2 do_delete

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 �����λ���̤���������

=cut

sub do_delete : Private {
    my ( $self, $c ) = @_;
    my $stash_target = 'body';

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : do_delete' );

    if ( $c->stash->{'set_view_target'} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{'set_view_target'};
    }

    #$c->stash->{$stash_target} = '�����λ���ޤ�����';
    unless ( $c->stash->{onload} =~ /alert\(\'�����λ���ޤ�����\'\)/ ) {
        $c->stash->{onload} .= sprintf( qq!alert('�����λ���ޤ�����');window.location='%s';!,
            join( '/', '', $c->action->namespace, 'list' ) )
            unless $self->get_clc($c)->req_param('return_path');
        $c->stash->{onload} .= sprintf( qq!alert('�����λ���ޤ�����');window.location='%s';!,
            $self->get_clc($c)->req_param('return_path') )
            if $self->get_clc($c)->req_param('return_path');
    }
    my $tmp = $self->call_trigger( 'do_delete_after', $c );
    $c->stash->{$stash_target} = $tmp if ($tmp);
}

=head2 pre_disable

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 �����ǧ���̤���������

=cut

sub pre_disable : Private {
    my ( $self, $c ) = @_;

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : pre_disable' );

    #-----------------------------------------------------
    # Require Model Object
    my $data = $c->stash->{'form_data'};
    delete $c->stash->{'form_data'};
    $data = {} unless ($data);

    #-----------------------------------------------------
    # �ѡ����ե�����(�ե��������������)
    #
    # �������� FORM �� parseform �η�̤���ͥ�褵��롣
    my (%TMP) = ( ref $c->stash->{FORM} eq 'HASH' ) ? %{ $c->stash->{FORM} } : ();
    $self->call_trigger( 'pre_disable_before_parse_form', $c, $data );
    $self->parse_form( $c, $data, { -hidden_with_label => 1 } );
    my (%FORM) = ( ref $c->stash->{parseform_result} eq 'HASH' ) ? %{ $c->stash->{parseform_result} } : ();
    $FORM{$_} = $TMP{$_} foreach ( keys %TMP );
    $self->call_trigger( 'pre_disable_after_parse_form', $c, \%FORM );

    $FORM{submit} = submit( -name => "submit_base", -value => '���', -class => 'btn' );
    $self->call_trigger( 'pre_disable_after_makebutton', $c, \%FORM );

    # �������줿HMTL�򥻥åȤ���
    my $stash_target = 'body';
    if ( $c->stash->{'set_view_target'} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{'set_view_target'};
    }
    $FORM{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );
    $FORM{'body_title'}         = $self->get_body_title($c);
    $FORM{'body_subtitle'}      = $self->get_body_subtitle($c);
    $c->stash->{'body_message'} = "������ޤ����������Сֺ���פ򥯥�å����Ƥ���������";
    $FORM{'body_message'}       = $self->get_body_message($c);
    my $line = $self->read_file( $c, $self->get_disable_file($c) );
    $self->call_trigger( 'pre_disable_before_parse_variable_change_file', $c, \$line );
    $self->call_trigger( 'pre_disable_before_parse_variable',             $c, \%FORM );
    $c->stash->{$stash_target} = $self->parse_variable( $line, %FORM );
    $self->call_trigger( 'pre_disable_after_parse_variable', $c, \%FORM );
}

=head2 do_disable

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 �����λ���̤���������

=cut

sub do_disable : Private {
    my ( $self, $c ) = @_;
    my $stash_target = 'body';

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : do_disable' );
    if ( $c->stash->{'set_view_target'} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{'set_view_target'};
    }

    #$c->stash->{$stash_target} = '�����λ���ޤ�����';
    unless ( $c->stash->{onload} =~ /alert\(\'�����λ���ޤ�����\'\)/ ) {
        $c->stash->{onload} .= sprintf( qq!alert('�����λ���ޤ�����');window.location='%s';!,
            join( '/', '', $c->action->namespace, 'list' ) )
            unless $self->get_clc($c)->req_param('return_path');
        $c->stash->{onload} .= sprintf( qq!alert('�����λ���ޤ�����');window.location='%s';!,
            $self->get_clc($c)->req_param('return_path') )
            if $self->get_clc($c)->req_param('return_path');
    }
    my $tmp = $self->call_trigger( 'do_disable_after', $c );
    $c->stash->{$stash_target} = $tmp if ($tmp);
}

=head2 do_csvupload

 �ڴ��ܥ᥽�åɡ�
 $c->stash()->{'set_view_target'} ���������Ƥ����顢������������̤�HTML������
 ��Ͽ��λ���̤���������

=cut

sub do_csvupload : Private {
    my ( $self, $c ) = @_;
    my $stash_target = 'body';

    # �ƥӥ塼�ν�����᥽�åɤ�Ƥ�
    $self->initialize($c);

    $c->log->debug( 'ShanonHTML : ' . ref($self) . ' : do_csvupload' );
    if ( $c->stash->{'set_view_target'} ) {
        $stash_target = $c->stash->{'set_view_target'};
        delete $c->stash->{'set_view_target'};
    }
    if ( exists $c->stash->{do_csvupload_error} && scalar @{ $c->stash->{do_csvupload_error} } ) {

        # ���顼��å�����Ϣ��
        $c->stash->{$stash_target}
            = sprintf( qq!<span class="errorMsg">%s</span>!, join( "<br>\n", @{ $c->stash->{do_csvupload_error} } ) );

        # ���顼�ܺ�ɽ��
        if ( exists $c->stash->{do_csvupload_table} && scalar @{ $c->stash->{do_csvupload_table} } ) {
            my @table      = @{ $c->stash->{do_csvupload_table} };
            my @line_error = @{ $c->stash->{do_csvupload_line_error} };
            my $line       = '<br><br><table border="1">';
            $line .= "<tr>\n";
            $line .= sprintf( qq!<th>�Կ�:%d%s</th>!,
                1,
                length( $line_error[1] ) ? sprintf( qq!<br><span class="errorMsg">%s</span>!, $line_error[1] ) : '' );
            for my $j ( 0 ... $#{ $table[1] } ) {
                $line .= sprintf( "<th>%s</th>", $table[1][$j] );
            }
            $line .= "</tr>\n";
            for my $i ( 2 .. $#table ) {
                $line .= "<tr>\n";
                $line .= sprintf( qq!<th>�Կ�:%d%s</th>!,
                    $i,
                    length( $line_error[$i] )
                    ? sprintf( qq!<br><span class="errorMsg">%s</span>!, $line_error[$i] )
                    : '' );
                for my $j ( 0 ... $#{ $table[$i] } ) {
                    $line .= sprintf( "<td>%s</td>", $table[$i][$j] );
                }
                $line .= "</tr>\n";
            }
            $line                      .= "</table>";
            $c->stash->{$stash_target} .= $line;
        }
    }
    elsif ( exists $c->stash->{do_csvupload_message} && scalar @{ $c->stash->{do_csvupload_message} } ) {

        # �̾��å�����Ϣ��
        $c->stash->{$stash_target} = join( "<br>\n", @{ $c->stash->{do_csvupload_message} } );
        unless ( $c->stash->{onload} =~ /alert\(\'��Ͽ��λ���ޤ�����\'\)/ ) {
            $c->stash->{onload} .= sprintf( qq!alert('��Ͽ��λ���ޤ�����');window.location='%s';!,
                join( '/', '', $c->action->namespace, 'list' ) );
        }
    }
    else {

        #$c->stash->{$stash_target} = '��Ͽ��λ���ޤ�����';
        unless ( $c->stash->{onload} =~ /alert\(\'��Ͽ��λ���ޤ�����\'\)/ ) {
            $c->stash->{onload} .= sprintf( qq!alert('��Ͽ��λ���ޤ�����');window.location='%s';!,
                join( '/', '', $c->action->namespace, 'list' ) );
        }
    }
    my $tmp = $self->call_trigger( 'do_csvupload_after', $c );
    $c->stash->{$stash_target} = $tmp if ($tmp);
}

=head2 get_body_title

 �������᥽�åɡ�
 $c->stash()->{'body_title'} ���������Ƥ����餽����֤�
 �������Ƥ��ʤ��ä��饳��ե����� 'title' ���֤�
 �����ȥ���������

=cut

sub get_body_title : Private {
    my ( $self, $c ) = @_;
    return $c->stash->{'body_title'} ? ( $c->stash->{'body_title'} ) : $c->clc($self)->config()->{title};
}

=head2 get_body_subtitle

 �������᥽�åɡ�
 $c->stash()->{'body_subtitle'} ���������Ƥ����餽����֤�
 �������Ƥ��ʤ��ä��� '�ۡ���' ���֤�
 ���֥����ȥ���������

=cut

sub get_body_subtitle : Private {
    my ( $self, $c ) = @_;
    return $c->stash->{'body_subtitle'} ? ( $c->stash->{'body_subtitle'} ) : '��';
}

=head2 get_body_message

 �������᥽�åɡ�
 $c->stash()->{'body_message'} ���������Ƥ����餽����֤�
 �������Ƥ��ʤ��ä���~ʸ�����֤�
 ��ʸ��Ƭ��å��������������

=cut

sub get_body_message : Private {
    my ( $self, $c ) = @_;
    return $c->stash->{'body_message'}
        ? sprintf( qq!<div class="bOverviewSearch">%s</div>!, $c->stash->{'body_message'} )
        : '';
}

=head2 get_plain_file

 �������᥽�åɡ�
 $c->stash()->{'plain_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 �ץ졼����̤Υե�������������

=cut

sub get_plain_file : Private {
    my ( $self, $c ) = @_;
    return $self->get_my_file( $c, $c->stash->{"plain_file"} ) if ( $c->stash->{"plain_file"} );
    return $self->get_my_file( $c, 'plain' );
}

=head2 get_add_file

 �������᥽�åɡ�
 $c->stash()->{'add_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 �ɲò��̤Υե�������������

=cut

sub get_add_file : Private {
    my $self = shift;
    my $c    = shift;
    return $self->get_my_file( $c, $c->stash->{"add_file"} ) if ( $c->stash->{"add_file"} );
    return $self->get_my_file( $c, 'add' );
}

=head2 get_delete_file

 �������᥽�åɡ�
 $c->stash()->{'delete_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 �����ǧ���̤Υե�������������

=cut

sub get_delete_file : Private {
    my $self = shift;
    my $c    = shift;
    return $self->get_my_file( $c, $c->stash->{"delete_file"} ) if ( $c->stash->{"delete_file"} );
    return $self->get_my_file( $c, 'delete' );
}

=head2 get_disable_file

 �������᥽�åɡ�
 $c->stash()->{'disable_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 �����ǧ���̤Υե�������������

=cut

sub get_disable_file : Private {
    my $self = shift;
    my $c    = shift;
    return $self->get_my_file( $c, $c->stash->{"disable_file"} ) if ( $c->stash->{"disable_file"} );
    return $self->get_my_file( $c, 'disable' );
}

=head2 get_disable_file

 �������᥽�åɡ�
 $c->stash()->{'view_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 �ץ�ӥ塼���̤Υե�������������

=cut

sub get_preview_file : Private {
    my $self = shift;
    my $c    = shift;
    return $self->get_my_file( $c, $c->stash->{"view_file"} ) if ( $c->stash->{"view_file"} );
    return $self->get_my_file( $c, 'view' );
}

=head2 get_popup_slist_file

 �������᥽�åɡ�
 $c->stash()->{'popup_slist_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 �ݥåץ��åײ��̤Υե�������������

=cut

sub get_popup_slist_file : Private {
    my $self = shift;
    my $c    = shift;
    return $self->get_my_file( $c, $c->stash->{"popup_slist_file"} ) if ( $c->stash->{"popup_slist_file"} );
    return $self->get_my_file( $c, 'popup_slist' );
}

=head2 get_search_file

 �������᥽�åɡ�
 $c->stash()->{'search_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 �������̤Υե�������������

=cut

sub get_search_file : Private {
    my $self = shift;
    my $c    = shift;
    return $self->get_my_file( $c, $c->stash->{"search_file"} ) if ( $c->stash->{"search_file"} );
    return $self->get_my_file( $c, 'search' );
}

=head2 get_list_file

 �������᥽�åɡ�
 $c->stash()->{'list_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 �ꥹ�Ȳ��̤Υե�������������

=cut

sub get_list_file : Private {
    my $self = shift;
    my $c    = shift;
    return $self->get_my_file( $c, $c->stash->{"list_file"} ) if ( $c->stash->{"list_file"} );
    return $self->get_my_file( $c, 'list' );
}

=head2 get_template_prefix

 �������᥽�åɡ�
 �ƥ�ץ졼�ȤΥץ�ե��å������������

=cut

sub get_template_prefix : Private {
    my ( $self, $c ) = @_;
    my $appname   = $c->config->{'name'};
    my $classname = ref($self) ? ref($self) : $self;
    my $namespace = $classname;
    $namespace =~ s/^$appname//;
    $namespace =~ s/^\:\:(Controller|Model|View|[CMV])\:\://;
    my (@bit) = split( '::', $namespace );
    return $bit[0];
}

=head2 get_my_file

 �������᥽�åɡ�
 ɬ�פʥƥ�ץ졼�ȥե�����򳫤�

=cut

sub get_my_file : Private {
    my ( $self, $c, $type ) = @_;
    my $prefix = $self->get_template_prefix($c);
    die "Can't find file type [add/delete/preview .. etc]" unless $type;
    my $namespace_path = $self->get_clc($c)->get_namespace();
    $namespace_path =~ s/::/\//g;
    my $file;
    if ( defined $c->stash->{'get_my_file_path'} ) {
        die 'can not find file ' . sprintf( '%s/%s.html', $c->stash->{'get_my_file_path'}, $type )
            unless ( -e sprintf( '%s/%s.html', $c->stash->{'get_my_file_path'}, $type ) );
        $file = sprintf( '%s/%s.html', $c->stash->{'get_my_file_path'}, $type );
    }
    else {
        $file = $c->config()->{root}
            . "/template/$prefix/"
            . ( $c->clc($self)->config()->{class_template_path} || $namespace_path )
            . "/$type.html";
    }
    $c->log->debug("file : $file");
    return $file;
}

=head2 get_index_file

 �������᥽�åɡ�
 index.html ���������

=cut

sub get_index_file : Private {
    my ( $self, $c ) = @_;
    my $prefix = $self->get_template_prefix($c);
    return $c->config()->{root} . sprintf( "/template/%s/%s", $prefix, $c->stash->{"index_file"} )
        if ( $c->stash->{"index_file"} );
    return $c->config()->{root} . sprintf( "/template/%s/index.html", $prefix );
}

=head2 get_popup_index_file

 �������᥽�åɡ�
 popup_index.html ���������

=cut

sub get_popup_index_file : Private {
    my ( $self, $c ) = @_;
    my $prefix = $self->get_template_prefix($c);
    return $c->config()->{root} . sprintf( "/template/%s/%s", $prefix, $c->stash->{"popup_index_file"} )
        if ( $c->stash->{"popup_index_file"} );
    return $c->config()->{root} . sprintf( "/template/%s/popup_index.html", $prefix );
}

=head2 get_popup_file

 �������᥽�åɡ�
 popup_func.js ���������

=cut

sub get_popup_file : Private {
    my ( $self, $c ) = @_;
    my $prefix = $self->get_template_prefix($c);
    return $c->config()->{root} . "/template/$prefix/popup_func.js";
}

=head2 get_popup_sel_func_file

 �������᥽�åɡ�
 popup_sel_func.js ���������

=cut

sub get_popup_sel_func_file : Private {
    my ( $self, $c ) = @_;
    my $prefix = $self->get_template_prefix($c);
    return $c->config()->{root} . "/template/$prefix/popup_sel_func.js";
}

=head2 get_table_file

 �������᥽�åɡ�
 $c->stash()->{'table_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 table.html ���������

=cut

sub get_table_file : Private {
    my ( $self, $c ) = @_;
    my $prefix = $self->get_template_prefix($c);

    my $file;
    unless ( defined $c->stash->{"table_file"} ) {
        $file = $self->get_my_file( $c, 'table' );
        unless ( -e $file ) {
            $file = $c->config()->{root} . sprintf( "/template/%s/table.html", $prefix );
        }
    }
    else {
        $file = $c->config()->{root} . sprintf( "/template/%s/%s", $prefix, $c->stash->{"table_file"} );
    }
    return $file;
}

=head2 get_header_file

 �������᥽�åɡ�
 $c->stash()->{'header_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 header.html ���������

=cut

sub get_header_file : Private {
    my ( $self, $c ) = @_;
    my $prefix = $self->get_template_prefix($c);
    return $c->config()->{root} . sprintf( "/template/%s/%s", $prefix, $c->stash->{"header_file"} )
        if ( $c->stash->{"header_file"} );
    return $c->config()->{root} . sprintf( "/template/%s/header.html", $prefix );
}

=head2 get_footer_file

 �������᥽�åɡ�
 $c->stash()->{'footer_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 footer.html ���������

=cut

sub get_footer_file : Private {
    my ( $self, $c ) = @_;
    my $prefix = $self->get_template_prefix($c);
    return $c->config()->{root} . sprintf( "/template/%s/%s", $prefix, $c->stash->{"footer_file"} )
        if ( $c->stash->{"footer_file"} );
    return $c->config()->{root} . sprintf( "/template/%s/footer.html", $prefix );
}

=head2 get_terminate_file

 �������᥽�åɡ�
 $c->stash()->{'terminate_file'} ���������Ƥ����顢���Υե�������ɤ߹���
 terminate.html ���������

=cut

sub get_terminate_file : Private {
    my ( $self, $c ) = @_;
    my $prefix = $self->get_template_prefix($c);
    return $c->config()->{root} . sprintf( "/template/%s/%s", $prefix, $c->stash->{"terminate_file"} )
        if ( $c->stash->{"terminate_file"} );
    return $c->config()->{root} . sprintf( "/template/%s/terminate.html", $prefix );
}

=head2 publish

 �������᥽�åɡ�
 �ǽ�Ū��HTML���̤���������

=cut

sub publish : Private {
    my ( $self, $c, %opt ) = @_;
    $c->log->debug('publish Page!!');
    $opt{body}       = $c->stash->{body};
    $opt{onload}     = $c->stash->{onload};
    $opt{javascript} = $c->stash->{javascript};

    #----------------------------------------------------------------
    # �إå���
    $self->call_trigger( 'publish_before_parse_form_header', $c, \%opt );
    $opt{header} = $self->parse_variable( $self->read_file( $c, $self->get_header_file($c) ), %opt );
    $self->call_trigger( 'publish_after_parse_form_header', $c, \%opt );

    #----------------------------------------------------------------
    # �եå���
    $self->call_trigger( 'publish_before_parse_form_footer', $c, \%opt );
    $opt{footer} = $self->parse_variable( $self->read_file( $c, $self->get_footer_file($c) ), %opt );
    $self->call_trigger( 'publish_after_parse_form_footer', $c, \%opt );

    $opt{'__baseurl__'} ||= $c->get_baseurl() if ( $c->can('get_baseurl') );
    $opt{'title'} = $c->clc($self)->config()->{title};
    $c->response->header( 'Content-Type' => 'text/html; charset=euc-jp' );
    my $index_file_name = $c->stash->{index_file_name} || $self->get_index_file($c);
    $c->response->body( $self->parse_variable( $self->read_file( $c, $index_file_name ), %opt ) );
}

=head2 read_file

 �������᥽�åɡ�
 �ե�������ɤ߹���

=cut

sub read_file : Private {
    my ( $self, $c, $file, %opt ) = @_;
    my ($line);
    die("Can't find file that is $file.") unless -e $file;
    local (*FILE);
    open( FILE, $file ) or die("Can't open file $file");
    {
        local $/;
        $line = <FILE>;
    }
    close(FILE);
    my $root = $c->config()->{root};
    $file =~ s/$root//;
    $line .= sprintf( "<!-- file : %s -->", $file );
    return $line;
}

=head2 parse_variable

 �������᥽�åɡ�
 $FORM���ͤ�ͤ��

=cut

sub parse_variable : Private {
    my ( $self, $line, %FORM ) = @_;
    return '' unless length($line);
    return $line if index( $line, '$FORM' ) < $[;

    # ------------------------------------------------------------------------------
    # �����ǰ��ä����ơ�Controller/ChangeLog.pm ����Ͽ���Ƥ��ޤ�
    # �������̤뤴�Ȥ˥ե������1�Ĥ��ĺ��
    #      if($line =~ /\<\!-- file : (.*) --\>/){
    #  	my $file = $1;
    #  	$file =~ s/\/\//\//;
    #  	my $file_type = $file =~ /seminar_base/ ? 1 : 2;
    #  	my %tmp = (type => $file_type,
    #  		   name => $file,
    #  		   valiable => [keys %FORM]);
    #  	my $string = Dumper \%tmp;

    #  	my $dir = '/home/inoue/public_html/cvshome/SS_for_EE/SS/script/visitor_tmpl';
    #  	use File::Find::Iterator;
    #  	my $find = File::Find::Iterator->create(dir => [$dir]);
    #  	my @file;
    #  	while (my $f = $find->next){
    #  	    push(@file, $f);
    #  	}
    #  	my $val_file = sprintf('%s/%d', $dir, scalar @file + 1);
    #  	open IN, ">$val_file";
    #  	print IN $string;
    #  	close IN;
    #      }
    # -----------------------------------------------------------------------------

    $FORM{'__now__'} ||= time();
    if ( defined( $FORM{'-strict'} ) ) {
        my ($key);
        foreach $key ( grep( substr( $_, 0, 1 ) ne '-', keys(%FORM) ) ) {
            if ( index( $line, $key ) >= $[ ) {
                $line =~ s/\$FORM{'$key'}/$FORM{$key}/ig;
                next;
            }
            else {
                last if index( $line, '$FORM' ) < $[;
            }
        }
    }
    else {
        no warnings;
        $line =~ s/\$FORM{'([^']+)'}/$FORM{$1}/ig if index( $line, '$FORM' ) >= $[;
        $line =~ s/\$FORM{"([^"]+)"}/$FORM{$1}/ig if index( $line, '$FORM' ) >= $[;    #"
        $line =~ s/\$FORM{(.*?)}/$FORM{$1}/ig     if index( $line, '$FORM' ) >= $[;    #'}
    }
    return $line;
}

=head2 parse_form

 �������᥽�åɡ�
 ����ե������ɤ߹���ǥե������ư��������

=cut

sub parse_form : Private {
    no warnings;
    my ( $self, $c, $data, $opt ) = @_;

    # return ������
    my $FORM;    # $c->stash->{parseform_result} �˷�̤Ȥ��ƥ��åȤ���ޤ�
    my %opt;
    %opt = %{$opt} if ( ref $opt eq 'HASH' );

    $FORM ||= {};

    # �ѿ�����������
    my ( %hidden, %hidden_with_label, %labelonly, %ignore, %select_prop );
    undef %hidden;
    undef %hidden_with_label;
    undef %labelonly;
    undef %ignore;
    undef %select_prop;

    # parse_form �᥽�åɤ��Ф��ƤΥ��ץ����μ����դ�����
    if ( $opt{'-hidden'} ) {

        # ����hidden�ˤ���Τ� ?
        $opt{'-hidden'} = [ map( $_->{'name'}, $c->clc($self)->schema() ) ] if ref( $opt{'-hidden'} ) ne 'ARRAY';
        %hidden = map( { $_ => 1 } @{ $opt{'-hidden'} } );
    }
    if ( $opt{'-hidden_with_label'} ) {

        # ����hidden_with_label�ˤ���Τ� ?
        if ( ref( $opt{'-hidden_with_label'} ) ne 'ARRAY' ) {
            $opt{'-hidden_with_label'} = [ map( $_->{'name'}, $c->clc($self)->schema() ) ];
        }
        %hidden_with_label = map { $_ => 1 } @{ $opt{'-hidden_with_label'} };

        # �ե����������hidden��ͥ�褷�ޤ���
        foreach ( grep( $_->{'form'}->{'type'} eq 'hidden', $c->clc($self)->schema() ) ) {
            delete $hidden_with_label{ $_->{'name'} };
        }
        $hidden{$_} = 1 foreach @{ $opt{'-hidden_with_label'} };
    }
    elsif ( $opt{'-labelonly'} ) {
        $opt{'-labelonly'} = [ map( $_->{'name'}, $c->clc($self)->schema() ) ] if ref( $opt{'-labelonly'} ) ne 'ARRAY';
        %labelonly = map { $_ => 1 } @{ $opt{'-labelonly'} };
        $hidden{$_} = 1 foreach @{ $opt{'-labelonly'} };
    }
    if ( $opt{'-ignore'} ) {
        $opt{'-ignore'} = [ map( $_->{'name'}, $c->clc($self)->schema() ) ] if ref( $opt{'-ignore'} ) ne 'ARRAY';
        %ignore = map( { $_ => 1 } @{ $opt{'-ignore'} } );
    }
    if ( $opt{'-select_prop'} ) {    #�ʤˤ���?
        %select_prop = map( { $_ => 1 } @{ $opt{'-select_prop'} } );
    }

    foreach my $schema (
        ref( $opt{'-list'} ) eq 'ARRAY'
        ? map( $c->clc($self)->schema($_), @{ $opt{'-list'} } )
        : $c->clc($self)->schema() )
    {
        my ($key) = $schema->{'name'};
        next if ( %select_prop and !( exists $select_prop{$key} ) );
        next if $ignore{$key};

        # ̵�뤹����ϡ������Ǥ��褦�ʤ�

        my ( %type, %javascript, %formopt );

        # ��������������⡢���ץ������꤬ͥ�褵���
        if ( $hidden{$key} ) {
            $type{'orig'} = $schema->{'form'}->{'type'};
            $type{'cur'}  = 'hidden';
        }
        else {
            $type{'cur'} = $schema->{'form'}->{'type'};
            if ( $type{'cur'} eq 'hidden_with_label' ) {
                $type{'cur'} = 'hidden';
                $hidden_with_label{$key} = 1;
            }
            %javascript = map( { '-' . $_ => $schema->{'form'}->{$_} }
                grep( $schema->{'form'}->{$_},
                    qw(onClick onChange onFocus onBlur onMouseOver onMouseOut
                        onSelect style onDblClick onKeyDown onKeyUp onKeyPress
                        class readOnly style disabled) ) );
            if ( ref $schema->{'form'} eq 'HASH' ) {
                foreach my $i ( keys %{ $schema->{'form'} } ) {
                    if ( grep { $i eq $_ }
                        qw!value values default ignore type name list linebreak size maxlength suffix prefix error! )
                    {

                        # ���פ��ʤ���Τ����򲼵�����Ͽ����
                    }
                    else {
                        $formopt{$i} = $schema->{'form'}->{$i};
                    }
                }
            }

            #%formopt = %{$schema->{'form'}}
        }

        # �ե�����̾����������
        $formopt{'-name'} = $c->clc($self)->get_form_prefix . $key;

        # �ե�����θ��Ф������
        $FORM->{ $key . '_desc' } = $schema->{'desc'};

        # default �����ꤹ��
        $formopt{'-default'} = $self->parse_form_set_default( $c, $schema, $data );

        if ( ref( $schema->{'list'} ) eq 'ARRAY' ) {
            $formopt{'-values'} = [ map( $_->{'name'}, grep { not $_->{'form'}->{'ignore'} } @{ $schema->{'list'} } ) ];
            $formopt{'-labels'}
                = { map { $_->{'name'} => $_->{"desc_$ENV{'LANG'}"} || $_->{'desc'} } @{ $schema->{'list'} } };
        }
        next if ref( $formopt{'-default'} ) eq 'Fh';

        # �����ΤȤ��ϡ�radio��checkbox�ˤ���
        $type{'cur'} = 'checkbox' if ( $c->stash->{list_search_now} and $type{'cur'} eq 'radio' );

        #
        # ��äȥե��������������Ȥ���ޤǤ��ޤ�����
        #
        if ( $type{'cur'} eq 'hidden' && !$c->stash->{list_search_now} ) {
            delete( $formopt{'-values'} );
            if ( not $labelonly{$key} ) {
                if ( ref( $formopt{'-default'} ) eq 'ARRAY' ) {
                    $FORM->{$key} = join(
                        '',
                        map( sprintf( '<input type="hidden" name="%s" value="%s">',
                                $self->escape_html( $formopt{'-name'}, $_ ) ),
                            @{ $formopt{'-default'} } )
                    );
                }
                else {
                    $FORM->{$key} = sprintf( '<input type="hidden" name="%s" value="%s">',
                        $self->escape_html( $formopt{'-name'}, $formopt{'-default'} ) );
                }
            }
            next unless $hidden_with_label{$key} or $labelonly{$key};

            # ��٥���դ�����
            if ( ref( $schema->{'list'} ) eq 'ARRAY' ) {
                my (@bit);
                if ( ref $formopt{'-default'} eq 'ARRAY' ) {
                    @bit = @{ $formopt{'-default'} };
                }
                else {
                    $bit[0] = $formopt{'-default'};
                }
                ## �ץ饹�ƥ����Ȥ�������
                my $plus;
                if ( $schema->{'plus_text'} ) {
                    $plus = $data->{ $schema->{name} . '_plus_text' };
                    push(
                        @{ $schema->{'list'} },
                        { name => ( scalar @{ $schema->{'list'} } ) + 1, desc => $schema->{plus_text}->{'name'} }
                    );
                }
                ## �����ޤ�
                foreach my $list ( @{ $schema->{'list'} } ) {
                    if ( grep { $list->{'name'} eq $_ } @bit ) {
                        $FORM->{$key} .= $list->{desc};
                        $FORM->{$key}
                            .= ( $schema->{'form'}->{'linebreak'} || $schema->{'form'}->{'-columns'} ) ? '<br>' : ' ';
                    }
                }
                $FORM->{$key} .= "<div>$plus</div>" if $plus;
            }
            elsif ( $type{'orig'} eq 'textarea' ) {
                $FORM->{$key} .= $self->format_linebreak( $self->escape_html( $formopt{'-default'} ), '<br>' );
            }
            else {
                $FORM->{$key} .= $self->escape_html( $schema->{'form'}->{'desc'} || $formopt{'-default'} )
                    if ( $formopt{'-default'} );
            }
            $FORM->{$key} = $schema->{'form'}->{'prefix'} . $FORM->{$key} . $schema->{'form'}->{'suffix'}
                if ( $formopt{'-default'} );
        }
        elsif ( $type{'cur'} eq 'text' ) {
            delete $formopt{ -values } if exists $formopt{ -values };
            $FORM->{$key} = textfield(
                %formopt,
                -override  => 1,
                -size      => $schema->{'form'}->{'size'},
                -maxlength => $schema->{'form'}->{'maxlength'},
                %javascript,
            );
        }
        elsif ( $type{'cur'} eq 'password' ) {
            $FORM->{$key} = password_field(
                %formopt,
                -override  => 1,
                -size      => $schema->{'form'}->{'size'},
                -maxlength => $schema->{'form'}->{'maxlength'},
                %javascript,
            );
        }
        elsif ( $type{'cur'} eq 'date' || $schema->{sql}->{type} =~ /timestamp/ ) {
            if ( $c->stash->{list_search_now} ) {
                delete $formopt{-default} if exists $formopt{-default};
                delete $formopt{default_start}
                    if exists $formopt{default_start};    # ����򤤤�ʤ��ȡ�textfield�᥽�åɤǥХ��Ǥޤ�����why!
                delete $formopt{default_end}
                    if exists $formopt{default_end};      # ����򤤤�ʤ��ȡ�textfield�᥽�åɤǥХ��Ǥޤ�����why!
                                                          # �ꥹ�ȤΥ������ξ��Τ�
                my %start = %formopt;
                my %end   = %formopt;
                $start{-name}    = $start{-name} . '_start';
                $start{-default} = $schema->{form}->{default_start};
                $end{-name}      = $end{-name} . '_end';
                $end{-default}   = $schema->{form}->{default_end};
                $FORM->{$key}    = sprintf(
                    "%s%s �� %s%s",
                    textfield(
                        %start,
                        -override  => 1,
                        -size      => $schema->{'form'}->{'size'},
                        -maxlength => $schema->{'form'}->{'maxlength'},
                        %javascript,
                    ),
                    sprintf(
                        qq[<input type="button" class="btn" value="����" onClick="javascript: wrtCalendar(this.form.%s);">],
                        $start{'-name'} ),
                    textfield(
                        %end,
                        -override  => 1,
                        -size      => $schema->{'form'}->{'size'},
                        -maxlength => $schema->{'form'}->{'maxlength'},
                        %javascript,
                    ),
                    sprintf(
                        qq[<input type="button" class="btn" value="����" onClick="javascript: wrtCalendar(this.form.%s);">],
                        $end{'-name'} ),
                );
            }
            else {
                $FORM->{$key} = textfield(
                    %formopt,
                    -override => 1,

                    #-readonly => 1,
                    -size      => $schema->{'form'}->{'size'},
                    -maxlength => $schema->{'form'}->{'maxlength'},
                    %javascript,
                );
                $FORM->{$key} .= sprintf(
                    qq[<input type="button" class="btn" value="����" onClick="javascript: wrtCalendar(this.form.%s);">],
                    $formopt{'-name'} );
            }
        }
        elsif ( $type{'cur'} eq 'html' ) {
            $FORM->{$key} = $self->set_html_editor( $c, $FORM, \%formopt, $schema );
        }
        elsif ( $type{'cur'} eq 'radio' ) {
            $formopt{'-default'} = '-' unless ( length( $formopt{'-default'} ) );
            ## ���󥱡����Ѥγ�ĥ���ܤ�������
            my $plus;
            if ( $schema->{'plus_text'} ) {
                $plus = textfield(
                    -name      => $formopt{-name} . '_plus_text',
                    -override  => 1,
                    -size      => $schema->{plus_text}->{'size'},
                    -maxlength => $schema->{plus_text}->{'maxlength'},
                );
                push( @{ $formopt{ -values } }, ( scalar @{ $formopt{ -values } } ) + 1 )
                    ;    #$schema->{plus_text}->{'name'}
                $formopt{-labels}->{ @{ $formopt{ -values } } } = $schema->{plus_text}->{'name'};
            }
            $FORM->{$key} = radio_group(
                %formopt,
                -linebreak => $schema->{'form'}->{'linebreak'},
                %javascript,
            );
            $FORM->{$key} .= $plus if $plus;    ## ���󥱡����Ѥγ�ĥ���ܤ�������
        }
        elsif ( $type{'cur'} eq 'checkbox' ) {
            if ( ref( $schema->{'list'} ) eq 'ARRAY' ) {
                ## ���󥱡����Ѥγ�ĥ���ܤ�������
                my $plus;
                if ( $schema->{'plus_text'} ) {
                    $plus = textfield(
                        -name      => $formopt{-name} . '_plus_text',
                        -override  => 1,
                        -size      => $schema->{plus_text}->{'size'},
                        -maxlength => $schema->{plus_text}->{'maxlength'},
                    );
                    push( @{ $formopt{ -values } }, ( scalar @{ $formopt{ -values } } ) + 1 )
                        ;    #$schema->{plus_text}->{'name'}
                    $formopt{-labels}->{ @{ $formopt{ -values } } } = $schema->{plus_text}->{'name'};
                }
                my (%args) = (
                    %formopt,
                    -defaults  => $formopt{'-default'},
                    -linebreak => $schema->{'form'}->{'linebreak'},
                    %javascript
                );
                $FORM->{$key} = checkbox_group(%args);
                $FORM->{$key} .= $plus if $plus;    ## ���󥱡����Ѥγ�ĥ���ܤ�������
            }
            else {
                $FORM->{$key} = checkbox(
                    %formopt,
                    -checked => $formopt{'-default'} ? 'checked' : '',
                    -label => $schema->{'form'}->{'desc'} || $schema->{'desc'} || $schema->{'name'},
                    -value => $schema->{'form'}->{'value'} || 'checked',
                    %javascript,
                );
            }
        }
        elsif ( $type{'cur'} eq 'select' ) {
            $formopt{'-default'} = '' unless ( defined $formopt{'-default'} );
            $FORM->{$key} = popup_menu( %formopt, %javascript );
        }
        elsif ( $type{'cur'} eq 'textarea' ) {
            $FORM->{$key} = textarea(
                %formopt,
                -rows => ( $schema->{'form'}->{'rows'} || 4 ),
                -columns => ( $schema->{'form'}->{'columns'} || $schema->{'form'}->{'cols'} || 64 ),
                -wrap => $schema->{'form'}->{'wrap'} || '',
                %javascript,
            );
        }
        elsif ( $type{'cur'} eq 'file' ) {
            $FORM->{$key} = filefield( %formopt, %javascript );
        }
        elsif ( $type{'cur'} eq 'scrolling' ) {
            my (%args) = (
                %formopt,
                -size => $schema->{'form'}->{'size'} || '',
                -multiple => 'true',
                %javascript
            );
            $FORM->{$key} = scrolling_list(%args);
        }
        elsif ( $type{'cur'} eq 'ignore' ) {

            # Nothing to do.
        }
        if ( $schema->{'popup'} ) {

        #$c->log->dumper('---------------------------------------------------------------popup�䤱�� ===',$type{'cur'});
            $FORM->{$key} .= $self->make_popup( $c, $key ) if ( $type{'cur'} ne 'hidden' );
        }
        if ( $schema->{'add_download_link'} ) {
            my $data = $schema->{'add_download_link'}->{class}->retrieve( $formopt{'-default'} )
                if $formopt{'-default'};
            my $view;
            if ($data) {
                my $name = $schema->{'add_download_link'}->{name};
                $view = $data->$name;
                my $plus = sprintf(
                    qq!<a href="%s?id=%d">��Ͽ�ѥե�����: %s</a>!,
                    $schema->{'add_download_link'}->{link},
                    $formopt{'-default'}, $view,
                );
                $FORM->{$key} = ( $FORM->{$key} && $FORM->{$key} =~ /hidden/ ) ? $plus : $FORM->{$key} . $plus;
            }
        }
        if ( not grep( $type{'cur'} eq $_, qw(hidden ignore) ) ) {
            $FORM->{$key} = $schema->{'form'}->{'prefix'} . $FORM->{$key} . $schema->{'form'}->{'suffix'};
            $FORM->{$key} .= sprintf( ' <span class="asterisk">%s</span>', $opt{'-asterisk_for_notnull'} )
                if $schema->{'sql'}->{'notnull'}
                and $opt{'-asterisk_for_notnull'};
        }
        $FORM->{ $c->clc($self)->get_form_prefix . $key } = $FORM->{$key};
    }

    $c->stash->{parseform_result} = $FORM;
}

# -------------------------------------------------------------------------
# html editor
sub set_html_editor {
    my $self    = shift;
    my $c       = shift;
    my $FORM    = shift;
    my $formopt = shift;
    my $schema  = shift;

    # escape
    #    $formopt->{-default} = $self->escape_html($formopt->{-default});

    $FORM->{submit} = submit(
        -name    => "submit_base",
        -value   => '����',
        -class   => 'btn',
        -onclick => sprintf( "var obj=new ChangeForm('%s', ''); obj.getRichTextValues();", $formopt->{-name} )
    );
    $c->stash->{onload} .= sprintf( "var frame_%s = new Main('%s'); frame_%s.init_iframe();",
        $schema->{name}, $formopt->{-name}, $schema->{name} );

    my $line;
    my $file = $self->get_html_editor_file($c);
    if ( -e $file ) {
        $line = $self->read_file( $c, $file );
    }
    else {
        $line = <<"EOF";
<style type="text/css">
<!--
.format{
	width:500px;
	background:#ddd;
	padding:10px 0 10px 0;
	margin-top:10px;
	margin-bottom:10px;
}
-->
</style>
<div class="format">
�ե����
<select name="font_btn" id="font_btn" onchange="var obj=new ChangeForm('\$FORM{-name}', 'fontname'); obj.format(this[this.selectedIndex].value)">
  <option value="MS P �����å�,MS PGothic,Osaka,Sans-Serif">�����å���</option>
  <option value="MS P ��ī,MS PMincho,ʿ����ī,Serif">��ī��</option>
  <option value="MS �����å�,MS Gothic,Osaka-����,Monospace">���������å���</option>
  <option value="Geneva,Arial,Sans-Serif">Arial</option>
</select>
������
<select name="font_size" id="font_size" onchange="var obj=new ChangeForm('\$FORM{-name}', 'fontSize'); obj.format(this[this.selectedIndex].value);this.selectedIndex=0;">
  <option value="1">8pt</option>
  <option value="2">9px</option>
  <option value="3">10pt</option>
  <option value="4">11px</option>
  <option value="5">12pt</option>
  <option value="6">14pt</option>
  <option value="7">16pt</option>
</select><br>
<input type="button" name="bold_btn" value="����" onclick="var obj=new ChangeForm('\$FORM{-name}', 'bold'); obj.format();" height="18" style="CURSOR:POINTER">
<input type="button" name="bold_btn" value="����" onclick="var obj=new ChangeForm('\$FORM{-name}', 'italic'); obj.format();" height="18" style="CURSOR:POINTER">
<input type="button" name="bold_btn" value="����" onclick="var obj=new ChangeForm('\$FORM{-name}', 'underline'); obj.format();" height="18" style="CURSOR:POINTER">
<input type="button" name="bold_btn" value="��·��" onclick="var obj=new ChangeForm('\$FORM{-name}', 'justifyleft'); obj.format();" height="18" style="CURSOR:POINTER">
<input type="button" name="bold_btn" value="���·��" onclick="var obj=new ChangeForm('\$FORM{-name}', 'justifycenter'); obj.format();" height="18" style="CURSOR:POINTER"><br>
<input type="button" name="bold_btn" value="��·��" onclick="var obj=new ChangeForm('\$FORM{-name}', 'justifyright'); obj.format();" height="18" style="CURSOR:POINTER">
<input type="button" name="bold_btn" value="�վ��" onclick="var obj=new ChangeForm('\$FORM{-name}', 'insertunorderedlist'); obj.format();" height="18" style="CURSOR:POINTER">
<input type="button" name="bold_btn" value="�����ֹ�" onclick="var obj=new ChangeForm('\$FORM{-name}', 'insertorderedlist'); obj.format();" height="18" style="CURSOR:POINTER">
<input type="button" name="bold_btn" value="����ǥ��" onclick="var obj=new ChangeForm('\$FORM{-name}', 'indent'); obj.format();" height="18" style="CURSOR:POINTER">
<input type="button" name="bold_btn" value="�����ȥǥ��" onclick="var obj=new ChangeForm('\$FORM{-name}', 'outdent'); obj.format();" height="18" style="CURSOR:POINTER">
<input type="button" name="bold_btn" value="���" onclick="var obj=new ChangeForm('\$FORM{-name}', 'CreateLink'); obj.createLink('��󥯤�URL�����Ϥ��Ƥ���������', 'http:\/\/');" height="18" style="CURSOR:POINTER">
</div>
<table width="\$FORM{-width}px" border="0">
  <tr>
    <td id="container_\$FORM{-name}" height="200px"></td>
  </tr>
</table>
EOF
    }

    my $result = $self->parse_variable( $line, %{$formopt}, -width => $schema->{form}->{width} || '500' );
    $result .= sprintf(
        qq!<input type="hidden" name="%s" value="%s" id="%s">!,
        $formopt->{-name}, $self->escape_html( $formopt->{-default} ),
        $formopt->{-name}
    );

    $FORM->{ $schema->{name} } = $result;
}

sub get_html_editor_file : Private {
    my ( $self, $c ) = @_;
    my $prefix = $self->get_template_prefix($c);

    my $file = $self->get_my_file( $c, 'html_editor' );
    unless ( -e $file ) {
        $file = sprintf( "%s/template/%s/html_editor.html", $c->config()->{root}, $prefix );
    }
    return $file;
}

# �ǥե���Ȥ����ꤹ��
sub parse_form_set_default {
    my $self   = shift;
    my $c      = shift;
    my $schema = shift;
    my $data   = shift;

    #    my $key = shift;# �ǡ���
    my $default;

    # value �����
    my (@tmp);
    my $key = $schema->{'name'};
    if ( ref( $data->{$key} ) eq 'ARRAY' ) {
        @tmp = map {$_} grep { length($_) } @{ $data->{$key} };
    }
    else {
        $tmp[0] = $data->{$key} if ( exists $data->{$key} );
    }

    #    $c->log->dumper('----------------------�ͤ����뤫�ɤ����� == ',@tmp);
    unless (@tmp) {

        # �ǡ�����̵�����
        # form ������ɤ߹���
        if ( ref( $schema->{'form'}->{'default'} ) eq 'ARRAY' ) {
            my (@default) = @{ $schema->{'form'}->{'default'} };
            $default = \@default if ( scalar(@default) );
        }
        else {
            $default = $schema->{'form'}->{'default'} if ( defined $schema->{'form'}->{'default'} );
        }
    }
    else {

        # �ǡ�����������
        if ( scalar @tmp > 1 ) {
            $default = \@tmp;
        }
        else {
            $default = $tmp[0] if ( defined $tmp[0] );
        }
    }

    #    $c->log->dumper('----------------------��̤�default == ',$default);
    return $default;
}
####################################################################################################
# �������᥽�åɡ�
# HTML���������פ�Ԥ�
####################################################################################################

=head2 parse_form

 �������᥽�åɡ�
 HTML���������פ�Ԥ�

=cut

sub escape_html : Private {
    no warnings;
    my $self = shift;
    my (@arg) = @_;
    foreach (@arg) {
        $_ =~ s/\&/\&amp\;/g;
        $_ =~ s/\"/\&quot\;/g;
        $_ =~ s/\>/\&gt\;/g;
        $_ =~ s/\</\&lt\;/g;
    }
    return wantarray ? @arg : $arg[0];
}

=head2 format_linebreak

 �������᥽�åɡ�
 ���ԥ����ɤ� $linebreak �����줹��

=cut

sub format_linebreak : Private {
    my ( $self, $line, $linebreak ) = @_;
    $linebreak ||= "\n";
    return $line unless ($line);
    $line =~ s/\x0D\x0A|\x0D|\x0A/$linebreak/go;
    return $line;
}

=head2 blank

 �������᥽�åɡ�
 ��ʸ�����ɤ�����Ƚ�̤���

=cut

sub blank : Private {
    my $self = shift;
    return ( !defined $_[0] || $_[0] eq '' );
}

=head2 make_popup

 �������᥽�åɡ�
 �ݥåץ��åפ򳫤��ܥ���������������

=cut

sub make_popup : Private {
    my $self = shift;
    my $c    = shift;
    my $name = shift;

    # �ܥ����ѤΥ�����ץȺ���
    my $get = $self->createJSFunction( $c, $name );

    # �ܥ�������
    my $button = $self->createPopupBtn( $c, $name );
    return $button . $get;
}

=head2 load_popup_setting_data

 �������᥽�åɡ�
 �ݥåץ��åפǸƤФ줿¦ ���Ȥ��ؿ�

=cut

sub load_popup_setting_data : Private {
    my $self = shift;
    my $c    = shift;

    die 'Window class or name is not setting' unless ( $c->req->param('dist_class') and $c->req->param('dist_name') );

    my $class_name  = $c->req->param('dist_class');
    my $schema_name = $c->req->param('dist_name');

    $self->set_popup_setting_data( $c, $class_name, $schema_name );

    $c->log->debug('----------------------- loadStoraedData �η��');
    $c->log->dumper( $c->stash->{'popup_setting'} );
}

=head2 set_popup_setting_data

 �������᥽�åɡ�
 �ݥåץ��å��Ѥ� config ���ɤ߹���ǡ������å����ơ����åȤ�����ܴؿ�

=cut

sub set_popup_setting_data : Private {
    my $self  = shift;
    my $c     = shift;
    my $class = shift;
    my $name  = shift;
    die 'name �λ��꤬����ޤ���' unless $name;

    my (%t_opt)
        = ( ref $c->clc($class)->schema($name)->{popup}->{link} eq 'HASH' )
        ? %{ $c->clc($class)->schema($name)->{popup}->{link} }
        : die "link ���꤬����ޤ���";
    $t_opt{'form_name'} = 'form1' unless ( $t_opt{'form_name'} );
    $t_opt{'func_name'} = 'WOpen' unless ( $t_opt{'func_name'} );
    die 'dist_class ������ޤ���' unless ( $t_opt{'dist_class'} );    # ���뤫 ��Ӥ�����Ȥʤ������
    die 'dist_name ������ޤ���'  unless ( $t_opt{'dist_name'} );     #������� ��Ӥ�����Ȥʤ������

    my %opt = ( ref $c->clc($class)->schema($name)->{popup}->{base} eq 'HASH' )
        ? %{ $c->clc($class)->schema($name)->{popup}->{base} }
        : die 'Config��popup���ܤ��ʤ��������㤦';
    foreach (qw(func_name num targ_vals dist_class dist_name form_name targ_is_url)) {
        $opt{$_} = $t_opt{$_};
    }
    die 'wnd_name is null !!'                unless ( $opt{'wnd_name'} );    #  'search' �򤤤�Ȥ���
    die "class �� base �˻��ꤵ��Ƥ��ޤ���" unless $opt{'class'};           # ���Υ��饹����ꤷ�Ƥ���������
    die "mode �� base �˻��ꤵ��Ƥ��ޤ���" unless $opt{'mode'};    #  'popup_slist' ����ꤹ�뤫�������mode�Ǥ⤤����
    die "style �� base �˻��ꤵ��Ƥ��ޤ���" unless ( $opt{'style'} and ref( $opt{'style'} ) eq 'HASH' );

    # $opt{'style'} = {width => '450', height => '600',menubar => 'no',scrollable => 'auto', scrollbars => 'auto'};
    # $opt{'style'}->{'width'} = '450' unless($opt{'style'}->{'width'});
    # $opt{'style'}->{'height'} = '600' unless($opt{'style'}->{'height'});

    # �����ޤǤ� %opt �����꤬��λ���ޤ���

    #    $c->log->dumper(\%opt);
    $c->stash->{'popup_setting'}->{p_settings} = \%opt;

    # �ʤ�publish ���Ѥߤ������
    my (%js_name_hash) = (
        scalar => 1,
        array  => 1,
        hash   => 1
    );
    $c->stash->{'popup_setting'}->{js_name_hash} = \%js_name_hash;         # publish �Ǥ���ߤ���
    $c->stash->{'popup_setting'}->{popup_js}     = 'popup_sel_func.js';    # publish �Ǥ���ߤ���
}

=head2 createJSFunction

 �������᥽�åɡ�
 �ݥåץ��åײ��̤�ɽ�����뤿���LINK����

=cut

sub createJSFunction : Private {
    my $self = shift;
    my $c    = shift;
    my $name = shift;

    # ������ɤ߹���
    $self->set_popup_setting_data( $c, $self, $name );
    my (%opt) = %{ $c->stash->{'popup_setting'}->{p_settings} };

    # �������� �ե������Ĥ���
    my %FORM;
    %FORM = map { $_ => $opt{$_} } qw(func_name wnd_name class mode dist_class dist_name);
    $FORM{'style'} = join( ',', map { sprintf( "%s=%s", $_, $opt{'style'}->{$_} ) } keys( %{ $opt{'style'} } ) );

    #
    my $prefix = $c->clc($self)->get_form_prefix();

    #
    if ( $opt{'targ_vals'} and !$opt{'targ_is_url'} ) {
        my @default_list;
        die "targ_vals��ARRAYREF�ǤϤ���ޤ���" unless ( ref( $opt{'targ_vals'} ) eq 'ARRAY' );
        foreach ( @{ $opt{'targ_vals'} } ) {
            $_->{'type'} = 'hidden' unless ( $_->{'type'} );

            #$_->{'default'} = '0' unless($_->{'default'});
            die "targ_vals�����name���ʤ���Τ�����ޤ�" unless ( $_->{'name'} );
            push(
                @default_list,
                sprintf(
                    'setValue(f, "%s", "%s", "%s");',
                    $_->{'type'} || 'hidden',
                    $prefix . $_->{'name'},
                    $_->{'default'},
                )
            );
        }
        $FORM{'default_list'} = join( "\n\t", @default_list );
    }
    elsif ( ref( $opt{'targ_vals'} ) eq 'ARRAY' and $opt{'targ_is_url'} ) {
        my @url;
        foreach my $targ ( @{ $opt{'targ_vals'} } ) {
            $targ->{'type'}    = 'hidden' unless ( $targ->{'type'} );
            $targ->{'default'} = '0'      unless ( $targ->{'default'} );
            die("targ_vals�����name���ʤ���Τ�����ޤ�") unless ( $targ->{'name'} );
            push( @url, join( ',', map { sprintf( '%s.%s', $_, $targ->{$_} ) } keys( %{$targ} ) ) );
        }
        $FORM{'targ_vals'} = '&targ_vals=' . join( ':', @url );
    }
    $self->call_trigger( 'createJSFunction_before_parse_variable', $c, \%FORM );

    #$this->number($opt{'num'});
    #is->p_settings()->[$this->number()] = \%opt;
    #--------------------------------------------------------------------------------------
    # javascript ������ʪ���֤��ޤ���
    return $self->parse_variable( $self->read_file( $c, $self->get_popup_file($c) ), %FORM );
}

=head2 createPopupBtn

 �������᥽�åɡ�
 �ݥåץ��åץܥ������������

=cut

sub createPopupBtn : Private {
    my $self      = shift;
    my $c         = shift;
    my $name      = shift;
    my $func_name = $c->clc($self)->schema($name)->{popup}->{link}->{func_name};
    my $line      = join(
        '&nbsp;',
        sprintf( '<input type="button" class="btn" name="person_search_btn" value="����" onClick="javascript: %s();">',
            $func_name ),
        sprintf(
            '<input type="button" class="btn" name="person_def_bnt" value="���ꥢ" onClick="javascript: %sToDefault(this.form);">',
            $func_name )
    );
    return $line;
}

=head2 PVtoJSV

 �������᥽�åɡ�
 
 Perl���ѿ���JavaScript���ѿ��ˤ���ؿ�
 �ޤ��ޤ����褫����
 ���ɤ�;�Ϥ���
 ʣ����Ȥ����ϡ������ϥå�����ꡢ��3�������Ϥ�����
 my(%name_hash) = (scalar => 1,
 					array => 1,
 					hash => 1);
 Usage: $JSValiable = $self->PVtoJSV($c, $PerlValiable);
 			$PerlValiable�ϥ����顼�ʳ��ϥ�ե���󥹤��Ϥ�����
 				�������֥������Ȥ��Ϥ����餪�������ʤ�
 
 		 $JSValiable =$self-> PVtoJSV($c, $PerlValiable, \%name_hash);
 		 $JSValiable = $self->PVtoJSV($c, $PerlValiable, \%name_hash,'var_name');

=cut

sub PVtoJSV : Private {
    my $self      = shift;
    my $c         = shift;
    my $valiable  = shift;
    my $name_hash = shift;
    my $val_name  = shift;

    my ($return) = "";
    unless ( ref($name_hash) =~ /HASH/ ) {
        my (%hash) = (
            scalar => 0,
            array  => 0,
            hash   => 0
        );
        $name_hash = \%hash;
    }

    if ( $valiable and ref($valiable) =~ /SCALAR/ ) {
        $return .= $self->PVtoJSV( $c, ${$valiable}, $name_hash, $val_name );
    }
    elsif ( $valiable and ref($valiable) =~ /ARRAY/ ) {
        my ($array_num) = $name_hash->{array};
        my ($hash_num)  = $name_hash->{hash};
        my ($var_name);
        if ( $val_name =~ /\w+/ ) {
            $var_name = $val_name;
        }
        else {
            $var_name = sprintf( "array_%s", $array_num );
            $name_hash->{array}++;
        }
        $return .= sprintf( "\nvar %s = new Array();\n", $var_name );
        for ( my ($i) = 0; $i < scalar @{$valiable}; $i++ ) {
            if ( ref( $valiable->[$i] ) =~ /SCALAR/ ) {
                $return .= sprintf( "%s[%s] = \"%s\";\n", $var_name, $i, ${ $valiable->[$i] } );
            }
            elsif ( ref( $valiable->[$i] ) =~ /ARRAY/ ) {
                my ($array_n) = $name_hash->{array};
                $return .= $self->PVtoJSV( $c, $valiable->[$i], $name_hash );
                $return .= sprintf( "%s[%s] = array_%s;\n", $var_name, $i, $array_n );
            }
            elsif ( ref( $valiable->[$i] ) =~ /HASH/ ) {
                my ($hash_n) = $name_hash->{hash};
                $return .= $self->PVtoJSV( $c, $valiable->[$i], $name_hash );
                $return .= sprintf( "%s[%s] = hash_%s;\n", $var_name, $i, $hash_n );
            }
            else {
                $return .= sprintf( "%s[%s] = \"%s\";\n", $var_name, $i, $valiable->[$i] );
            }
        }
    }
    elsif ( $valiable and ref($valiable) =~ /HASH/ ) {
        my ($array_num) = $name_hash->{array};
        my ($hash_num)  = $name_hash->{hash};
        my ($var_name);
        if ( $val_name && $val_name =~ /\w+/ ) {
            $var_name = $val_name;
        }
        else {
            $var_name = sprintf( "hash_%s", $hash_num );
            $name_hash->{hash}++;
        }
        $return .= sprintf( "\nvar %s = new Array();\n", $var_name );
        my (@keys) = keys( %{$valiable} );
        for ( my ($i) = 0; $i < scalar @keys; $i++ ) {
            if ( ref( $valiable->{ $keys[$i] } ) =~ /SCALAR/ ) {
                $return .= sprintf( "%s[\"%s\"] = \"%s\";\n",
                    $var_name, $keys[$i], $self->escape_javascript( ${ $valiable->{ $keys[$i] } } ) );
            }
            elsif ( ref( $valiable->{ $keys[$i] } ) =~ /ARRAY/ ) {
                my ($array_n) = $name_hash->{array};
                $return .= $self->PVtoJSV( $c, $valiable->{ $keys[$i] }, $name_hash );
                $return .= sprintf( "%s[\"%s\"] = array_%s;\n", $var_name, $keys[$i], $array_n );
            }
            elsif ( ref( $valiable->{ $keys[$i] } ) =~ /HASH/ ) {
                my ($hash_n) = $name_hash->{hash};
                $return .= $self->PVtoJSV( $c, $valiable->{ $keys[$i] }, $name_hash );
                $return .= sprintf( "%s[\"%s\"] = hash_%s;\n", $var_name, $keys[$i], $hash_n );
            }
            else {
                $return .= sprintf( "%s[\"%s\"] = \"%s\";\n",
                    $var_name, $keys[$i], $self->escape_javascript( $valiable->{ $keys[$i] } ) );
            }
        }
    }
    else {
        my ($var_name);
        if ( $val_name =~ /\w+/ ) {
            $var_name = $val_name;
        }
        else {
            $var_name = sprintf( "scalar_%s", $name_hash->{scalar} );
            $name_hash->{scalar}++;
        }
        $return .= sprintf( "var %s = \"%s\";\n", $var_name, $valiable );

    }
    return $return;
}

sub escape_javascript {    #  " ��"" �ˤ��ޤ���
    my $self = shift;
    my (@arg) = @_;
    foreach (@arg) {
        $_ =~ s/"/\\"/g;
    }
    return wantarray ? @arg : $arg[0];
}

=head1 SEE ALSO

�Ȥꤢ�������ä�
���ܸ�ȱѸ�� ξ��POD�񤭤���������ɲ��Ȥ��ʤ�ʤ��Τ��ʤ�

=head1 AUTHOR

Kenichiro Nakamura, E<lt>nakamura@shanon.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Kenichiro Nakamura and Shanon Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;

