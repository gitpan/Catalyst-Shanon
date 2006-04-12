package Catalyst::Controller::ADVEL;

use strict;
use warnings;
use Date::Calc qw(:all);

my ($Revision) = '$Id: ADVEL.pm,v 1.148 2006/04/12 08:37:26 shimizu Exp $';
our $VERSION = '0.01';

use base qw(Catalyst::Controller Catalyst::Model::ShanonConfig);
use Class::Trigger;
use Data::Dumper;

=head1 NAME

Catalyst::Controller::ADVEL - Scaffolding Controller Component (Add Delete View Edit List)

=head1 SYNOPSIS

  package MyApp::Controller::MyController;
  use base 'Catalyst::Controller::ADVEL';

=head1 DESCRIPTION

基本的な「登録」「削除」「表示」「編集」「一覧」の機能を提供するための
ベースオブジェクト。

=head1 METHODS

=head2 action_switcher

アクションを切り替えるための関数

Catalyst::Plugin::ClassConfigを使用している場合は、
config->{'actions'}->{add|delete|disable}から配列リファレンスを取得し、
それを使います。

トリガー：

=over 1

=item $self->set_actions($c, \@actions);

=back

次のアクションに進むためには
$c->stash->{'ADVEL_OK'}->{$self->get_clc($c)->get_namespace}->{'アクション名'}が真である必要があります。
各アクションで0をreturnしてください。

=cut

sub action_switcher : Private {
    my $self = shift;
    my $c    = shift;
    my $type = $c->stash->{'ADVEL_action_type'};
    delete $c->stash->{'ADVEL_action_type'};
    $c->log->info( 'ADVEL : ' . ref($self) . ' : action_switcher' );
    my @actions;

    # addの場合
    if ( $type eq 'add' ) {

        #@actions = qw(input confirm do_add);
        @actions = qw(input do_add);
    }

    # deleteの場合
    elsif ( $type eq 'delete' ) {
        @actions = qw(pre_delete do_delete);
    }

    # disableの場合
    elsif ( $type eq 'disable' ) {
        @actions = qw(pre_disable do_disable);
    }

    # viewの場合
    elsif ( $type eq 'view' ) {
        @actions = qw(preview);
    }

    # csvuploadの場合
    elsif ( $type eq 'csvupload' ) {

        # 動的にコンフィグを生成する
        my $hash;
        $hash->{findrow}      = 'invisible';
        $hash->{metarow}      = 'invisible';
        $hash->{desc}         = 'CVSファイル';
        $hash->{form}->{type} = 'file';
        $hash->{name}         = 'csvupload_csv_file';
        $hash->{temporary}    = '1';
        push @{ $self->get_clc($c)->_config()->{ $self->get_clc($c)->get_namespace }->{'schema'} }, $hash;
        $self->get_clc($c)->_gen_schema_map();

        # add.html の代わりに csvupload を使う
        $c->stash->{add_file} = 'csvupload';
        @actions = qw(input do_csvupload);
    }

    # 各コントローラの初期化メソッドを呼ぶ
    $self->initialize($c);

    # configにてactionセットの指定があればそれを使う
    @actions = @{ $self->get_clc($c)->config()->{'actions'}->{$type} }
        if (ref( $self->get_clc($c)->config()->{'actions'} ) eq 'HASH'
        and ref( $self->get_clc($c)->config()->{'actions'}->{$type} ) eq 'ARRAY' );

    # 最後にlistに戻るために
    push( @actions, 'default' );

    # actionセットをオーバーライドするためのトリガー
    $self->call_trigger( 'set_actions', $c, \@actions, $type );

    # actionセットをループで回す
    foreach my $action (@actions) {

        # actionから0が帰ってこなければそこで終了する
        my @next_action;
        if ( ref($action) eq 'ARRAY' ) {
            @next_action = @{$action};
        }
        else {
            $next_action[0] = $action;
        }
        $self->call_trigger( 'action_switcher_check_action', $c, \@next_action );

        #	last if($c->forward(@next_action));
        #	return 1 if($c->forward(@next_action));

        my $rt = $c->forward(@next_action);
        $c->log->info( 'ADVEL : action_switcher : ' . ref($self) . " @next_action returned $rt" );
        $c->log->info( 'ADVEL : action_switcher : ' . ref($self) . " @next_action \$c->error is : ",
            Dumper( $c->error ) );
        if ( ref( $c->error ) eq 'ARRAY' and scalar @{ $c->error } > 0 ) {
            $rt = 1;
        }
        return 1 if ($rt);
    }
    return 0;
}

=head2 input

入力画面を表示するための内部アクション

トリガー：

=over 8

=item $self->input_before($c);

=item $self->input_before_check_errors($c, $hash);

=item $self->input_check($c);

=item $self->input_after_retreive($c);

=item $self->input_after_get_from_req($c);

=item $self->input_after_gen_first_data($c);

=item $self->input_view($c, \@view);

=item $self->input_after($c);

=back

=cut

sub input : Private {
    my $self = shift;
    my $c    = shift;

    # input内最初に呼ばれるトリガー
    $self->call_trigger( 'input_before', $c );

    # inputアクションに入ったことを知らせる
    $c->log->info( 'ADVEL : ' . ref($self) . ' : input' );

    # エラーチェック
    # inputからSubmitされた場合($c->req->param('action')が$self->get_clc($c)->get_namespace.'/'.input)のみ調べる
    # エラーチェックから0が帰ってくればflgを立てる
    ## namespace -----------------------------
    if (    $c->session->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'input'}
        and $c->req->param('action') )
    {
        my $hash = $self->get_clc($c)->req_params();
        $self->call_trigger( 'input_before_check_errors', $c, $hash );
        $c->stash->{'error_check_data'} = $hash;

      #	$c->log->debug("---------------------------------------------------------エラーチェックやってるもん".ref $self);
      #	unless($c->check_all_errors($self,qw(id disable))) {
        my $rt;

        # csvupload ではエラーチェックを省きます
        if ( $c->action->name() eq 'csvupload' ) {
            $rt = 0;
        }
        else {
            $rt = $c->check_all_errors( $self, qw(id disable) );
        }
        $c->log->info( 'ADVEL : ' . ref($self) . ' : input : check_all_errors : rt : ' . $rt );
        unless ($rt) {

            # namespace
            $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'input'} = 1;

            # check_all_errorsがOKなので、OKな値をreqに戻してやる
            $self->get_clc($c)->set_req_params($hash);

            #	    $self->get_clc($c)->_params()->{$self->get_clc($c)->get_namespace} = $hash;
        }
        else {

            # エラーだった場合にstashの中身を消す
            delete $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'input'};
        }
    }

    # 次のページに飛んで良いか判断するためのトリガー
    $self->call_trigger( 'input_check', $c );

    # input のフラグが真だったら次のアクションに逝く
    # namespace ------------------------------
    if ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'input'} ) {
        $c->log->info( 'ADVEL : ' . ref($self) . ' : input : check is OK. go next' );
        return 0;
    }

    $self->call_trigger( 'input_after_check', $c );

    # この画面が誰かを設定する
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );

    # namespace ------------------------------
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/input';

    # この画面を表示したフラグを立てる
    $c->session->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'input'} = 1;

    # モデルを取得する
    my $model = $self->get_model($c);
    $c->log->info( 'ADVEL : ' . ref($self) . " : input - model = $model" );

    # 引数があったらretrieveしてみる
    if ( $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        $self->retrieve_for_input( $c, $model );
    }

    # パラメータが飛んできたら取ってみる
    elsif ( keys( %{ $self->get_clc($c)->req_params } ) ) {
        $c->stash->{'form_data'} = $self->get_clc($c)->req_params;
        $self->call_trigger( 'input_after_get_from_req', $c );
    }

    # それ以外は空っぽですよ？
    else {
        $c->stash->{'form_data'} = {};
        foreach my $name (qw(id date_regist date_update)) {
            next unless ( $self->get_clc($c)->schema($name) );
            $c->stash->{'form_data'}->{$name} = '----';
        }
        $self->call_trigger( 'input_after_gen_first_data', $c );
    }

    # Viewを取得する
    my @view;

    #if($self->get_clc($c)->getView()) {
    #    push(@view, $self->get_clc($c)->getView());
    #    push(@view, 'input');
    #}
    $self->get_view( $c, \@view, 'input' );

    # 画面を表示するViewをいじるためのトリガー
    $self->call_trigger( 'input_view', $c, \@view );
    $c->log->info( 'ADVEL : ' . ref($self) . " : input - view = @view" );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : input : next forward is undefined !!' ) unless (@view);

    # 次のアクションへ
    $c->forward(@view);

    # 最後に走るトリガー
    $self->call_trigger( 'input_after', $c );
    return 1;
}

## 外に出しちゃいました。ここをオーバーライドしたくて。。
sub retrieve_for_input : Private {
    my $self  = shift;
    my $c     = shift;
    my $model = shift;

    return 0 unless defined($model);
    my $data = $model->retrieve( $c->req->args->[0] );
    $c->log->info(
        sprintf(
            qq!ADVEL : input : %s : retrieve(%d) : %s!,
            ref $model,
            $c->req->args->[0],
            defined $data ? 'Found' : 'NotFound'
        )
    );

    # retrieveできなきゃ死ぬ エラーメッセージはとりあえず据え置き
    unless ($data) {
        $c->stash->{'model'}     = undef;
        $c->stash->{'form_data'} = undef;
        die 'Can not retrieve ' . $c->req->args->[0];
    }
    $c->stash->{'form_data'} = $data->toHashRef();
    if ( $self->get_clc($c)->schema('date_update') and !$c->stash->{'form_data'}->{'date_update'} ) {
        $c->stash->{'form_data'}->{'date_update'} = '----';
    }
    $c->log->debug( 'ADVEL : ' . ref($self) . ' : input : ', Dumper( $c->stash->{'form_data'} ) );
    $c->stash->{'model'} = $data;
    $self->call_trigger( 'input_after_retrieve', $c );
}

=head2 confirm

確認画面を表示するための内部アクションです。

トリガー：

=over 4

=item $self->confirm_before($c);

=item $self->confirm_check($c);

=item $self->confirm_view($c, \@view);

=item $self->confirm_after($c);

=back

=cut

sub confirm : Private {
    my $self = shift;
    my $c    = shift;

    # 最初に走るトリガー
    $self->call_trigger( 'confirm_before', $c );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : confirm' );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : action : ' . $c->req->param('action') );

    # confirm 画面から飛ばされていたらflgを真にする
    $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'confirm'} = 1
        if ( $c->req->param('action') eq $self->get_clc($c)->get_namespace . '/confirm' );

    # 次の画面に行っていいかどうかのトリガー
    $self->call_trigger( 'confirm_check', $c );

    # flgが真ならば次の画面へ行く
    if ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'confirm'} ) {
        $c->log->info( 'ADVEL : ' . ref($self) . ' : confirm : check is OK. go next' );
        return 0;
    }

    # この画面が誰かを設定する
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/confirm';

    # queryからの値を詰める
    #    $c->log->debug('★★★★★ : get_form_plus_str : '.$self->get_clc($c)->get_form_plus_str);
    $c->stash->{'form_data'} = $self->get_clc($c)->req_params();

    # この画面のViewの設定
    my @view;

    #if($self->get_clc($c)->getView) {
    #    push(@view, $self->get_clc($c)->getView());
    #    push(@view, 'confirm');
    #}
    $self->get_view( $c, \@view, 'confirm' );

    $self->call_trigger( 'confirm_view', $c, \@view );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : confirm : next forward is undefined !!' ) unless (@view);

    # Viewへ飛ぶ
    $c->forward(@view);

    $self->call_trigger( 'confirm_after', $c );
    return 1;
}

=head2 do_add

実際に登録を行い、完了画面を表示するための内部アクション

トリガー：

=over 6

=item $self->do_add_before($c);

=item $self->do_add_check($c);

=item $self->do_add_commit_flg($c);

=item $self->do_add_flush_flg($c);

=item $self->do_add_view($c, \@view);

=item $self->do_add_after($c, \$commit_flg);

=back

=cut

sub do_add : Private {
    my $self = shift;
    my $c    = shift;
    my $args = shift;

    # 最初に走るトリガー
    $self->call_trigger( 'do_add_before', $c );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : do_add' );

    # do_addからSubmitされた場合($c->req->param('action')がdo_add)のみflgを立てる
    if ( $c->req->param('action') eq $self->get_clc($c)->get_namespace . '/do_add' ) {
        $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'do_add'} = 1;
    }

    # 次のページに飛ばすかどうかのチェックのためのトリガー
    $self->call_trigger( 'do_add_check', $c, $args );

    # flgが真ならば次の画面へ行く
    if ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'do_add'} ) {
        $c->log->info( 'ADVEL : ' . ref($self) . ' : do_add : check is OK. go next' );
        return 0;
    }

    # この画面が誰かを設定する
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/do_add';

    # 飛んできたqueryをget
    my $hash = $self->get_clc($c)->req_params();

    $c->log->debug( 'ADVEL : ' . ref($self) . ' : do_add : req_params : ', Dumper($hash) );

    # int,date,timestamp型でNOT NULLじゃない値が空文字で入ってきたら
    # hashから抜く（抜かないとDB登録時にエラーになる）
    foreach my $p ( @{ $self->get_clc($c)->schema } ) {
        my $name      = $p->{'name'};
        my $hash_name = exists $hash->{$name} ? $hash->{$name} : '';
        my $sql_type  = exists $p->{'sql'}->{'type'} ? $p->{'sql'}->{'type'} : '';
        my $not_null  = exists $p->{'sql'}->{'notnull'} ? $p->{'sql'}->{'notnull'} : '0';

        # もしschemaに存在している値なのに$hashに存在していなかったら空を詰める
        $hash->{$name} = undef
            if ( !( exists $hash->{$name} )
            and grep( $p->{'form'}->{'type'} eq $_, qw(radio select checkbox scrolling) ) );
        $c->log->debug( sprintf( "name : %s : %s / %s", $name, $hash_name, $sql_type ) );
        if (   ( $sql_type eq 'int' || $sql_type eq 'date' || $sql_type eq 'timestamp with time zone' )
            && !$not_null
            && length($hash_name) == 0 )
        {
            $c->log->debug( sprintf( "deleted name : %s : %s / %s", $name, $hash_name, $sql_type ) );
            delete $hash->{$name};
        }
    }

    # id date_regist date_updateに詰めていた----を消す
    foreach my $name (qw(id date_regist date_update)) {
        my $hash_name = exists $hash->{$name} ? $hash->{$name} : '';
        $c->log->debug("deleted name : $name : $hash_name");
        delete $hash->{$name} if ( $hash_name eq '----' );
    }

    # 自分自身のmodelをget
    my $model = $self->get_model($c);

    my $data;

    # idがあるのでupdate
    if ( $hash->{'id'} ) {

        # 最初にDBから現在のをretrieveして
        $data = $model->retrieve( $hash->{'id'} );

        # 次にqueryの値で上書きする
        my $pure_data = $data->pureHashRef;
        foreach my $column ( grep( $_ ne $model->primary_column->name_lc, map { $_->name_lc } $data->columns() ) ) {

            #	    next unless(exists $hash->{$column});
            next if ( $c->clc($self)->schema($column)->{'temporary'} );
            next if ( $pure_data->{$column} eq $hash->{$column} );
            $data->$column( $hash->{$column} );
        }

        # date_updateがあったら現在値を詰める
        if ( $data->can('date_update') ) {
            $data->date_update('now');
        }
        $self->get_clc($c)->class_stash->{ADVEL_model_update_flag} = 1;
        $data->update($c);
    }

    # ないのでcreate
    else {
        delete $hash->{'id'}      if exists( $hash->{'id'} );
        delete $hash->{'disable'} if exists( $hash->{'disable'} );
        $self->get_clc($c)->class_stash->{ADVEL_model_update_flag} = 0;
        $data = $model->create( $c, $hash ) if ( $model && $model->can('create') );
    }

    if ($data) {
        $c->stash->{'form_data'} = $data->toHashRef();
        $c->stash->{'model'}     = $data;

        #	$c->log->debug('ADVEL : '.ref($self).' : do_add : form_data : ',Dumper($c->stash->{'form_data'}));
    }
    else {
        $c->stash->{'form_data'} = undef;
        $c->stash->{'model'}     = undef;
    }

# トリガーdo_add_commit_flgで$c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_commit'}に真を詰めない限りcommitする
    $self->call_trigger( 'do_add_commit_flg', $c );

# MyApp.pmのendでdbi_commitをかけること ということでここのcommitはさようなら
#    $model->dbi_commit() unless(!$model || $c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_commit'});
# トリガーdo_add_flush_flgで$c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_flush'}に真をを詰めない限りsession中に作ったflgエントリを削除する
    $self->call_trigger( 'do_add_flush_flg', $c );
    unless ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'not_flush'} ) {
        delete $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace };
        delete $c->session->{'ADVEL'}->{ $self->get_clc($c)->get_namespace };
    }

    # 表示するためのviewを取得
    my @view;

    #if($self->get_clc($c)->getView) {
    #    push(@view, $self->get_clc($c)->getView());
    #    push(@view, 'do_add');
    #}
    $self->get_view( $c, \@view, 'do_add' );

    # Viewを変更するためのトリガー
    $self->call_trigger( 'do_add_view', $c, \@view );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : do_add : next forward is undefined !!' ) unless (@view);

    $c->forward(@view);

    $self->call_trigger( 'do_add_after', $c );
    return 1;
}

=head2 pre_disable

無効化の確認画面を表示するための内部アクション

トリガー：

=over 5

=item $self->pre_disable_before($c);

=item $self->pre_disable_check($c);

=item $self->pre_disable_after_form_data($c);

=item $self->pre_disable_view($c, \@view);

=item $self->pre_disable_after($c);

=back

=cut

sub pre_disable : Private {
    my $self = shift;
    my $c    = shift;
    my $args = shift;

    # pre_disable で最初に呼ばれるトリガー
    $self->call_trigger( 'pre_disable_before', $c );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : pre_disable' );

    # 画面遷移チェック
    # pre_disableからSubmitされた場合のみflgを立てる
    $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'pre_disable'} = 1
        if ( $c->req->param('action') eq $self->get_clc($c)->get_namespace . '/pre_disable' );

    # 次の画面に言っていいかどうかのトリガー
    $self->call_trigger( 'pre_disable_check', $c, $args );

    # flgが真ならば次の画面へ行く
    if ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'pre_disable'} ) {
        $c->log->info( 'ADVEL : ' . ref($self) . ' : pre_disable : check is OK. go next' );
        return 0;
    }

    # この画面が誰かを設定する
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/pre_disable';

    # modelを取得する
    my $model = $self->get_model($c);
    $c->log->info( 'ADVEL : ' . ref($self) . " : pre_disable - model = $model" );

    # 第一引数でretrieveする
    my $data;
    if ( $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        $self->retrieve_for_disable( $c, $model, \$data );
    }

#    my $data = $model->retrieve($c->req->args->[0]);
#    $c->log->debug("ADVEL : pre_disable : $model : retrieve(".$c->req->args->[0].") : ".($data ? 'Found' : 'NotFound'));
# retrieveできなきゃ死ぬ エラーメッセージはとりあえず据え置き
#    die 'Can not retrieve '.$c->req->args->[0] unless($data);
#    $c->stash->{'model'} = $data;
#    $c->stash->{'form_data'} = $data->toHashRef();
    $self->call_trigger( 'pre_disable_after_form_data', $c, \$data );

    # 自分自身に必要なViewを取得する
    my @view;

    #if($self->get_clc($c)->getView) {
    #    push(@view, $self->get_clc($c)->getView());
    #    push(@view, 'pre_disable');
    #}
    $self->get_view( $c, \@view, 'pre_disable' );

    # 画面を表示するViewをいじるためのトリガー
    $self->call_trigger( 'pre_disable_view', $c, \@view );
    $c->log->info( 'ADVEL : ' . ref($self) . ' : pre_disable : next forward is undefined !!' ) unless (@view);

    # 次のアクションへ
    $c->forward(@view);

    # 最後に走るトリガー
    $self->call_trigger( 'pre_disable_after', $c );

    return 1;
}

=head2 retrieve_for_disable

削除確認用検索

=cut

sub retrieve_for_disable : Private {
    my $self  = shift;
    my $c     = shift;
    my $model = shift;
    my $data  = shift;
    $self->call_trigger( 'retrieve_form_disable_before', $c );
    $$data = $model->retrieve( $c->req->args->[0] );
    die 'Can not retrieve ' . $c->req->args->[0] unless ($$data);
    $c->log->info(
        sprintf(
            qq!ADVEL : pre_disable : %s : retrieve(%d) : %s!,
            ref $model,
            $c->req->args->[0],
            defined $$data ? 'Found' : 'NotFound'
        )
    );

    if ($$data) {
        $c->stash->{'model'}     = $$data;
        $c->stash->{'form_data'} = $$data->toHashRef();
    }
    else {
        $c->stash->{'form_data'} = undef;
        $c->stash->{'model'}     = undef;
    }
    $self->call_trigger( 'retrieve_for_disable_after', $c );
}

=head2 do_disable

実際に無効化を行い、完了画面を表示するための内部アクション

トリガー：

=over 6

=item $self->do_disable_before($c);

=item $self->do_disable_check($c);

=item $self->do_disable_commit_flg($c);

=item $self->do_disable_flush_flg($c);

=item $self->do_disable_view($c, \@view);

=item $self->do_disable_after($c);

=back

=cut

sub do_disable : Private {
    my $self = shift;
    my $c    = shift;
    my $args = shift;

    $self->call_trigger( 'do_disable_before', $c );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : do_disable' );

    # do_addからSubmitされた場合($c->req->param('action')がdo_disable)のみflgを立てる
    if ( $c->req->param('action') eq $self->get_clc($c)->get_namespace . '/do_disable' ) {
        $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'do_disable'} = 1;
    }

    # 次に飛ばすかどうかのチェックのためのトリガー
    $self->call_trigger( 'do_disable_check', $c );

    # flgが真ならば次の画面へ行く
    if ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'do_disable'} ) {
        $c->log->info( 'ADVEL : ' . ref($self) . ' : do_disable : check is OK. go next' );
        return 0;
    }

    # この画面が誰かを設定する
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/do_disable';

    # modelの取得
    my $model = $self->get_model($c);

    # idでretrieveする
    my $data;
    if ( $self->get_clc($c)->req_param('id') ) {
        $self->retrieve_for_do_disable( $c, $model, \$data );

        #	$data = $model->retrieve($self->get_clc($c)->req_param('id'));
        #	$data->update($c);
    }

    $c->stash->{'model'} = $data;

# トリガーdo_disable_commit_flgで$c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_commit'}に真を詰めない限りcommitする
    $self->call_trigger( 'do_disable_commit_flg', $c );

    # MyApp.pmのendでdbi_commitをかけること ということでここのcommitはさようなら
    #    $model->dbi_commit() unless($c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_commit'});

# トリガーdo_disable_flush_flgで$c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_flush'}に真をを詰めない限りsession中に作ったflgエントリを削除する
    $self->call_trigger( 'do_disable_flush_flg', $c );
    delete $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }
        unless ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'not_flush'} );

    # 表示するためのViewを取得
    my @view;

    #if($self->get_clc($c)->getView()) {
    #    push(@view, $self->get_clc($c)->getView());
    #    push(@view, 'do_disable');
    #}
    $self->get_view( $c, \@view, 'do_disable' );

    # Viewを変更するためのトリガー
    $self->call_trigger( 'do_disable_view', $c, \@view );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : do_disable : next forward is undefined !!' ) unless (@view);

    $c->forward(@view);

    $self->call_trigger( 'do_disable_after', $c );
    return 1;
}

=head2 retrieve_for_do_disable

削除用検索

=cut

sub retrieve_for_do_disable : Private {
    my $self  = shift;
    my $c     = shift;
    my $model = shift;
    my $data  = shift;
    $self->call_trigger( 'retrieve_for_do_disable_before', $c );
    $$data = $model->retrieve( $self->get_clc($c)->req_param('id') );
    $c->log->info(
        sprintf(
            qq!ADVEL : do_disable : %s : retrieve(%d) : %s!,
            ref $model,
            $c->req->args->[0],
            defined $$data ? 'Found' : 'NotFound'
        )
    );

    # disableを立てる
    $$data->disable(1);
    $$data->update($c);
    $self->call_trigger( 'retrieve_for_do_disable_after', $c, $data );
}

=head2 pre_delete

削除の確認画面を表示するための内部アクション

トリガー：

=over 5

    $self->pre_delete_before($c);
    $self->pre_delete_check($c);
    $self->pre_delete_after_form_data($c);
    $self->pre_delete_view($c, \@view);
    $self->pre_delete_after($c);

=back

=cut

sub pre_delete : Private {
    my $self = shift;
    my $c    = shift;

    $self->call_trigger( 'pre_delete_before', $c );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : pre_delete' );

    # 画面遷移チェック
    # pre_deleteからSubmitされた場合のみflgを立てる
    $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'pre_delete'} = 1
        if ( $c->req->param('action') eq $self->get_clc($c)->get_namespace . '/pre_delete' );

    # 次の画面に言っていいかどうかのトリガー
    $self->call_trigger( 'pre_delete_check', $c );

    # flgが真ならば次の画面へ行く
    if ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'pre_delete'} ) {
        $c->log->info( 'ADVEL : ' . ref($self) . ' : pre_delete : check is OK. go next' );
        return 0;
    }

    # この画面が誰かを設定する
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/pre_delete';

    # modelを取得する
    my $model = $self->get_model($c);
    $c->log->info( 'ADVEL : ' . ref($self) . " : pre_delete - model = $model" );

    # 第一引数でretrieveする
    my $data = $model->retrieve( $c->req->args->[0] );
    $c->log->info(
        sprintf(
            qq!ADVEL : pre_delete : %s : retrieve(%d) : %s!,
            ref $model,
            $c->req->args->[0],
            defined $$data ? 'Found' : 'NotFound'
        )
    );

    # retrieveできなきゃ死ぬ エラーメッセージはとりあえず据え置き
    unless ($data) {
        $c->stash->{'form_data'} = undef;
        $c->stash->{'model'}     = undef;
        die 'Can not retrieve ' . $c->req->args->[0];
    }

    $c->stash->{'model'}     = $data;
    $c->stash->{'form_data'} = $data->toHashRef();
    $self->call_trigger( 'pre_delete_after_form_data', $c );

    # 画面を表示するViewを取得する
    my @view;

    #if($self->get_clc($c)->getView()) {
    #    push(@view, $self->get_clc($c)->getView());
    #    push(@view, 'pre_delete');
    #}
    $self->get_view( $c, \@view, 'pre_delete' );

    # 画面を表示するViewをいじるためのトリガー
    $self->call_trigger( 'pre_delete_view', $c, \@view );
    $c->log->info( 'ADVEL : ' . ref($self) . ' : pre_delete : next forward is undefined !!' ) unless (@view);

    # 次のアクションへ
    $c->forward(@view);

    $self->call_trigger( 'pre_delete_after', $c );

    return 1;
}

=head2 do_delete

実際に無効化を行い、完了画面を表示するための内部アクション

トリガー：

=over 6

=item $self->do_delete_before($c);

=item $self->do_delete_check($c);

=item $self->do_delete_commit_flg($c);

=item $self->do_delete_flush_flg($c);

=item $self->do_delete_view($c, \@view);

=item $self->do_delete_after($c);

=back

=cut

sub do_delete : Private {
    my $self = shift;
    my $c    = shift;

    $self->call_trigger('do_delete_before');

    $c->log->info( 'ADVEL : ' . ref($self) . ' : do_delete' );

    # do_addからSubmitされた場合($c->req->param('action')がdo_delete)のみflgを立てる
    if ( $c->req->param('action') eq $self->get_clc($c)->get_namespace . '/do_delete' ) {
        $c->session->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'do_delete'} = 1;
    }

    # 次に飛ばすかどうかのチェックのためのトリガー
    $self->call_trigger( 'do_delete_check', $c );

    # flgが真ならば次の画面へ行く
    if ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'do_delete'} ) {
        $c->log->info( 'ADVEL : ' . ref($self) . ' : do_delete : check is OK. go next' );
        return 0;
    }

    # この画面が誰かを設定する
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/do_delete';

    # modelの取得
    my $model = $self->get_model($c);

    # idでretrieveする
    my $data = $model->retrieve( $self->get_clc($c)->req_param('id') );
    $c->log->info(
        sprintf(
            qq!ADVEL : do_delete : %s : retrieve(%d) : %s!,
            ref $model,
            $self->get_clc($c)->req_param('id'),
            defined $data ? 'Found' : 'NotFound'
        )
    );

    # 消す
    $data->delete($c);

# トリガーdo_delete_commit_flgで$c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_commit'}に真を詰めない限りcommitする
    $self->call_trigger( 'do_delete_commit_flg', $c );

    # MyApp.pmのendでdbi_commitをかけること ということでここのcommitはさようなら
    #    $model->dbi_commit() unless($c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_commit'});

# トリガーdo_delete_flush_flgで$c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_flush'}に真をを詰めない限りsession中に作ったflgエントリを削除する
    $self->call_trigger( 'do_delete_flush_flg', $c );
    delete $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }
        unless ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'not_flush'} );

    # 表示するためのViewを取得
    my @view;

    #if($self->get_clc($c)->getView) {
    #    push(@view, $self->get_clc($c)->getView());
    #    push(@view, 'do_delete');
    #}
    $self->get_view( $c, \@view, 'do_delete' );

    # Viewを変更するためのトリガー
    $self->call_trigger( 'do_delete_view', $c, \@view );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : do_delete : next forward is undefined !!' ) unless (@view);

    $c->forward(@view);

    $self->call_trigger( 'do_delete_after', $c );

    return 1;
}

=head2 preview

確認画面を表示するための内部アクション

トリガー：

=over 5

=item $self->preview_before($c);

=item $self->preview_check($c);

=item $self->preview_after_form_data($c);

=item $self->preview_view($c, \$view);

=item $self->preview_after($c);

=back

=cut

sub preview : Private {
    my $self = shift;
    my $c    = shift;

    $self->call_trigger( 'preview_before', $c );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : preview' );

    $self->call_trigger( 'preview_check', $c );

    return 0
        if ( ref( $c->session->{'ADVEL'}->{ $self->get_clc($c)->get_namespace } )
        and $c->session->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'preview'} );

    my $model = $self->get_model($c);
    $self->call_trigger( 'preview_get_model_after', $c, \$model );
    my $data;
    if ( $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        return 0 unless $self->retrieve_for_preview( $c, $model, \$data );
    }
    $self->call_trigger( 'preview_after_form_data', $c, \$data );

    my @view;

    #if($self->get_clc($c)->getView()) {
    #    push(@view, $self->get_clc($c)->getView());
    #    push(@view, 'preview');
    #}
    $self->get_view( $c, \@view, 'preview' );

    $self->call_trigger( 'preview_view', $c, \@view );

    if ( !$data ) {
        die 'Can not retrieve ' . $c->req->args->[0] unless ( $c->action->namespace =~ /multi/ );
    }

    $c->log->info( 'ADVEL : ' . ref($self) . ' : preview : next forward is undefined !!' ) unless (@view);

    $c->forward(@view);

    $self->call_trigger( 'preview_after', $c );

    return 1;
}

=head2 retrieve_for_preview

詳細用検索

=cut

sub retrieve_for_preview : Private {
    my $self  = shift;
    my $c     = shift;
    my $model = shift;
    my $data  = shift;
    die 'Can not retrieve' if ( $c->req->args->[0] && $c->req->args->[0] =~ /\D/ );
    $self->call_trigger( 'retrieve_for_preview_before', $c );
    $$data = $model->retrieve(
        disable => 0,
        id      => $c->req->args->[0]
    );
    $c->log->info(
        sprintf(
            qq!ADVEL : preview : %s : retrieve(%d) : %s!,
            ref $model,
            $c->req->args->[0],
            defined $$data ? 'Found' : 'NotFound'
        )
    );

    if ($$data) {
        $c->stash->{'model'}     = $$data;
        $c->stash->{'form_data'} = $$data->toHashRef();
    }
    else {
        if ( $c->action->namespace =~ /multi/ ) {
            $c->stash->{'model'}     = undef;
            $c->stash->{'form_data'} = undef;
        }
        else {
            die 'Can not retrieve ' . $c->req->args->[0];
        }
        die 'Can not retrieve ' . $c->req->args->[0] if $c->stash->{force_check_by_multi_in_retrieve_for_preview};
    }
    $self->call_trigger( 'retrieve_for_preview_after', $c );
    return 1;
}

=head2 list_query_for_session

save condition to session or read condition from session

=cut

sub list_query_for_session : Private {
    my $self = shift;
    my $c    = shift;
    $c->log->debug('----- list_query_for_session');

    # クエリを見て保存するかどうかをきめる。
    # submitされていない場合は、ここは空になるので保存されない
    if ( $c->req->param('btn_crear') ) {    # todo スペルちゅうやん
        $c->session->{list_query_temporaly}->{ $self->get_clc($c)->get_namespace } = undef;
        $self->get_clc($c)->set_req_params( {} );
    }
    else {
        my %get;
        $get{$_} = $c->req->param($_) foreach ( $c->req->param() );
        my $hash = \%get;
        if ( scalar keys %{$hash} ) {

            # 値があれば設定する (上書き)
            $c->session->{list_query_temporaly}->{ $self->get_clc($c)->get_namespace } = $hash;
        }
        elsif ( exists $c->session->{list_query_temporaly}->{ $self->get_clc($c)->get_namespace } ) {

            # 値がなければ読み込む
            my $hash = $c->session->{list_query_temporaly}->{ $self->get_clc($c)->get_namespace };
            if ( ref $hash eq 'HASH' ) {
                $c->req->params($hash);
                $c->clc('anything')->_gen_req_params();
            }
        }
    }
}

=head2 set_list_attr

set specify additional query attributes

=cut

sub set_list_attr : Private {
    my $self   = shift;
    my $c      = shift;
    my $offset = shift;
    my $limit  = shift;
    $c->log->debug('----- set_list_attr');
    $$limit = $c->req->param('limit') || 30;
    $$offset = 0;
    my $page_num = $c->req->param('page_num') || 1;
    $$offset = $$limit * ( $page_num - 1 );

#    $self->get_clc($c)->class_stash->{offset} = $offset; もどってからセットしているんだからいらないはず しかもリファレンスやし
#    $self->get_clc($c)->class_stash->{limit} = $limit;
}

=head2 list_sort

set fields that will be used to order the results of your query

=cut

sub list_sort : Private {
    my $self = shift;
    my $c    = shift;
    $c->log->debug('----- list_sort');
    my $order_by;
    my $prefix = $self->get_clc($c)->get_form_prefix;
    my $item   = $c->req->param("${prefix}order_item");
    my $order  = $c->req->param("${prefix}order");
    $order_by = $item . ' ' . $order if ($item);
    $order_by ||= 'id';

    $self->get_clc($c)->class_stash->{sortorder} = $order_by;
    return $order_by;
}

=head2 list_where

make specify where clause

=cut

sub list_where : Private {
    my $self = shift;
    my $c    = shift;
    $c->log->debug('----- list_where ');

    # 検索結果をかえす
    my %hash;

    # データ取得
    my $data = $self->get_clc($c)->req_params();
    my (@field) = ('default');
    push( @field, 'visible' )
        if ( defined( $c->req->param("search_type") ) && $c->req->param("search_type") eq 'detail' );
    foreach my $type (@field) {

        # 検索項目だけに限定する
        foreach my $p ( @{ $self->get_clc($c)->schema } ) {
            next if ( $p->{'temporary'} );           # DBにない値ではwhere句を作らない。
            next if ( $p->{'findrow'} ne $type );    # 検索フィールドにないならなにもしない
                                                     # 拡張項目用に作成したトリガー
            $self->call_trigger( 'list_where_make_phrase', $c, $p, \%hash );
            next if defined $p->{'searched'} && $p->{'searched'};

            # next unless(defined($data->{$p->{name}}));# 値がなければなにもしない
            # 数値データのバリデータ / 間違っていたのでなおしたよ nakamura
            #if(grep{$p->{sql}->{type} eq $_} qw!int integer serial!){
            # 大量のワーニングが出るので直しました shimizu
            if (defined $p->{sql}->{type}
                && (   $p->{sql}->{type} eq 'int'
                    || $p->{sql}->{type} eq 'integer'
                    || $p->{sql}->{type} eq 'serial' )
                )
            {
                if ( ref $data->{ $p->{name} } eq 'ARRAY' ) {
                    my @tmp;
                    foreach ( @{ $data->{ $p->{name} } } ) {
                        push( @tmp, int($_) ) if ( length($_) );
                    }
                    $data->{ $p->{name} } = \@tmp;
                }
                else {
                    $data->{ $p->{name} } = int( $data->{ $p->{name} } ) if ( length( $data->{ $p->{name} } ) );
                }
            }
            if ( $p->{form}->{type} =~ /text/ ) {

                # textfield textarea
                if ( exists $p->{name} && exists $data->{ $p->{name} } && length( $data->{ $p->{name} } ) ) {
                    if ( ref $data->{ $p->{name} } eq 'ARRAY' ) {
                        $hash{ $p->{name} } = $data->{ $p->{name} };
                    }
                    else {
                        my $value = $data->{ $p->{name} };
                        if ( $value =~ /or/ ) {
                            $value =~ s/　//g;     # 全角を半角に
                            $value =~ s/\s+//g;    # 半角のたばをe1つに
                            my (@bit) = split( 'or', $value );
                            my @tmp;
                            foreach my $i (@bit) {
                                if ( length($i) ) {
                                    push( @tmp, { 'like', sprintf( '%%%s%%', $i ) } );
                                }
                            }
                            $hash{ $p->{name} } = [@tmp];
                        }
                        else {
                            $value =~ s/　/ /g;     # 全角を半角に
                            $value =~ s/\s+/ /g;    # 半角のたばを1つに
                            my (@bit) = split( ' ', $value );
                            my @tmp;
                            foreach my $i (@bit) {
                                if ( length($i) ) {
                                    push( @tmp, { 'like', sprintf( '%%%s%%', $i ) } );
                                }
                            }
                            $hash{ $p->{name} } = [ -and => @tmp ];
                        }
                    }
                }
            }
            elsif ( $p->{form}->{type} =~ /date/ ) {

                # 日付(カレンダー)の検索
                my ( @start_day, @end_day );
                my ( $start_day, $end_day );
                my $start_name = sprintf( '%s_start', $p->{name} );
                my $end_name   = sprintf( '%s_end',   $p->{name} );

                # 開始 -----------------------------------------------------------------------------------
                if ( $self->get_clc($c)->req_param($start_name) ) {
                    if ( $self->get_clc($c)->req_param($start_name) =~ /(\d+)-(\d+)-(\d+)/ ) {
                        @start_day = ( $1, $2, $3 );
                        my @start_result_day = Add_Delta_Days( @start_day, -1 );

                        # 日付が存在する場合 ---------------------------
                        if ( check_date(@start_result_day) ) {
                            $hash{ $p->{name} }->{'>'} = sprintf( '%4d-%02d-%02d',
                                $start_result_day[0], $start_result_day[1], $start_result_day[2] );

                            # 検索条件のデフォルトをセット
                            $self->get_clc($c)->schema( $p->{name} )->{form}->{default_start}
                                = $self->get_clc($c)->req_param($start_name);
                        }
                    }
                }

                # 終り -----------------------------------------------------------------------------------
                if ( $self->get_clc($c)->req_param($end_name) ) {
                    if ( $self->get_clc($c)->req_param($end_name) =~ /(\d+)-(\d+)-(\d+)/ ) {
                        @end_day = ( $1, $2, $3 );
                        my @end_result_day = Add_Delta_Days( @end_day, +1 );
                        if ( check_date(@end_result_day) ) {
                            $hash{ $p->{name} }->{'<'}
                                = sprintf( '%4d-%02d-%02d', $end_result_day[0], $end_result_day[1],
                                $end_result_day[2] );
                            $self->get_clc($c)->schema( $p->{name} )->{form}->{default_end}
                                = $self->get_clc($c)->req_param($end_name);
                        }
                    }
                }

                # -----------------------------------------------------------------------------------------
            }
            else {

                # radio select scrolling date
                $hash{ $p->{name} } = $data->{ $p->{name} }
                    if ( exists $p->{name} && exists $data->{ $p->{name} } && length( $data->{ $p->{name} } ) );
            }
        }
    }

    # 無効化フラグを初期値で設定
    $hash{disable} = [0];
    $self->get_clc($c)->class_stash->{where} = \%hash;
    return \%hash;
}

=head2 get_iterators

search iterators, then create list

=cut

sub get_iterators : Private {
    my $self = shift;
    my $c    = shift;

    $c->log->debug('----- get_iterators');
    my $model = $self->get_clc($c)->class_stash->{model};

    die 'do not defined where clause.' unless ( $self->get_clc($c)->class_stash->{where} );
    my $opt = {
        where => $self->get_clc($c)->class_stash->{where},
        attr  => {
            order_by      => $self->get_clc($c)->class_stash->{sortorder},
            limit_dialect => $model,
            limit         => $self->get_clc($c)->class_stash->{limit},
            offset        => $self->get_clc($c)->class_stash->{offset}
        }
    };
    return undef unless defined($model);
    return undef unless $model->can('search_where');

    $c->log->debug( '===== model : ' . Dumper $model);
    $c->log->debug( '===== where : ' . Dumper $opt->{where} );
    $c->log->debug( '===== attr : ' . Dumper $opt->{attr} );

    my $data = $model->search_where( $opt->{where}, $opt->{attr} );

    return $data;
}

=head2 make_meta_row

=cut

sub make_meta_row : Private {
    my $self = shift;
    my $c    = shift;

    my @view;
    $self->get_view( $c, \@view, 'make_metarow' );
    $c->forward(@view);
}

=head2 make_list

make basic list

=cut

sub make_list : Private {
    my $self = shift;
    my $c    = shift;

    my $data = $self->get_iterators($c);
    $self->call_trigger( 'make_list_get_iterators_after', $c, $data );
    $self->get_clc($c)->class_stash->{'list_data'} = $data;

    my @view;
    my $target_view
        = exists( $c->stash->{'target_view'} ) && $c->stash->{'target_view'} ? $c->stash->{'target_view'} : 'make_list';
    $self->get_view( $c, \@view, $target_view );
    $c->forward(@view);
}

=head2 list_search

searching

=cut

sub list_search : Private {
    my $self = shift;
    my $c    = shift;

    my @view;
    $self->get_view( $c, \@view, 'list_search' );
    $c->forward(@view);
}

=head2 list_navigate

navigation

=cut

sub list_navigate : Private {
    my $self = shift;
    my $c    = shift;

    my $opt = {
        order_by      => $self->get_clc($c)->class_stash->{sortorder},
        limit_dialect => $self->get_clc($c)->class_stash->{model},
        limit         => $self->get_clc($c)->class_stash->{limit},
        offset        => $self->get_clc($c)->class_stash->{offset}
    };

    # not limited
    # ナビゲーションがおかしくなるため、、これを保存
    my $tmp_limit  = $self->get_clc($c)->class_stash->{limit};
    my $tmp_offset = $self->get_clc($c)->class_stash->{offset};

    undef $self->get_clc($c)->class_stash->{limit};
    undef $self->get_clc($c)->class_stash->{offset};

    $c->log->debug('----- list_navigate');

    # maximum -----------------------------
    my $max_num = 0;

    my $data = $self->get_iterators($c);
    $max_num = $data->count if ($data);
    {

        # 検索を保存
        $self->get_clc($c)->class_stash->{limit}  = $tmp_limit;
        $self->get_clc($c)->class_stash->{offset} = $tmp_offset;
    }

    #    $c->log->debug('----- list_navigate max_num = '.$max_num);
    my $max_page = $max_num / $opt->{limit};

    #    $c->log->debug('----- list_navigate max_page = '.$max_page);
    $max_page = int($max_page) + 1 if ( $max_page =~ /\./ );

    #    $c->log->debug('----- list_navigate max_page2 = '.$max_page);
    # start num, end num ------------------
    my ( $start_num, $end_num ) = ( 0, 0 );
    my $page_num = $c->req->param('page_num') || 1;
    $start_num = $opt->{limit} * ( $page_num - 1 ) + 1 if ($max_num);
    $end_num = $opt->{limit} * ( $page_num - 1 ) + $opt->{limit};
    $end_num = $max_num if ( $end_num > $max_num );

    #持ち運び用
    $self->get_clc($c)->class_stash->{max_page}  = $max_page;
    $self->get_clc($c)->class_stash->{start_num} = $start_num;
    $self->get_clc($c)->class_stash->{end_num}   = $end_num;
    $self->get_clc($c)->class_stash->{max_num}   = $max_num;
    $c->log->debug( "==== max_page : "
            . $max_page
            . "  start_num : "
            . $start_num
            . "  end_num : "
            . $end_num
            . "  max_num : "
            . $max_num );

    my @view;
    $self->get_view( $c, \@view, 'list_navigate' );
    $c->forward(@view);
}

# list のラッパーを作っておく

=head2 csvdownload_sort

=cut

sub csvdownload_sort : Private {
    my $self = shift;
    return $self->list_sort(@_);
}

=head2 csvdownload_where

=cut

sub csvdownload_where : Private {
    my $self = shift;
    return $self->list_where(@_);
}

=head2 do_csvupload

実際に登録を行い、完了画面を表示するための内部アクション

独自のメッセージを入れたいときは以下の値をいじってください

 $c->stash->{do_csvupload_error} - エラーメッセージを入れる配列
 $c->stash->{do_csvupload_message} - 通常メッセージを入れる配列

トリガー：

=over 7

=item $self->do_csvupload_before($c);

=item $self->do_csvupload_check($c);

=item $self->do_csvupload_check_row($c, $hash);

チェック結果がNGだったら $c->stash->{do_csvupload_check_row_result} = 0 にしてください。

=item $self->do_csvupload_commit_flg($c);

=item $self->do_csvupload_flush_flg($c);

=item $self->do_csvupload_view($c, \@view);

=item $self->do_csvupload_after($c, \$commit_flg);

=back

=cut

sub do_csvupload : Private {
    my $self = shift;
    my $c    = shift;
    my $args = shift;

    # 最初に走るトリガー
    $self->call_trigger( 'do_csvupload_before', $c );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : do_csvupload' );

    # do_csvuploadからSubmitされた場合($c->req->param('action')がdo_csvupload)のみflgを立てる
    if ( $c->req->param('action') eq $self->get_clc($c)->get_namespace . '/do_csvupload' ) {
        $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'do_csvupload'} = 1;
    }

    # 次のページに飛ばすかどうかのチェックのためのトリガー
    $self->call_trigger( 'do_csvupload_check', $c, $args );

    # flgが真ならば次の画面へ行く
    if ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'do_csvupload'} ) {
        $c->log->info( 'ADVEL : ' . ref($self) . ' : do_csvupload : check is OK. go next' );
        return 0;
    }

    # この画面が誰かを設定する
    $c->stash->{'FORM'} = {} unless ( $c->stash->{'FORM'} );
    $c->stash->{'FORM'}->{'action'} = $self->get_clc($c)->get_namespace . '/do_csvupload';

    # 飛んできたqueryをget
    my $hash = $self->get_clc($c)->req_params();

    $c->log->info( 'ADVEL : ' . ref($self) . ' : do_csvupload : req_params : ', Dumper($hash) );

    $c->stash->{do_csvupload_error}   = [];
    $c->stash->{do_csvupload_message} = [];

    # リクエストパラメータチェック
    if ( !exists $hash->{csvupload_csv_file} || length( $hash->{csvupload_csv_file} ) < 5 ) {
        push @{ $c->stash->{do_csvupload_error} }, "CSVファイルが指定されていません。";
    }

    # ファイルサイズチェック
    my $prefix = $self->get_clc($c)->get_form_prefix();
    my $fobj   = $c->request->upload( $prefix . 'csvupload_csv_file' );
    if ( defined $fobj && $fobj->size() > 0 && $fobj->filename() =~ /\.csv$/ ) {
        $c->log->debug( "CSV file name = " . $fobj->filename() );
        $c->log->debug( "CSV file size = " . $fobj->size() );
    }
    else {
        push @{ $c->stash->{do_csvupload_error} }, "CSVファイルが空です。";
    }

    # モデル取得
    my $model = $self->get_model($c);

    # エラーチェックと実登録
    $self->_do_csvupload( $c, $fobj, $hash, $model );

    # エラーがあったときはロールバック！！
    if ( scalar @{ $c->stash->{do_csvupload_error} } > 0 ) {
        $model->dbi_rollback();
    }

# トリガーdo_csvupload_commit_flgで$c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_commit'}に真を詰めない限りcommitする
    $self->call_trigger( 'do_csvupload_commit_flg', $c );

# トリガーdo_csvupload_flush_flgで$c->stash->{'ADVEL'}->{$self->get_clc($c)->get_namespace}->{'not_flush'}に真をを詰めない限りsession中に作ったflgエントリを削除する
    $self->call_trigger( 'do_csvupload_flush_flg', $c );
    unless ( $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace }->{'not_flush'} ) {
        delete $c->stash->{'ADVEL'}->{ $self->get_clc($c)->get_namespace };
        delete $c->session->{'ADVEL'}->{ $self->get_clc($c)->get_namespace };
    }

    # 表示するためのviewを取得
    my @view;

    #if($self->get_clc($c)->getView) {
    #    push(@view, $self->get_clc($c)->getView());
    #    push(@view, 'do_csvupload');
    #}
    $self->get_view( $c, \@view, 'do_csvupload' );

    # Viewを変更するためのトリガー
    $self->call_trigger( 'do_csvupload_view', $c, \@view );

    $c->log->info( 'ADVEL : ' . ref($self) . ' : do_csvupload : next forward is undefined !!' ) unless (@view);

    $c->forward(@view);

    $self->call_trigger( 'do_csvupload_after', $c );
    return 1;
}

# 全般的にマルチのときはループをもう１階層増やすか呼ぶ側をマルチ対応にしないと駄目
# 引数：
#   $fobj  - CSVファイルオブジェクト
#   $hash  - id => 1 のようなハッシュのリファレンス
#   $model - モデルのクラス名
sub _do_csvupload : Private {
    my $self  = shift;
    my $c     = shift;
    my $fobj  = shift;
    my $hash  = shift;
    my $model = shift;

    if ( scalar @{ $c->stash->{do_csvupload_error} } == 0 && defined $fobj && defined $model ) {
        my @table;
        my @line_error;
        my @models;

        # カラム名取得
        my $cols = 0;
        foreach my $p ( $self->get_clc($c)->schema ) {
            next if ( $p->{metarow} eq 'invisible' and $p->{sql}->{notnull} ne '1' );
            next if ( exists $p->{temporary} && $p->{temporary} == 1 );

            $table[0][ $cols++ ] = $p->{name};
        }

        my $rows = 1;
        my @lines = split( "\n", Jcode::convert( $fobj->slurp(), 'euc-jp', 'sjis' ) );
        while (@lines) {

            # 構文解析
            my $line = shift(@lines);
            $line .= shift(@lines) while ( $line =~ tr/"// % 2 and (@lines) );
            $line =~ s/(?:\x0D\x0A|[\x0D\x0A])?$/,/;
            my @values = map { /^"(.*)"$/s ? scalar( $_ = $1, s/""/"/g, $_ ) : $_ }
                ( $line =~ /("[^"]*(?:""[^"]*)*"|[^,]*),/g );
            for my $i ( 0 .. $#values ) {
                $table[$rows][$i] = $values[$i];
            }
            $rows++;
        }
        $c->stash->{do_csvupload_table} = \@table;

        # データが1行も入っていない
        if ( 2 >= $#table ) {
            push @{ $c->stash->{do_csvupload_error} }, "データが1行も入っていません。";
            $line_error[0] = "データなし";
        }

        # 0行目と1行目が異なる
        if ( $#{ $table[0] } != $#{ $table[1] } ) {
            push @{ $c->stash->{do_csvupload_error} }, sprintf( "行数%d：不正な列数(%d)です。", 1, $#{ $table[1] } );
            $line_error[1] = sprintf( "不正な列数(%d)", $#{ $table[1] } );
        }

        # 1行ごとにエラーチェック＆登録
        my $creates = 0;

        #my $updates = 0;
        for my $i ( 2 .. $#table ) {

            # 0行目と行数が異なる
            if ( $#{ $table[0] } != $#{ $table[$i] } ) {
                push @{ $c->stash->{do_csvupload_error} },
                    sprintf( "行数%d：不正な列数(%d)です。", $i, $#{ $table[$i] } );
                $line_error[$i] = sprintf( "不正な列数(%d)", $#{ $table[$i] } );
            }
            else {
                my $hash = undef;

                # hash への値詰めと外部参照値の変換
                for my $j ( 0 ... $#{ $table[$i] } ) {
                    $c->log->debug( sprintf( "%d,%d : %s = %s", $i, $j, $table[0][$j], $table[$i][$j] ) );

                    # list があったらそこから呼ぶ
                    my $value = $table[$i][$j];
                    my @list  = exists $self->get_clc($c)->schema( $table[0][$j] )->{list}
                        ? @{ $self->get_clc($c)->schema( $table[0][$j] )->{list} }
                        : ();
                    if ( scalar(@list) > 0 ) {
                        foreach my $item (@list) {
                            if ( $value eq $item->{'desc'} ) {
                                $value = $item->{'name'};
                                last;
                            }
                        }
                    }
                    $table[$i][$j] = $value;
                    $hash->{ $table[0][$j] } = $value;
                }

                # 各列に特別な値を詰めるとき
                $self->call_trigger( 'input_before_check_errors', $c, $hash );

                # 各行のエラーチェック
                $c->stash->{do_csvupload_check_row_result} = 1;
                $self->call_trigger( 'do_csvupload_check_row', $c, $hash );

                # レコードチェック
                if ( $c->stash->{do_csvupload_check_row_result} != 1 ) {
                    push @{ $c->stash->{do_csvupload_error} }, sprintf( "行数%d：不正なレコードです。", $i );
                    $line_error[$i] = "不正レコード";
                }

                # 実登録
                if ( $c->stash->{do_csvupload_check_row_result} = 1 && $rows > 1 ) {

                    # これらは値が入っていないとエラーになる
                    $c->stash->{'error_check_data'} = undef;
                    foreach my $column (qw(disable date_regist date_update)) {
                        $hash->{$column} = '----'
                            unless exists $hash->{$column};
                    }
                    $hash->{id} = 0 if exists $hash->{id};
                    $c->stash->{'error_check_data'} = $hash;

                    # 各列のエラーチェック
                    if ( $c->check_all_errors($self) ) {
                        $c->stash->{do_csvupload_check_row_result} = 0;
                        my $err_hash = undef;

                        # このハッシュだとすごく使いづらいので使いやすいように加工
                        foreach
                            my $line ( @{ $c->stash->{'find_errors'}->{ $self->get_clc($c)->get_namespace }->{_P_} } )
                        {
                            $err_hash->{ $line->{'name'} } = $line->{'message'};
                        }
                        for my $j ( 0 ... $#{ $table[$i] } ) {
                            $c->log->debug( sprintf( "%d,%d : %s", $i, $j, $table[$i][$j] ) );
                            if ( exists $err_hash->{ $table[0][$j] } ) {
                                $table[$i][$j] = $table[$i][$j]
                                    . sprintf( qq!<br><span class="errorMsg">%s</span>!, $err_hash->{ $table[0][$j] } );
                            }
                        }
                        $c->stash->{'find_errors'} = undef;
                    }

                    # エラーがないから登録
                    else {

                        # これらは値が入っているとエラーになる
                        foreach my $column (qw(disable date_regist date_update)) {
                            if ( $hash->{$column} eq '----' ) {
                                delete $hash->{$column};
                                $c->log->debug( sprintf( "deleted column : %s", $column ) );
                            }
                        }
                        delete $hash->{id} if exists $hash->{id};

                        # int,date,timestamp型でNOT NULLじゃない値が空文字で入ってきたら
                        # hashから抜く（抜かないとDB登録時にエラーになる）
                        foreach my $column ( keys %{$hash} ) {
                            my $schema   = $self->get_clc($c)->schema($column);
                            my $sql_type = exists $schema->{'sql'}->{'type'} ? $schema->{'sql'}->{'type'} : '';
                            my $not_null = exists $schema->{'sql'}->{'notnull'} ? $schema->{'sql'}->{'notnull'} : '0';
                            if ((   $sql_type eq 'int' || $sql_type eq 'date' || $sql_type eq 'timestamp with time zone'
                                )
                                &&

                                #!$not_null &&
                                length( $hash->{$column} ) == 0
                                )
                            {
                                delete $hash->{$column};
                                $c->log->debug( sprintf( "deleted column : %s", $column ) );
                            }
                        }

                        # 登録予約
                        push( @models, $hash );
                    }
                }
            }
        }

        # 実登録
        if ( scalar @{ $c->stash->{do_csvupload_error} } == 0 ) {
            foreach my $hash (@models) {
                $c->log->debug( "creating: ", Dumper $hash);
                my $result = $model->create( $c, $hash );
                $c->log->debug( "created: ", Dumper $result);
                $creates++;
            }
        }

        # 登録完了
        if ( $creates > 0 ) {
            push @{ $c->stash->{do_csvupload_message} }, $creates . "件追加しました。";
        }
        else {
            push @{ $c->stash->{do_csvupload_error} }, "データが1件もありません。";
        }
        $c->stash->{do_csvupload_table}      = \@table;
        $c->stash->{do_csvupload_line_error} = \@line_error;
    }
}

=head2 default

デフォルトアクション

リストにforwardします

=cut

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('list');
}

=head2 add

登録処理用アクション

標準で 入力=>完了 の２アクション

=cut

sub add : Local {
    my $self = shift;
    my $c    = shift;
    $c->log->info( 'ADVEL : ' . ref($self) . ' : add' );
    $c->stash->{'ADVEL_action_type'} = 'add';
    $c->forward('action_switcher');
}

=head2 delete

削除処理用アクション

標準で 確認=>削除 の２アクション

=cut

sub delete : Local {
    my ( $self, $c ) = @_;
    $c->log->info( 'ADVEL : ' . ref($self) . ' : delete' );
    $c->stash->{'ADVEL_action_type'} = 'delete';
    $c->forward('action_switcher');
}

=head2 disable

無効化処理用アクション

標準で 確認=>無効化 の２アクション

=cut

sub disable : Local {
    my ( $self, $c ) = @_;
    $c->log->info( 'ADVEL : ' . ref($self) . ' : disable' );
    $c->stash->{'ADVEL_action_type'} = 'disable';
    $c->forward('action_switcher');
}

=head2 view

詳細画面を表示するためのアクション

=cut

sub view : Local {
    my ( $self, $c ) = @_;
    $c->log->info( 'ADVEL : ' . ref($self) . ' : view' );
    $c->stash->{'ADVEL_action_type'} = 'view';
    $c->forward('action_switcher');
}

=head2 list

一覧表示用アクション

トリガー：

=over 3

=item $serf->list_before($c);

=item $self->list_data($c, $data);

=item $self->list_after($c);

=back

=cut

sub list : Local {
    my $self = shift;
    my $c    = shift;

    # 各コントローラの初期化メソッドを呼ぶ
    $self->initialize($c);

    $c->log->info( 'ADVEL : ' . ref($self) . ' : list' );
    $self->call_trigger( 'list_before', $c );

    $self->list_query_for_session($c);

    my $sortorder = $self->list_sort($c);
    $self->call_trigger( 'list_sort_after', $c, \$sortorder );
    $self->get_clc($c)->class_stash->{sortorder} = $sortorder;

    my $where = $self->list_where($c);
    $self->call_trigger( 'list_where_after', $c, $where );
    $self->get_clc($c)->class_stash->{where} = $where;

    my ($offset) = '';
    my ($limit)  = '';
    $self->set_list_attr( $c, \$offset, \$limit );

    $self->get_clc($c)->class_stash->{offset} = $offset;
    $self->get_clc($c)->class_stash->{limit}  = $limit;
    $self->get_clc($c)->class_stash->{model}  = $self->get_model($c);

    $self->list_search($c);

    $self->list_navigate($c);

    $self->make_meta_row($c);

    $self->make_list($c);

    my @view;
    $self->get_view( $c, \@view, 'list' );
    $self->call_trigger( 'list_view', $c, \@view );
    $c->forward(@view);
}

=head2 csvdownload

CVSダウンロードアクション

=cut

sub csvdownload : Local {
    my $self = shift;
    my $c    = shift;

    # 各コントローラの初期化メソッドを呼ぶ
    $self->initialize($c);

    $c->log->debug('--------------------------- csvdownload にきました');

    $self->call_trigger( 'csvdownload_before', $c );

    # 並び変え
    my $sortorder = $self->csvdownload_sort($c);
    $self->call_trigger( 'csvdownload_sort_after', $c );
    $self->get_clc($c)->class_stash->{sortorder} = $sortorder;

    # 検索
    my $where = $self->csvdownload_where($c);
    $self->call_trigger( 'csvdownload_wheres_after', $c, $where );
    $self->get_clc($c)->class_stash->{where} = $where;

    # ページ制御
    my ($offset) = '';
    my ($limit)  = '';

    # モデル
    $self->get_clc($c)->class_stash->{model} = $self->get_model($c);

    # データ取り出し
    my $data = $self->get_iterators($c);

    $c->stash->{'csvdownload_data'} = $data;

    my @view;
    if ( $self->get_clc($c)->getView ) {
        push( @view, $self->get_clc($c)->getView() );
        push( @view, 'csvdownload' );
    }
    $self->call_trigger( 'csvdownload_view', $c, \@view );

    $c->forward(@view);

    # ファイル出力
    $c->res()->header(
        'Content-Type'        => 'application/octet-stream',
        '-charset'            => 'Shift_JIS',
        'Content-Disposition' =>
            sprintf( 'attachment; filename="%s.csv"', $c->stash->{csvdownload_filename} || 'file' ),
    );
    $c->res()->body( $c->stash->{body} );
    $c->log->debug('--------------------------- csvdownload 終了');

    return 1;
}

=head2 csvupload

CVSアップロードアクション

=cut

sub csvupload : Local {
    my $self = shift;
    my $c    = shift;
    $c->log->info( 'ADVEL : ' . ref($self) . ' : csvupload' );
    $c->stash->{'ADVEL_action_type'} = 'csvupload';
    $c->forward('action_switcher');
}

=head1 SEE ALSO

とりあえず空っぽ
日本語と英語と 両方POD書きたいんだけど何とかならないのかなぁ

=head1 AUTHOR

Shota Takayam, E<lt>takayama@shanon.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Shota Takayama and Shanon, Inc.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.


=cut

1;
__END__


