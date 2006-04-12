package Catalyst::Model::ShanonDBI;

# ShanonDBI.pm
# Copyright(c) 2005 Shota Takayama. All rights reserved.
# Written by Shota Takayama <takayama@shanon.co.jp>.
# First cut on 2005-11-17 17:46:36 JST.
# Time-stamp: "2006-02-17 11:59:35 takayama" last modified.

use strict;
use warnings;
use Catalyst::Plugin::ShanonUtil;

my ($Revision) = '$Id: ShanonDBI.pm,v 1.29 2006/02/21 01:37:21 takayama Exp $';
our $VERSION = '0.01';

use base 'Class::DBI';
use Class::Trigger;
use Date::Parse;
use NEXT;
use Data::Dumper;

# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Catalyst::Model::ShanonDBI - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Catalyst::Model::ShanonDBI;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Catalyst::Model::ShanonDBI, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=cut

=over 7

=item preHash

DBに入ってる値そのままをハッシュにして返す

=cut

sub pureHash {
    my ($self) = @_;
    my %hash = $self->_as_hash();
    foreach my $i ( keys %hash ) {
        if ( ref( $hash{$i} ) and grep( $_ ne ref( $hash{$i} ), qw(ARRAY SCALAR HASH) ) ) {
            my $primary = $hash{$i}->primary_column();
            $hash{$i} = $hash{$i}->$primary();
        }
    }
    return %hash;

}

sub pureHashRef {
    return { $_[0]->pureHash() };
}

=item toHash

フィルターがかかったハッシュを返す

=cut

sub toHash {
    my ($self) = @_;
    my %hash = $self->_as_hash();
    foreach my $i ( keys %hash ) {
        $hash{$i} = $self->$i() if ( $self->can($i) );
        if ( ref( $hash{$i} ) and grep( $_ ne ref( $hash{$i} ), qw(ARRAY SCALAR HASH) ) ) {
            my $primary = $hash{$i}->primary_column();
            $hash{$i} = $hash{$i}->$primary();
        }
    }
    return %hash;
}

=item toHashRef

ハッシュのレファレンスを返す

=cut

sub toHashRef {
    return { $_[0]->toHash() };
}

=item date2str

DBから返ってきたタイムスタンプを YYYY-MM-DD 形式にして返します
変換できなかったときはそのまま返します

=cut

sub date2str {
    my ( $self, $value ) = @_;
    return Catalyst::Plugin::ShanonUtil->date2str($value);
}

=item time2str

DBから返ってきたタイムスタンプを HH:MM 形式にして返します
変換できなかったときはそのまま返します

=cut

sub time2str {
    my ( $self, $value ) = @_;
    return Catalyst::Plugin::ShanonUtil->time2str($value);
}

=item create

Class::DBI のcreateのOverride
トリガー：$self->create_before($c, $hash);
          $self->create_after($c, $hash, $rt);

=cut

sub create {
    my $self = shift;
    my $c    = shift;
    my $hash = shift;

    # カラムリストに存在しないキーを排除する
    my %columns = map { $_ => 1 } $self->columns();
    delete $hash->{$_} foreach ( grep( !( $columns{$_} ), keys( %{$hash} ) ) );

    $self->call_trigger( 'create_before', $c, $hash );
    my $rt = $self->SUPER::create($hash);
    $self->call_trigger( 'create_after', $c, $hash, $rt );

    # ログに残す
    $rt->get_model_changes_create($c) if ($c);
    return $rt;
}

=item add

更新用コールバック群
トリガー：$self->update_before($c);
          $self->update_after($c, $rt);
          $self->disable_before($c); # 削除時
          $self->disable_after($c, $rt); # 削除時

=cut

sub update {
    my $self = shift;
    my $c    = shift;
    $self->call_trigger( 'update_before', $c );
    if ( $self->can('disable') && $self->disable() == 1 ) {

        # disable = 1 のときは削除用コールバックを呼ぶ
        $self->call_trigger( 'disable_before', $c );
    }

    # ログに残す
    $self->get_model_changes_update($c) if ($c);
    my $rt = $self->SUPER::update();
    if ( $self->can('disable') && $self->disable() == 1 ) {

        # disable = 1 のときは削除用コールバックを呼ぶ
        $self->call_trigger( 'disable_after', $c, $rt );
    }
    $self->call_trigger( 'update_after', $c, $rt );
    return $rt;
}

=item delete

削除用コールバック群
トリガー：$self->delete_before($c);
          $self->delete_after($c, $rt);

=cut

sub delete {
    my $self = shift;
    my $c    = shift;

    $self->call_trigger( 'delete_before', $c );

    # ログに残す
    $self->get_model_changes_delete($c) if ($c);
    my $rt = $self->SUPER::delete();
    return $rt;
}

=item get_model_changes_update

modelに対してupdateが発行された再に呼び出されます。
modelの変更を検出し、stashに詰めておく関数
$c->stash->{'ADVEL_model_changes'}をリストとして標準で使います。

=cut

sub get_model_changes_update {
    my $self  = shift;
    my $c     = shift;
    my $class = ref($self);
    $c->log->debug("* change data : $class") if ( $c->debug );
    my %changelog = ( $class => {} );

    # 変更のあったカラムのリストを取得
    my @change_columns = $self->is_changed;
    $c->log->debug( '@change_columns : ' . "\n" . Dumper( \@change_columns ) );

    # 現在の値をゲット
    my $after = $self->pureHashRef();

    # 変更前に戻す
    $self->discard_changes;

    # 変更前の値をゲット
    my $before = $self->pureHashRef();

    # 変更があったカラムでループをまわす
    foreach my $column (@change_columns) {

        # 今は変更が消えてしまっているので、再び変更をする
        $self->$column( $after->{$column} );

        # もし中身が寸分変わりなければログには残さない
        next if ( $before->{$column} eq $after->{$column} );

        # 変更ログデータを生成
        $changelog{$class}->{$column} = { before => $before->{$column}, after => $after->{$column} };
        $c->log->debug("* change column : $column : $before->{$column} => $after->{$column}")
            if ( $c->debug );
    }

    # stashの保存領域が空なら初期化する
    $c->stash->{'ADVEL_model_changes'} = [] unless ( $c->stash->{'ADVEL_model_changes'} );

    # stashに詰め込む
    push( @{ $c->stash->{'ADVEL_model_changes'} }, \%changelog );

    return 0;
}

=item get_model_changes_create

modelに対して新しいレコードが作製された場合に呼び出されます。
$c->stash->{'ADVEL_model_changes'}に新規登録として詰め込みます。

=cut

sub get_model_changes_create {
    my $self  = shift;
    my $c     = shift;
    my $class = ref($self);
    $c->log->debug("* create data : $class");
    my %changelog = ( $class => {} );
    my $after = $self->pureHashRef();
    foreach my $column ( $self->columns ) {
        $changelog{$class}->{$column} = { before => undef, after => $after->{$column} };
        $c->log->debug("* create column : $column : $after->{$column}")
            if ( $c->debug );
    }
    $c->stash->{'ADVEL_model_changes'} = [] unless ( $c->stash->{'ADVEL_model_changes'} );
    push( @{ $c->stash->{'ADVEL_model_changes'} }, \%changelog );

    return 0;
}

=item get_model_changes_delete

modelを削除した場合に呼び出されます。
$c->stash->{'ADVEL_model_changes'}に削除登録として詰め込みます。

=cut

sub get_model_changes_delete {
    my $self      = shift;
    my $c         = shift;
    my $class     = ref($self);
    my %changelog = ( $class => {} );
    $c->log->debug("* delete data : $class");
    my $before = $self->pureHashRef();
    foreach my $column ( $self->columns ) {
        $changelog{$class}->{$column} = { before => $before->{$column}, after => undef };
        $c->log->debug("* delete column : $column : $before->{$column}")
            if ( $c->debug );
    }
    $c->stash->{'ADVEL_model_changes'} = [] unless ( $c->stash->{'ADVEL_model_changes'} );
    push( @{ $c->stash->{'ADVEL_model_changes'} }, \%changelog );

    return 0;
}

=head1 SEE ALSO

L<Catalyst>

=head1 AUTHOR

Shota Takayama, E<lt>takayama@shanon.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Shanon, Inc.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.


=cut

