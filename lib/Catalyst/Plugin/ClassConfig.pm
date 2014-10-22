package Catalyst::Plugin::ClassConfig;

use strict;
use warnings;
use base 'Class::Data::Inheritable';
use NEXT;
use Text::SimpleTable;
use Clone 'clone';

our $VERSION = '0.01';

__PACKAGE__->mk_classdata('_clc_obj');

my ($Revision) = '$Id: ClassConfig.pm,v 1.52 2006/04/07 08:32:30 shimizu Exp $';

=head1 NAME

Catalyst::Plugin::ClassConfig - MVC�Υ��饹���ĤΥե�����˴�Ϣ�դ��ޤ���

=head1 SYNOPSIS

use Catalyst qw/ClassConfig/

MyApp->config()->{ClassConfig => {dir => '/path/to/config/dir',
ModelPrefix => ['CDBI','MyDBI'],
ViewPrefix => ['TT','HTMLT']};

=head1 DESCRIPTION

���̤�̾����MVC�Υ��饹���ĤΥ���ե����ե�����˴�Ϣ�դ��ޤ���
��ǥ롢�ӥ塼������ȥ���Ƕ�����ʬ�����Υե�����˽񤭽Ф������ݤ����Ѥ��Ƥ���������

=cut

=over 2

=item prepare

���������
MyApp->config->{'ClassConfig'}->{'NotClone'}�����ꤵ��Ƥ��ʤ���硢
�����ΰ�Υ���ե����ǡ���������ΰ�˥��ԡ����ޤ���
NotClone�����ꤵ��Ƥ�����������ΰ�ϻȤ�줺��
���٤Ƽ����ΰ褬�Ȥ��ޤ���
���ξ���ư����˥���ե������ѹ�����ȡ�
Web�����С�����λ����ޤǻĤ�Τ���դ��Ƥ���������

=cut

sub prepare {
    my $c = shift;
    $c->log->debug('++++++ ClassConfig prepare +++++++');
    if ( $c->debug ) {
        $c->log->debug('+ Start                          +');
    }

    # ����ե���������ΰ��Clone����
    unless ( ref( $c->config->{'ClassConfig'} ) eq 'HASH'
        and $c->config->{'ClassConfig'}->{'NotClone'} )
    {
        $c->log->debug('+  start clone config data       +');
        $c->_clc_obj->_config( clone( $c->_clc_obj->_config_backup ) );
        $c->log->debug('+  end clone config data         +');
    }

    # view��ͥ���٤򥯥ꥢ����
    $c->_clc_obj->_view_priority(undef);

    # model��ͥ���٤򥯥ꥢ����
    $c->_clc_obj->_model_priority(undef);

    # $c->_clc_obj->_load_list_flg()�򥯥ꥢ����
    $c->_clc_obj->_load_list_flg( {} );

    # $c->_clc_obj->_params()�򥯥ꥢ����
    $c->_clc_obj->_params(undef);

    $c->_clc_obj->_form_name_join_str( {} );
    $c->_clc_obj->_form_name_plus_str( {} );

    $c->_clc_obj->_plus_str_stock( {} );

    if ( $c->debug ) {
        $c->log->debug('+ End                            +');
    }
    $c->log->debug('++++++++++++++++++++++++++++++++++');
    $c->NEXT::prepare(@_);
}

=item setup

Catalyst��ư���ν����Ǥ���
ClassConfig�����������Ѥ��륪�֥������Ȥ�������ޤ���

=cut

sub setup {
    my $c = shift;
    $c->log->debug('Create Catalyst::ClassConfig object') if ( $c->debug );
    my $clc_obj = Catalyst::ClassConfig::Object->new();
    $c->_clc_obj($clc_obj);
    my $class = $c->config()->{'name'};
    $c->NEXT::setup(@_);
}

=item setup_actions

Catalyst��ư���ν����Ǥ���
Catalyst�����ɤ�������ݡ��ͥ�Ȥ��⥸�塼��������������
������б���������ե����ե��������ɤ��ޤ���

=cut

sub setup_actions {
    my $c = shift;
    foreach my $name ( keys( %{ $c->components } ) ) {
        $c->clc($name)->_load_config();
    }
    if ( $c->debug ) {
        my $t = Text::SimpleTable->new( [ 24, 'Namespace' ], [ 48, 'ConfigFile' ], [ 48, 'Class' ] );
        my %classmap;
        foreach my $class ( sort keys( %{ $c->_clc_obj->_namespace_map } ) ) {
            $classmap{ $c->_clc_obj->_namespace_map->{$class} } = []
                unless ( $classmap{ $c->_clc_obj->_namespace_map->{$class} } );
            push( @{ $classmap{ $c->_clc_obj->_namespace_map->{$class} } }, $class );
        }
        foreach my $namespace ( sort keys(%classmap) ) {
            my $p_namespace = $namespace;
            my $configfile  = $c->_clc_obj->_configfile_map->{ $classmap{$namespace}->[0] };
            next unless ($configfile);
            my $root = $c->config->{'root'};
            $configfile =~ s/$root/\[ROOT\]/g;
            foreach my $class ( @{ $classmap{$namespace} } ) {
                $t->row( $p_namespace, $configfile, $class );
                $configfile  = '';
                $p_namespace = '';
            }
        }
        $c->log->debug( "Loaded config files:", $t->draw );
    }
    $c->NEXT::setup_actions(@_);
}

=item clc

ClassConfig�ε�ǽ�˥����������뤿��δؿ��Ǥ���
ɬ����ʬ���ȤΥ��֥������ȡ��ޤ��ϥ��饹̾���Ϥ��Ƥ���������
ex) $c->clc($self) or $c->clc('MyApp::C::MyController');

=cut

sub clc {
    my $c    = shift;
    my $self = shift;

    $c->_clc_obj()->_self($self);
    $c->_clc_obj()->_c($c);
    return $c->_clc_obj();
}

1;

package Catalyst::ClassConfig::Object;

use strict;
use base 'Class::Accessor::Fast';
use Clone 'clone';

use Data::Dumper;

=head1 NAME

Catalyst::ClassConfig::Object - ClassConfig�����ΤǤ���

=head1 DESCRIPTION



=cut

=over 4

=item new

=cut

sub new {
    my ($pkg) = @_;

    my $this = bless( {}, $pkg );
    $this->mk_accessors(
        '_config_backup',  '_config',             '_self',          '_c',
        '_schema_map',     '_classname_map',      '_namespace_map', '_configfile_map',
        '_params',         '_load_list_flg',      '_view_priority', '_model_priority',
        '_plus_str_stock', '_form_name_join_str', '_form_name_plus_str'
    );
    $this->_config_backup(  {} );
    $this->_config(         {} );
    $this->_schema_map(     {} );
    $this->_namespace_map(  {} );
    $this->_classname_map(  {} );
    $this->_configfile_map( {} );
    $this->_params(undef);
    $this->_load_list_flg(      {} );
    $this->_plus_str_stock(     {} );
    $this->_form_name_join_str( {} );
    $this->_form_name_plus_str( {} );
    return $this;
}

=item class_stash


=cut

sub class_stash {
    my $self = shift;
    $self->_c->stash->{'ClassConfig'}->{ $self->get_namespace } = {}
        unless ( $self->_c->stash->{'ClassConfig'}->{ $self->get_namespace } );
    return $self->_c->stash->{'ClassConfig'}->{ $self->get_namespace };
}

=item load

����ե����ե����������Ū�˥��ɤ��ޤ���
NotClone��Ω�äƤ��ʤ����Ϥ��Υꥯ�����ȤΤߤ�ͭ���Ǥ�

=cut

sub load_config {
    my $this = shift;
    my $file = shift;
    $this->_load_config( $file, 1 );
}

##################################################
# ����ե�������ɤ���ؿ�
#
##################################################
sub _load_config {
    my $this = shift;
    my $c    = $this->_c();

    my $classname = ref( $this->_self ) ? ref( $this->_self ) : $this->_self;

    my $namespace = $this->get_namespace();
    return undef unless ($namespace);

    my $file = shift;
    $file = $this->_gen_configfile( $namespace, $file );

    return 0 unless ( $file && length($file) > 0 && -f $file );
    $this->_configfile_map()->{$classname} = $file;

    my $force = shift;
    return 0 if ( ( $this->_config->{$namespace} or $this->_config_backup->{$namespace} ) and !$force );

    my ($ext) = $file =~ m/\.([\w]+)$/;
    my $config;
    if ( $ext =~ /^(p|P)(l|L)$/ ) {
        $config = do($file);
        die "$@" if ($@);
    }
    else {
        $c->log->debug("ClassConfig : config load routine undefined !! ($file) ($ext)");
    }
    if ( ( ref( $c->config->{'ClassConfig'} ) eq 'HASH' and $c->config->{'ClassConfig'}->{'NotClone'} )
        or $force )
    {

        #	$c->log->debug('ClassConfig : Load config to master');
        $this->_config()->{$namespace} = $config;
    }
    else {

        #	$c->log->debug('ClassConfig : Load config to mirror');
        $this->_config_backup()->{$namespace} = $config;
    }
    $this->_gen_schema_map();
}

##### load_list��⤦���ټ¹Ԥ���list�򹹿����������˻��Ѥ��Ƥ���������
sub reload_list {
    my $this      = shift;
    my $namespace = $this->get_namespace();
    $this->_load_list_flg->{$namespace} = 0;
    $this->_load_list;
}

sub _load_list {
    my $this      = shift;
    my $namespace = $this->get_namespace();
    return if ( $this->_load_list_flg->{$namespace} );

    my $config = $this->_config()->{$namespace};

    #    $this->_c()->log()->debug('���� Class::Config('.
    #			      (ref($this->_self) ? ref($this->_self) : $this->_self).
    #			      ') _load_list ����');
    foreach my $schema ( @{ $config->{'schema'} } ) {
        next
            unless ( $schema
            or $schema->{'form'}
            or $schema->{'form'}->{'type'}
            or $schema->{'sql'}
            or $schema->{'sql'}->{'references'} );
        if ((      $schema->{'form'}->{'type'} eq 'select'
                or $schema->{'form'}->{'type'} eq 'radio'
                or $schema->{'form'}->{'type'} eq 'hidden_with_label' || $schema->{'form'}->{'type'} eq 'hidden'
            )
            && $schema->{'sql'}->{'references'}
            && length( $schema->{'sql'}->{'references'} ) > 0
            )
        {

            # _load_list��config��Ƥ��٤˸ƤФ�뤿�ᡢ
            # ��¸���Ƥ���ꥹ�Ȥ����Ǥ򤹤٤ƺ������
            if ( $schema->{'list'} ) {
                $schema->{'list'} = [];
            }

            # name ���ʤ��Ȥ��� sql->references->desc �� name �����Υ����̾������뤳��
            my $name = $schema->{'sql'}->{'references'}->{'name'} || 'id';
            my $desc = $schema->{'sql'}->{'references'}->{'desc'} || 'name';

            # ���ȥơ��֥뤫�鸡����̤�list�ˤĤä���
            push @{ $schema->{'list'} }, { 'name' => '', 'desc' => '' }
                if ( $schema->{'form'}->{'type'} eq 'select' );    # ̵�����Ѥ�Ƭ�˶��ι��ܤ���������
            my (%where) =
                ( ref $schema->{'sql'}->{where} eq 'HASH' )
                ? %{ $schema->{'sql'}->{where} }
                : ( disable => [0] );
            my (%order_by) =
                ( ref $schema->{'sql'}->{order_by} eq 'HASH' )
                ? %{ $schema->{'sql'}->{order_by} }
                : ( order_by => 'id' );

            ##### %where��value������Υ�ե���󥹤���ʤ������Ѵ����ޤ���
            %where = map { ref $where{$_} eq 'ARRAY' ? ( $_ => $where{$_} ) : ( $_ => [ $where{$_} ] ) } keys(%where);

            ######

            if ( $schema->{'sql'}->{'references'}->{'class'}->can('search_where') ) {
                foreach my $result ( $schema->{'sql'}->{'references'}->{'class'}->search_where( \%where, \%order_by ) )
                {
                    push @{ $schema->{'list'} }, { 'name' => $result->$name(), 'desc' => $result->$desc() };
                }
            }

            #$this->_c->log->debug("$schema->{'name'} : schema->{'list'}\n", Dumper($schema->{'list'}))
        }
    }
    $this->_load_list_flg->{$namespace} = 1;
}

=item config

=cut

sub config {
    my $this      = shift;
    my $c         = $this->_c();
    my $namespace = $this->get_namespace();

    #    ��Class��getConfig��������Ƥ����ȡ����ä���ͥ�褷�ƻȤ��äƻ������ɡ�������
    #    �����Ǥ�_config��ȤäƤ�����ʡ��ɤ�����
    #    return $this->_self()->getConfig()
    #	if(ref($this->_self()) and !(grep(ref($this->_self() ne $_, qw(SCALAR ARRAY HASH))))
    #	   and $this->_self()->can('getConfig'));
    return undef unless ($namespace);
    $this->_config()->{$namespace} = {} unless $this->_config()->{$namespace};
    my $config = $this->_config()->{$namespace};
    $this->_load_list();
    return $config;
}

=item schema

=cut

sub schema {
    my $this = shift;

    #    my @keys = @_;
    no warnings;
    my $key       = shift;
    my $c         = $this->_c();
    my $namespace = $this->get_namespace();
    return undef unless ($namespace);
    return undef unless ( $this->_config()->{$namespace} );
    return undef unless ( $this->_config()->{$namespace}->{'schema'} );
    $this->_load_list();

    if ($key) {
        return $this->_config()->{$namespace}->{'schema'}->[ $this->_schema_map()->{$namespace}->{$key} ];
    }
    else {
        return wantarray ? @{ $this->_config()->{$namespace}->{'schema'} } : $this->_config()->{$namespace}->{'schema'};
    }

    #    if(scalar @keys > 0) {
    #	my @returns;
    #	foreach my $key (@keys) {
    #	    next unless(defined $this->_schema_map()->{$namespace}->{$key});
    #	    push(@returns, $this->_config()->{$namespace}->{'schema'}->[$this->_schema_map()->{$namespace}->{$key}]);
    #	}
    #	return wantarray ? @returns : \@returns;
    #    } else {
    #	return wantarray ? @{$this->_config()->{$namespace}->{'schema'}} : $this->_config()->{$namespace}->{'schema'};
    #    }
}

=item properties

schema��name�Υꥹ�Ȥ��֤�

=cut

sub properties {
    my $this      = shift;
    my $c         = $this->_c();
    my $namespace = $this->get_namespace();
    return undef unless ($namespace);
    return undef unless ( $this->_schema_map()->{$namespace} );

    return sort { $this->_schema_map->{$namespace}->{$a} <=> $this->_schema_map->{$namespace}->{$b} }
        keys( %{ $this->_schema_map()->{$namespace} } );
}

=item getController

=cut

sub getController {
    my $this = shift;
    return $this->_self()->getController()
        if ( ref( $this->_self() ) and $this->_self()->can('getController') );
    return $this->_get_classname('C');
}

=item setController

=cut

sub setController {
    my $this = shift;
    my $name = shift;
    return $this->_set_classname( 'C', $name );
}

=item getView

=cut

sub getView {
    my $this = shift;
    return $this->_self()->getView()
        if ( ref( $this->_self() ) and $this->_self()->can('getView') );
    return scalar $this->_get_classname('V');
}

=item setView

=cut

sub setView {
    my $this = shift;
    my $name = shift;
    return scalar $this->_set_classname( 'V', $name );
}

=item getViews

=cut

sub getViews {
    my $this = shift;
    return ( $this->_get_classname('V') );
}

=item setViewType

ʣ����View�����ä����ˡ����ꤵ��Ƥ�prefix��view��ͥ�褵����

=cut

sub setViewType {
    my $this = shift;
    my $type = shift;
    $this->_view_priority($type);
}

=item getModel

=cut

sub getModel {
    my $this = shift;
    return $this->_self()->getModel()
        if ( ref( $this->_self() ) and $this->_self()->can('getModel') );
    return scalar $this->_get_classname('M');
}

=item setModel

=cut

sub setModel {
    my $this = shift;
    my $name = shift;
    $this->_set_classname( 'M', $name );
}

=item getModels

=cut

sub getModels {
    my $this = shift;
    return ( $this - _get_classname('M') );
}

=item setModelType

=cut

sub setModelType {
    my $this = shift;
    my $type = shift;
    $this->_model_priority($type);
}

=item get_namespace

=cut

sub get_namespace {
    my ($this)  = @_;
    my $c       = $this->_c();
    my $self    = $this->_self();
    my $appname = $c->config->{'name'};
    my $classname = ref($self) ? ref($self) : $self;
    return $this->_namespace_map()->{$classname} if ( $this->_namespace_map()->{$classname} );
    return $classname unless ( $classname =~ /^$appname/ );

    my $namespace = $classname;
    $namespace =~ s/^$appname//;
    return undef unless ( length($namespace) );
    $namespace =~ s/^\:\:(Controller|Model|View|[CMV])//;
    my $type = substr( $1, 0, 1 );
    if ( ref( $c->config()->{'ClassConfig'} ) eq 'HASH' ) {

        #	$c->log->debug("\$classanme=$classname");
        if ( $classname =~ /^$appname\:\:(Model|M)/
            and ref( $c->config()->{'ClassConfig'}->{'ModelPrefix'} ) eq 'ARRAY' )
        {
            my @prefixs = @{ $c->config()->{'ClassConfig'}->{'ModelPrefix'} };
            if ( my ($prefix) = grep( $classname =~ /^$appname\:\:(Model|M)\:\:$_\:\:/, @prefixs ) ) {
                $namespace =~ s/\:\:$prefix//;
            }

            # 	    foreach my $suffix (@{$c->config()->{'ClassConfig'}->{'ModelPrefix'}}) {
            # 		$namespace =~ s/\:\:$suffix//;
            # 	    }
        }
        elsif ( $classname =~ /^$appname\:\:(View|V)/
            and ref( $c->config()->{'ClassConfig'}->{'ViewPrefix'} ) eq 'ARRAY' )
        {
            my @prefixs = @{ $c->config()->{'ClassConfig'}->{'ViewPrefix'} };
            if ( my ($prefix) = grep( $classname =~ /^$appname\:\:(View|V)\:\:$_\:\:/, @prefixs ) ) {
                $namespace =~ s/\:\:$prefix//;
            }

            # 	    foreach my $suffix (@{$c->config()->{'ClassConfig'}->{'ViewPrefix'}}) {
            # 		    $namespace =~ s/\:\:$suffix//
            # 			if($classname =~ /^$appname\:\:(View|V)\:\:$suffix\:\:/);
            # 	    }
        }
    }
    $namespace =~ s/^\:\://;
    return undef unless ( length($namespace) );
    $this->_namespace_map()->{$classname} = $namespace;
    unless ( $this->_classname_map->{$namespace} ) {
        $this->_classname_map->{$namespace} = {};
        $this->_classname_map->{$namespace}->{$type} = [];
    }
    push( @{ $this->_classname_map->{$namespace}->{$type} }, $classname );
    return $namespace;
}

=item req_params

=cut

sub req_params {
    my $this      = shift;
    my $namespace = $this->get_namespace();
    my $plus      = $this->get_form_plus_str;

    unless ( ref( $this->_params ) eq 'HASH' ) {
        $this->_gen_req_params;
    }
    if (wantarray) {
        return () unless ( $this->_params->{$namespace} );
        return %{ $this->_params->{$namespace}->{$plus} } || ();
    }
    else {
        return {} unless ( $this->_params->{$namespace} );
        return clone( $this->_params()->{$namespace}->{$plus} ) || {};
    }
}

=item req_param

=cut

sub req_param {
    my $this      = shift;
    my $name      = shift;
    my $namespace = $this->get_namespace();
    my $plus      = $this->get_form_plus_str;

    unless ( ref( $this->_params() ) eq 'HASH' ) {
        $this->_gen_req_params();
    }
    return undef unless ( ref( $this->_params->{$namespace} )          eq 'HASH' );
    return undef unless ( ref( $this->_params->{$namespace}->{$plus} ) eq 'HASH' );

    # $name���Ϥ���Ƥ��ʤ�����̾���Υꥹ�Ȥ��֤�
    unless ($name) {
        return keys( %{ $this->_params()->{$namespace}->{$plus} } );
    }
    else {
        return clone( $this->_params()->{$namespace}->{$plus}->{$name} );
    }
}

=item get_form_prefix

�������줿�ե������̾�����뤿��ˡ�
����������ʬ���֤�

=cut

sub get_form_prefix {
    my $this   = shift;
    my $joiner = $this->get_form_delimiter;
    my $plus   = $this->get_form_plus_str;
    return join( $joiner, $this->get_namespace(), $plus ) . $joiner;
}

=item get_form_delimiter

=cut

sub get_form_delimiter {
    return $_[0]->_form_name_join_str()->{ $_[0]->get_namespace } || '_D_';
}

=item get_form_plus_str

=cut

sub get_form_plus_str {
    return $_[0]->_form_name_plus_str()->{ $_[0]->get_namespace } || '_P_';
}

=item set_form_delimiter

=cut

sub set_form_delimiter {
    return $_[0]->_form_name_join_str()->{ $_[0]->get_namespace } = $_[1];
}

=item set_form_plus_str

=cut

sub set_form_plus_str {
    return $_[0]->_form_name_plus_str()->{ $_[0]->get_namespace } = $_[1];
}

=item get_next_plus_str

=cut

sub get_next_plus_str {
    my $this = shift;
    $this->_plus_str_stock()->{ $this->get_namespace } = 0
        unless ( $this->_plus_str_stock()->{ $this->get_namespace } );
    $this->_plus_str_stock()->{ $this->get_namespace }++;
    return sprintf( '_%d_', $this->_plus_str_stock()->{ $this->get_namespace } );
}

=item clear_form_delimiter

=cut

sub clear_form_delimiter {
    my $this = shift;
    $this->_form_name_join_str( {} );
}

=item clear_form_plus_str

=cut

sub clear_form_plus_str {
    my $this = shift;
    $this->_plus_str_stock(     {} );
    $this->_form_name_plus_str( {} );
}

##################################################
#
##################################################
sub _gen_req_params {
    my $this = shift;
    my $c    = $this->_c();

    my $joiner = $this->get_form_delimiter;

    my $tmp_hash = $c->req->params();
    my %hash;
    while ( my ( $tmp_key, $val ) = each %{$tmp_hash} ) {

        #	my ($name,  $key) = split/_:_/, $tmp_key;
        #	$hash{$name} = {} unless($hash{$name});
        #	$hash{$name}->{$key} = $val;
        my ( $name, $plus, $key ) = split /$joiner/, $tmp_key;
        next unless ($plus);
        $hash{$name} = {} unless ( $hash{$name} );
        $hash{$name}->{$plus} = {} unless ( $hash{$name}->{$plus} );
        $hash{$name}->{$plus}->{$key} = $val;
    }
    $this->_params( \%hash );
}

=item set_req_params

$c->clc($self)->set_req_params(\%hash);

=cut

sub set_req_params {
    my $this = shift;
    my $c    = $this->_c();
    my $hash = shift;

    my $namespace = $this->get_namespace();
    my $plus      = $this->get_form_plus_str;

    die "\$hash isn't HASH REF" unless ( ref($hash) eq 'HASH' );

    $this->_params( {} ) unless ( ref( $this->_params ) eq 'HASH' );
    $this->_params->{$namespace} = {} unless ( $this->_params->{$namespace} );
    $this->_params->{$namespace}->{$plus} = {} unless ( $this->_params->{$namespace}->{$plus} );

    foreach my $key ( keys( %{$hash} ) ) {
        $this->_params()->{$namespace}->{$plus}->{$key} = $hash->{$key};
    }
}

=item set_req_param

=cut

sub set_req_param {
    my $this = shift;
    my $name = shift;
    my $val  = shift;

    #    return unless($val); undef �ͤ���ʤ���ޤ����ä���

    my $namespace = $this->get_namespace;
    my $plus      = $this->get_form_plus_str;

    $this->_params( {} ) unless ( ref( $this->_params ) eq 'HASH' );
    $this->_params->{$namespace} = {} unless ( $this->_params->{$namespace} );
    $this->_params->{$namespace}->{$plus} = {} unless ( $this->_params->{$namespace}->{$plus} );

    $this->_params->{$namespace}->{$plus}->{$name} = $val;
}

##################################################
#
##################################################
sub _set_classname {
    my $this = shift;
    my $type = shift;
    my $name = shift;

    my $namespace = $this->get_namespace();
    $this->_classname_map->{$namespace}->{$type} = [$name];
}

##################################################
#
##################################################
sub _get_classname {
    my $this = shift;
    my $type = shift;

    my $appname = $this->_c->config->{'name'};

    my $namespace = $this->get_namespace();
    return undef unless ($namespace);
    return undef unless ( $this->_classname_map->{$namespace}->{$type} );
    if (wantarray) {
        return @{ $this->_classname_map->{$namespace}->{$type} };
    }
    elsif ( $type eq 'V' and $this->_view_priority() ) {
        my $p_view = $this->_view_priority();
        if ( grep( $_ =~ /^$appname\:\:(View|V)\:\:$p_view/, @{ $this->_classname_map->{$namespace}->{$type} } ) ) {
            return (
                grep( $_ =~ /^$appname\:\:(View|V)\:\:$p_view/, @{ $this->_classname_map->{$namespace}->{$type} } ) )
                [0];
        }
        else {
            return $this->_classname_map->{$namespace}->{$type}->[0];
        }
    }
    elsif ( $type eq 'M' and $this->_model_priority() ) {
        my $p_model = $this->_model_priority();
        if ( grep( $_ =~ /^$appname\:\:(Model|M)\:\:$p_model/, @{ $this->_classname_map->{$namespace}->{$type} } ) ) {
            return (
                grep( $_ =~ /^$appname\:\:(Model|M)\:\:$p_model/, @{ $this->_classname_map->{$namespace}->{$type} } ) )
                [0];
        }
        else {
            return $this->_classname_map->{$namespace}->{$type}->[0];
        }
    }
    else {
        $this->_classname_map->{$namespace}->{$type}->[0];
    }
}

##################################################
#
##################################################
sub _gen_schema_map {
    my ($this) = @_;
    my $namespace = $this->get_namespace();
    return undef unless ($namespace);
    my %hash;
    if ( ref( $this->_config()->{$namespace}->{'schema'} ) eq 'ARRAY' ) {
        for ( my $i = 0; $i < scalar @{ $this->_config()->{$namespace}->{'schema'} }; $i++ ) {
            $hash{ $this->_config()->{$namespace}->{'schema'}->[$i]->{'name'} } = $i;
        }
    }
    elsif ( ref( $this->_config_backup()->{$namespace}->{'schema'} ) eq 'ARRAY' ) {
        for ( my $i = 0; $i < scalar @{ $this->_config_backup->{$namespace}->{'schema'} }; $i++ ) {
            $hash{ $this->_config_backup()->{$namespace}->{'schema'}->[$i]->{'name'} } = $i;
        }
    }
    $this->_schema_map()->{$namespace} = \%hash;
    return 1;
}

##################################################
#
##################################################
sub _gen_configfile {
    my ( $this, $namespace, $file ) = @_;
    my $c   = $this->_c();
    my $dir = 'config';
    if ( ref( $c->config()->{'ClassConfig'} ) eq 'HASH'
        and $c->config()->{'ClassConfig'}->{'dir'} )
    {
        $dir = $c->config()->{'ClassConfig'}->{'dir'};
    }
    $dir = '' if ( $file && $file =~ /^$dir/ );

    unless ($file) {
        my $conf_find = sprintf( '%s/%s/%s.*', $c->config->{'home'}, $dir, $namespace );
        $conf_find =~ s!\:\:!\/!g;
        ($file) = ( glob($conf_find) )[0];
    }
    else {
        $file = sprintf( '%s/%s/%s', $c->config->{'home'}, $dir, $file );
        $file =~ s!//!/!g;
    }
    return $file;
}

=head1 SEE ALSO

L<Catalyst>

=head1 AUTHOR

Shota Takayama, E<lt>shot@bindstorm.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Shota Takayama and Shanon, Inc.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut

1;
__END__
