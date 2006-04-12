package Catalyst::Helper::Controller::ADVEL;

# ADVEL.pm
# Copyright(c) 2005 Shota Takayama. All rights reserved.
# Written by Shota Takayama <takayama@shanon.co.jp>.
# First cut on 2005-11-17 17:46:36 JST.
# Time-stamp: "2005-12-12 19:49:20 takayama" last modified.

my ($Revision) = '$Id: ADVEL.pm,v 1.20 2006/02/14 04:19:12 shimizu Exp $';
($VERSION) = $Revision =~ /v ([0-9.]+)/;
use vars qw($VERSION);
use strict;
use warnings;

use Path::Class;

=head1 NAME

Catalyst::Helper::Controller::ADVEL - Helper for Add Delete View Edit List (Scaffolding)

=head1 SYNOPSIS

    # Imagine you want to generate a scaffolding controller MyApp::C::SomeTable
    # for a CDBI table class MyApp::M::CDBI::SomeTable
    script/myapp_create.pl controller SomeTable ADVEL CDBI::SomeTable

=head1 DESCRIPTION

Helper for Add Delete View Edit List (Scaffolding).

Templates area TT so you'll need a TT View Component and forward in
your end action too.

Note that you have to add these lines to your CDBI class...

    use Class::DBI::AsForm;
    use Class::DBI::FromForm;

for L<Catalyst::Model::CDBI> you can do that  by adding this

    additional_base_classes => [qw/Class::DBI::AsForm Class::DBI::FromForm/],   

to the component config. Also, change your application class like this:

    use Catalyst qw/-Debug FormValidator/;

Also, note that the scaffolding uses L<Template::Plugin::Class>, so it will
be a requirement for you application as well.

This Helper's template does'nt output <HTML> tag.
set PRE_PROCESS and POST_PROCESS for your Catalyst config.

ex)
    MyApp->config({
        name     => 'MyApp',
        root     => MyApp->path_to('root');,
    });
=head1 METHODS

=over 4

=item mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper, $table_class ) = @_;
    $helper->{table_class} = $helper->{app} . '::Model::' . $table_class;
    my $file = $helper->{file};
    my $dir  = dir( $helper->{base}, 'root', $helper->{prefix} );

    #$helper->mk_dir($dir);
    $helper->render_file( 'compclass', $file );
}

=back

=head1 AUTHOR

Shota Takayama

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use warnings;
use base 'Catalyst::Controller::ADVEL';

=head1 NAME

[% class %] - Scaffolding Controller Component

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Scaffolding Controller Component.

=head1 METHODS

=cut

############################################################
# アクションスイッチャ用コールバック
# $actions にARRAY REFでアクションが入ります
# 標準のアクションを入れ替えたいときに使用してください
############################################################
# __PACKAGE__->add_trigger(set_actions => \&set_actions);
# sub set_actions {
#     my $self = shift;
#     my $c = shift;
#     my $actions = shift;
# }

############################################################
# 入力用コールバック群
############################################################

# 一番最初に呼ばれるトリガー
# inputに入った直後に処理を挟みたい場合に。
# __PACKAGE__->add_trigger(input_before => \&input_before);
# sub input_before {
#     my $self = shift;
#     my $c = shift;
# }

# フォームにデータを詰めるときに呼ばれるトリガー
# __PACKAGE__->add_trigger(input_after_gen_first_data => \&input_after_gen_first_data);
# sub input_after_gen_first_data {
#     my $self = shift;
#     my $c = shift;
# }

# エラーチェックの直前に呼ばれるトリガー
# check_all_errorsでは$hashの中身をチェックします
# __PACKAGE__->add_trigger(input_before_check_errors => \&input_before_check_errors);
# sub input_before_check_errors {
#     my $self = shift;
#     my $c = shift;
#     my $hash = shift;
# }

# 追加のエラーチェックで呼ばれるトリガー
# エラーがあったら$errorに詰めてやります
# __PACKAGE__->add_trigger(check_all_errors_after => \&check_all_errors_after);
# sub check_all_errors_after {
#     my $self = shift;
#     my $c = shift;
#     my $errors = shift;
#     my $schema = $self->get_clc($c)->schema();
#     my $amount = $self->get_clc($c)->req_param("amount");
#     if ($amount < 0) {
#         push(@{$errors}, {
#              name => 'amount',
#              message => '必ず正の値にしてください',
#          }
#         );
#    }
# }

# 次のアクションに移っていいかどうかを判定した後に呼ばれるトリガー
# 標準ではエラーチェックを通ったら次に行くので、
# その挙動を変えたい場合に
# __PACKAGE__->add_trigger(input_check => \&input_check);
# sub input_check {
#     my $self = shift;
#     my $c = shift;
#     # ここを偽にすると次の画面へ行かない
#     $c->session->{'ADVEL'}->{$c->namespace()}->{'input'} = 0;
# }

# modelからretrieveした後に呼ばれるトリガー
# retrieveした中身を替えたい場合は
# $c->stash->{'model'}と$c->stash->{'form_data'}を書き換えてください
# __PACKAGE__->add_trigger(input_after_retrieve => \&input_after_retrieve);
# sub input_after_retrieve {
#     my $self = shift;
#     my $c = shift;
# }

# reqから中身値を取得した後に呼ばれるトリガー
# $c->stash->{'form_data'}を書き換えてください
# __PACKAGE__->add_trigger(input_after_get_from_req => \&input_after_get_from_req);
# sub input_after_get_from_req {
#     my $self = shift;
#     my $c = shift;
# }

# retrieveもrequestも存在しなかったときに、
# 初期値を詰めた後に呼ばれるトリガー
# __PACKAGE__->add_trigger('input_after_gen_first_data' => \&input_after_gen_first_data);
# sub input_after_gen_first_data {
#     my $self = shift;
#     my $c = $c;
# }

# Viewを取得した後に呼ばれるトリガー
# Viewを変更したい場合や、
# 内部的に二つのinputを通したりこっそり別のactionにforwardしたい場合に
# __PACKAGE__->add_trigger(input_view => \&input_view);
# sub input_view {
#     my $self = shift;
#     my $c = shift;
#     my $next_view = shift;
#     # $next_viewはARRAYREF
#     # $next_view->[0]にforward先のクラス名
#     # $next_view->[1]にforward先のメソッド名を
#     # $next_view->[1]を省略した場合はprocessにforwardされます
#     $next_view->[0] = 'MyApp::View::MyView';
#     $next_view->[1] = 'input';
# }

# 最後に呼ばれるトリガー
# 最後に処理を挟みたい場合に
# __PACKAGE__->add_trigger(input_after => \&input_after);
# sub input_after {
#     my $self = shift;
#     my $c = shift;
# }


##################################################
# 確認用コールバック群
##################################################

# 一番最初に呼ばれるトリガー
# confirmに入った直後に処理を挟みたい場合に。
# __PACKAGE__->add_trigger(confirm_before => \&confirm_before);
# sub confirm_before {
#     my $self = shift;
#     my $c = shift;
# }

# エラーチェックの直前に呼ばれるトリガー
# check_all_errorsでは$hashの中身をチェックします
# __PACKAGE__->add_trigger(confirm_before_check_errors => \&confirm_before_check_errors);
# sub confirm_before_check_errors {
#     my $self = shift;
#     my $c = shift;
#     my $hash = shift;
# }

# 次のアクションに移っていいかどうかを判定した後に呼ばれるトリガー
# 標準ではエラーチェックを通ったら次に行くので、
# その挙動を変えたい場合に
# __PACKAGE__->add_trigger(confirm_check => \&confirm_check);
# sub confirm_check {
#     my $self = shift;
#     my $c = shift;
#     # ここを偽にすると次の画面へ行かない
#     $c->session()->{'ADVEL'}->{'confirm'} = 0;
# }

# Viewを取得した後に呼ばれるトリガー
# Viewを変更したい場合や、
# 内部的に二つのconfirmを通したりこっそり別のactionにforwardしたい場合に
# __PACKAGE__->add_trigger(confirm_view => \&confirm_view);
# sub confirm_view {
#     my $self = shift;
#     my $c = shift;
#     my $next_view = shift;
#     # $next_viewはARRAYREF
#     # $next_view->[0]にforward先のクラス名
#     # $next_view->[1]にforward先のメソッド名を
#     # $next_view->[1]を省略した場合はprocessにforwardされます
#     $next_view->[0] = 'MyApp::View::MyView';
#     $next_view->[1] = 'confirm';
# }

# 最後に呼ばれるトリガー
# 最後に処理を挟みたい場合に
# __PACKAGE__->add_trigger(confirm_after => \&confirm_after);
# sub confirm_after {
#     my $self = shift;
#     my $c = shift;
# }


##################################################
# 登録用コールバック群
##################################################

# 一番最初に呼ばれるトリガー
# do_addに入った直後に処理を挟みたい場合に。
# __PACKAGE__->add_trigger(do_add_before => \&do_add_before);
# sub do_add_before {
#     my $self = shift;
#     my $c = shift;
# }

# 次のアクションに移っていいかどうかを判定した後に呼ばれるトリガー
# 標準ではエラーチェックを通ったら次に行くので、
# その挙動を変えたい場合に
# __PACKAGE__->add_trigger(do_add_check => \&do_add_check);
# sub do_add_check {
#     my $self = shift;
#     my $c = shift;
#     # ここを偽にすると次の画面へ行かない
#     $c->session()->{'ADVEL'}->{'do_add'} = 0;
# }

# create or updateした後に呼ばれるトリガー
# commitを走らせたくない場合に
# __PACKAGE__->add_trigger(do_add_commit_flg => \&do_add_commit_flg);
# sub do_add_commit_flg {
#     my $self = shift;
#     my $c = shift;
#     # ここを真にするとcommitされない
#     $c->stash->{'ADVEL'}->{$c->namespace}->{'not_commit'} = 1;
# }

# session内のflgをflushするかどうかを変えるためのトリガー
# flushさせたくない場合に
# __PACKAGE__->add_trigger(do_add_flush_flg => \&do_add_flush_flg);
# sub do_add_flush_flg {
#     my $self = shift;
#     my $c = shift;
#     # ここを真にするとflushされない
#     $c->stash->{'ADVEL'}->{$c->namespace}->{'not_flush'} = 1;
# }

# Viewを取得した後に呼ばれるトリガー
# Viewを変更したい場合や、
# 内部的に二つのdo_addを通したりこっそり別のactionにforwardしたい場合に
# __PACKAGE__->add_trigger(do_add_view => \&do_add_view);
# sub do_add_view {
#     my $self = shift;
#     my $c = shift;
#     my $next_view = shift;
#     # $next_viewはARRAYREF
#     # $next_view->[0]にforward先のクラス名
#     # $next_view->[1]にforward先のメソッド名を
#     # $next_view->[1]を省略した場合はprocessにforwardされます
#     $next_view->[0] = 'MyApp::View::MyView';
#     $next_view->[1] = 'do_add';
# }

# 最後に呼ばれるトリガー
# 最後に処理を挟みたい場合に
# __PACKAGE__->add_trigger(do_add_after => \&do_add_after);
# sub do_add_after {
#     my $self = shift;
#     my $c = shift;
# }


##################################################
# 無効化確認用コールバック群
##################################################

# 一番最初に呼ばれるトリガー
# pre_disableに入った直後に処理を挟みたい場合に。
# __PACKAGE__->add_trigger(pre_disable_before => \&pre_disable_before);
# sub pre_disable_before {
#     my $self = shift;
#     my $c = shift;
# }

# 次のアクションに移っていいかどうかを判定した後に呼ばれるトリガー
# 標準ではエラーチェックを通ったら次に行くので、
# その挙動を変えたい場合に
# __PACKAGE__->add_trigger(pre_disable_check => \&pre_disable_check);
# sub pre_disable_check {
#     my $self = shift;
#     my $c = shift;
#     # ここを偽にすると次の画面へ行かない
#     $c->session()->{'ADVEL'}->{'pre_disable'} = 0;
# }

# Viewを取得した後に呼ばれるトリガー
# Viewを変更したい場合や、
# 内部的に二つのpre_disableを通したりこっそり別のactionにforwardしたい場合に
# __PACKAGE__->add_trigger(pre_disable_view => \&pre_disable_view);
# sub pre_disable_view  {
#     my $self = shift;
#     my $c = shift;
#     my $next_view = shift;
#     # $next_viewはARRAYREF
#     # $next_view->[0]にforward先のクラス名
#     # $next_view->[1]にforward先のメソッド名を
#     # $next_view->[1]を省略した場合はprocessにforwardされます
#     $next_view->[0] = 'MyApp::View::MyView';
#     $next_view->[1] = 'pre_disable';
# }

# 最後に呼ばれるトリガー
# 最後に処理を挟みたい場合に
# __PACKAGE__->add_trigger(pre_disable_after => \&pre_disable_after);
# sub pre_disable_after {
#     my $self = shift;
#     my $c = shift;
# }


##################################################
# 無効化実行用コールバック群
##################################################

# 一番最初に呼ばれるトリガー
# do_addに入った直後に処理を挟みたい場合に。
# __PACKAGE__->add_trigger(do_disable_before => \&do_disable_before);
# sub do_disable_before  {
#     my $self = shift;
#     my $c = shift;
# }

# 次のアクションに移っていいかどうかを判定した後に呼ばれるトリガー
# 標準ではエラーチェックを通ったら次に行くので、
# その挙動を変えたい場合に
# __PACKAGE__->add_trigger(do_disable_check => \&do_disable_check);
# sub do_disable_check {
#     my $self = shift;
#     my $c = shift;
#     # ここを偽にすると次の画面へ行かない
#     $c->session()->{'ADVEL'}->{'do_disable'} = 0;
# }

# create or updateした後に呼ばれるトリガー
# commitを走らせたくない場合に
# __PACKAGE__->add_trigger(do_disable_commit_flg => \&do_disable_commit_flg);
# sub do_disable_commit_flg {
#     my $self = shift;
#     my $c = shift;
#     # ここを真にするとcommitされない
#     $c->stash->{'ADVEL'}->{$c->namespace}->{'not_commit'} = 1;
# }

# session内のflgをflushするかどうかを変えるためのトリガー
# flushさせたくない場合に
# __PACKAGE__->add_trigger(do_disable_flush_flg => \&do_disable_flush_flg);
# sub do_disable_flush_flg {
#     my $self = shift;
#     my $c = shift;
#     # ここを真にするとflushされない
#     $c->stash->{'ADVEL'}->{$c->namespace}->{'not_flush'} = 1;
# }

# Viewを取得した後に呼ばれるトリガー
# Viewを変更したい場合や、
# 内部的に二つのdo_disableを通したりこっそり別のactionにforwardしたい場合に
# __PACKAGE__->add_trigger(do_disable_view => \&do_disable_view);
# sub do_disable_view  {
#     my $self = shift;
#     my $c = shift;
#     my $next_view = shift;
#     # $next_viewはARRAYREF
#     # $next_view->[0]にforward先のクラス名
#     # $next_view->[1]にforward先のメソッド名を
#     # $next_view->[1]を省略した場合はprocessにforwardされます
#     $next_view->[0] = 'MyApp::View::MyView';
#     $next_view->[1] = 'do_disable';
# }

# 最後に呼ばれるトリガー
# 最後に処理を挟みたい場合に
# __PACKAGE__->add_trigger(do_disable_after => \&do_disable_after);
# sub do_disable_after  {
#     my $self = shift;
#     my $c = shift;
# }

##################################################
# 削除確認用コールバック群
##################################################

# 一番最初に呼ばれるトリガー
# pre_deleteに入った直後に処理を挟みたい場合に。
# __PACKAGE__->add_trigger(pre_delete_before => \&pre_delete_before);
# sub  pre_delete_before {
#     my $self = shift;
#     my $c = shift;
# }

# 次のアクションに移っていいかどうかを判定した後に呼ばれるトリガー
# 標準ではエラーチェックを通ったら次に行くので、
# その挙動を変えたい場合に
# __PACKAGE__->add_trigger(pre_delete_check => \&pre_delete_check);
# sub pre_delete_check {
#     my $self = shift;
#     my $c = shift;
#     # ここを偽にすると次の画面へ行かない
#     $c->session()->{'ADVEL'}->{'pre_delete'} = 0;
# }

# Viewを取得した後に呼ばれるトリガー
# Viewを変更したい場合や、
# 内部的に二つのpre_deleteを通したりこっそり別のactionにforwardしたい場合に
# __PACKAGE__->add_trigger(pre_delete_view => \&pre_delete_view);
# sub pre_delete_view  {
#     my $self = shift;
#     my $c = shift;
#     my $next_view = shift;
#     # $next_viewはARRAYREF
#     # $next_view->[0]にforward先のクラス名
#     # $next_view->[1]にforward先のメソッド名を
#     # $next_view->[1]を省略した場合はprocessにforwardされます
#     $next_view->[0] = 'MyApp::View::MyView';
#     $next_view->[1] = 'pre_delete';
# }

# 最後に呼ばれるトリガー
# 最後に処理を挟みたい場合に
# __PACKAGE__->add_trigger(pre_delete_after => \&pre_delete_after);
# sub pre_delete_after  {
#     my $self = shift;
#     my $c = shift;
# }

##################################################
# 削除登録用コールバック群
##################################################

# 一番最初に呼ばれるトリガー
# do_addに入った直後に処理を挟みたい場合に。
# __PACKAGE__->add_trigger(do_delete_before => \&do_delete_before);
# sub do_delete_before  {
#     my $self = shift;
#     my $c = shift;
# }

# 次のアクションに移っていいかどうかを判定した後に呼ばれるトリガー
# 標準ではエラーチェックを通ったら次に行くので、
# その挙動を変えたい場合に
# __PACKAGE__->add_trigger(do_delete_check => \&do_delete_check);
# sub do_delete_check {
#     my $self = shift;
#     my $c = shift;
#     # ここを偽にすると次の画面へ行かない
#     $c->session()->{'ADVEL'}->{'do_delete'} = 0;
# }

# create or updateした後に呼ばれるトリガー
# commitを走らせたくない場合に
# __PACKAGE__->add_trigger(do_delete_commit_flg => \&do_delete_commit_flg);
# sub do_delete_commit_flg {
#     my $self = shift;
#     my $c = shift;
#     # ここを真にするとcommitされない
#     $c->stash->{'ADVEL'}->{$c->namespace}->{'not_commit'} = 1;
# }

# session内のflgをflushするかどうかを変えるためのトリガー
# flushさせたくない場合に
# __PACKAGE__->add_trigger(do_delete_flush_flg => \&do_delete_flush_flg);
# sub do_disable_flush_flg {
#     my $self = shift;
#     my $c = shift;
#     # ここを真にするとflushされない
#     $c->stash->{'ADVEL'}->{$c->namespace}->{'not_flush'} = 1;
# }

# Viewを取得した後に呼ばれるトリガー
# Viewを変更したい場合や、
# 内部的に二つのdo_deleteを通したりこっそり別のactionにforwardしたい場合に
# __PACKAGE__->add_trigger(do_delete_view => \&do_delete_view);
# sub do_delete_view  {
#     my $self = shift;
#     my $c = shift;
#     my $next_view = shift;
#     # $next_viewはARRAYREF
#     # $next_view->[0]にforward先のクラス名
#     # $next_view->[1]にforward先のメソッド名を
#     # $next_view->[1]を省略した場合はprocessにforward
#     $next_view->[0] = 'MyApp::View::MyView';
#     $next_view->[1] = 'do_delete';
# }

# 最後に呼ばれるトリガー
# 最後に処理を挟みたい場合に
# __PACKAGE__->add_trigger(do_delete_after => \&do_delete_after);
# sub do_delete_after  {
#     my $self = shift;
#     my $c = shift;
# }

##################################################
# プレビューコールバック群
##################################################

# __PACKAGE__->add_trigger(preview_before => \&preview_before);
# 一番最初に呼ばれるトリガー
# previewに入った直後に処理を挟みたい場合に。
# sub preview_before($c) {
#     my $self = shift;
#     my $c = shift;
# }

# __PACKAGE__->add_trigger(preview_check => \&preview_check);
# 次のアクションに移っていいかどうかを判定した後に呼ばれるトリガー
# 標準ではエラーチェックを通ったら次に行くので、
# その挙動を変えたい場合に
# sub preview_check($c) {
#     my $self = shift;
#     my $c = shift;
# }

# __PACKAGE__->add_trigger(preview_view => \&preview_view);
# Viewを取得した後に呼ばれるトリガー
# Viewを変更したい場合や、
# 内部的に二つのpreviewを通したりこっそり別のactionにforwardしたい場合に
# sub preview_view($c) {
#     my $self = shift;
#     my $c = shift;
#     my $next_view = shift;
# }

# __PACKAGE__->add_trigger(preview_after => \&preview_after);
# 最後に呼ばれるトリガー
# 最後に処理を挟みたい場合に
# sub preview_after($c) {
#     my $self = shift;
#     my $c = shift;
# }

##################################################
# 一覧用コールバック群
##################################################
# __PACKAGE__->add_trigger(list_before => \&list_before);
# sub list_before  {
#     my $self = shift;
#     my $c = shift;
# }

# __PACKAGE__->add_trigger(list_data => \&list_data);
# sub list_data  {
#     my $self = shift;
#     my $c = shift;
#     my $data = shift;
# }

# __PACKAGE__->add_trigger(list_after => \&list_after);
# sub list_after  {
#     my $self = shift;
#     my $c = shift;
# }

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
