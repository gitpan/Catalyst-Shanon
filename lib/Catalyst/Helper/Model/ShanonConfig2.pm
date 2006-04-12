package Catalyst::Helper::Model::ShanonConfig2;

use strict;
use Jcode;
use XML::Simple;
use Data::Dumper;
use DirHandle;
use FileHandle;

=head1 NAME

Catalyst::Helper::Model::ShanonConfig2 - Helper for Translating Cray Core File To Shanon Framework Configs

=head1 SYNOPSIS

    script/create.pl model ShanonConfig2 ShanonConfig2 [Cray Core File] [some modules]

=head1 DESCRIPTION

Helper for ShanonConfig2 Config.

=head2 METHODS

=over 4

=item mk_compclass

Reads the database and makes a main model class as well as placeholders
for each table.

=back 

=cut

# リレーション一覧
my @relations;

# テーブル一覧
my @tables;

####################################################################################################
# Cray Core のコメントを EUC-JP に変換する
####################################################################################################
sub encode {
    my ( $this, $str ) = @_;
    if ( !defined $str || length($str) == 0 ) {
        return "";
    }
    my @array = split( //, $str );
    my @list;
    for ( my $i = 0; $i < scalar(@array); $i++ ) {

        # \\n は「。」に変えちゃう
        if ( $array[$i] eq '\\' && $array[ $i + 1 ] eq 'n' ) {
            push @list, 129;
            push @list, 66;
            $i++;

            # \\\\ は「0x5C」にする
        }
        elsif ( $array[$i] eq '\\' && $array[ $i + 1 ] eq '\\' ) {
            push @list, 92;
            $i++;

            # \\144 など
        }
        elsif ( $array[$i] eq '\\' ) {
            push @list, $array[ $i + 1 ] . $array[ $i + 2 ] . $array[ $i + 3 ];
            $i += 3;

            # [ など
        }
        elsif ( 13 < ord( $array[$i] ) && ord( $array[$i] ) < 128 ) {
            push @list, ord( $array[$i] );
        }
    }

    # SJIS から EUC に変換して返す
    my $result = pack( "C*", @list );
    return jcode( $result, 'sjis' )->euc;
}

####################################################################################################
# hoge_fuga_master を HogeFugaMaster に変換する
####################################################################################################
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

####################################################################################################
# 指定されたIDのリレーションを返す
####################################################################################################
sub get_relation {
    my ( $this, $relation_id ) = @_;
    foreach my $relation (@relations) {
        if ( $relation_id eq $relation->{'ID'} ) {
            return $relation;
        }
    }
}

####################################################################################################
# 指定されたIDのテーブルを返す
####################################################################################################
sub get_table {
    my ( $this, $table_id ) = @_;
    foreach my $table (@tables) {
        if ( $table_id eq $table->{'ID'} ) {
            return $table;
        }
    }
}

####################################################################################################
# 指定された名前のスキーマ番号を返す
####################################################################################################
sub get_schema_index {
    my ( $this, $array, $name ) = @_;
    for ( my $i = 0; $i < scalar( @{$array} ); $i++ ) {
        if ( $name eq $array->[$i]->{'name'} ) {
            return $i;
        }
    }
    return -1;
}

sub mk_compclass {
    my ( $this, $helper, $file, @limited_file ) = @_;
    print "==========================================================\n";

    # ファイル名は必須
    unless ($file) {
        die "usage: xxx_create.pl config ShanonConfig2 ShanonConfig2 [Cray Core File] [some modules]\n";
        return 1;
    }

    # XMLファイル解析
    my $parser = new XML::Simple();
    my $tree   = $parser->XMLin($file);

    # コンフィグとSQL用のディレクトリを作る
    my $config_dir = sprintf( "%s/root/config", $helper->{'base'} );
    my $schema_dir = sprintf( "%s/sql/schema",  $helper->{'base'} );
    $helper->mk_dir($config_dir);
    $helper->mk_dir($schema_dir);

    # リレーションとテーブル一覧を取得する
    @relations = undef;    #@{$tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'}};
    @tables    = undef;    #@{$tree->{'METADATA'}->{'TABLES'}->{'TABLE'}};
    my $table_list = $tree->{'database-model'}->{'schema-list'}->{'schema'}->{'table-list'}->{'table'};

    # 指定したモジュールのみ
    my %limit;
    $limit{$_} = 1 foreach (@limited_file);

    foreach my $table_name ( keys %{$table_list} ) {
        my $table      = $table_list->{$table_name};
        my $class_name = $this->get_class_name($table_name);

        # 指定したモジュールのみ
        if ( scalar @limited_file ) {
            next unless ( $limit{$class_name} );
        }

        # 設定ファイル
        my $classVar;

        # 各テーブルの列一覧取得
        #my @columns = @{$table->{'COLUMNS'}->{'COLUMN'}};
        my $columns = $table->{'column-list'}->{'column'};

        # 各テーブルのインデックス覧取得
        my %indices;

        #if (ref($table->{'INDICES'}->{'INDEX'}) eq 'HASH') {
        #    # 要素一個のときはハッシュになってしまうのでその対策
        #    my $key = $table->{'INDICES'}->{'INDEX'}->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
        #    my $val = $table->{'INDICES'}->{'INDEX'}->{'FKRefDef_Obj_id'};
        #    # 主キーは無視する
        #    unless ($val eq '-1') {
        #        $indices{$key} = $val;
        #    }
        #} elsif (ref($table->{'INDICES'}->{'INDEX'}) eq 'ARRAY') {
        #    foreach my $index (@{$table->{'INDICES'}->{'INDEX'}}) {
        #        my $key = $index->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
        #        my $val = $index->{'FKRefDef_Obj_id'};
        #        # 主キーは無視する
        #        unless ($val eq '-1') {
        #            $indices{$key} = $val;
        #        }
        #    }
        #}

        my @serials;    # シーケンス一覧
        my @configs;    # 各コンフィグ
        my @schemas;    # 各SQL
        foreach my $column_name ( keys %{$columns} ) {
            my $column = $columns->{$column_name};
            my $sql;
            my $config;
            my @schema;

            # カラム名
            push @schema, "        " . $column_name;

            # 型
            if ( $column->{'auto-increment'} eq "true" ) {

                # AutoInc="1" だったら「テーブル名_カラム名_seq」という
                # テーブルを Postgresql が自動作成するのでその対応
                $sql->{'type'} = "serial";
                push @schema, "SERIAL";
                push @serials, sprintf( "GRANT ALL ON %s_%s_seq TO PUBLIC;\n", $table_name, $column_name );
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'INT4' ) {
                $sql->{'type'} = "int";
                push @schema, "INTEGER";
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'DATE' ) {
                $sql->{'type'} = "date";
                push @schema, "DATE";
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'TIMESTAMP' ) {
                $sql->{'type'} = "timestamp with time zone";
                push @schema, "TIMESTAMP with time zone";
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'VARCAHR' ) {
                $sql->{'type'} = "varchar(255)";
                push @schema, "VARCHAR(255)";
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'BOOL' ) {
                $sql->{'type'} = "bool";
                push @schema, "BOOL";
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'TEXT' ) {
                $sql->{'type'} = "text";
                push @schema, "TEXT";
            }
            else {
                $sql->{'type'} = "text";
                push @schema, "TEXT";
            }

            # 主キーかどうか
            if ( $table->{'primary-key'}->{'primary-key-column'}->{'name'} eq lc($column_name) ) {
                $sql->{'primarykey'} = 1;
                push @schema, "PRIMARY KEY";
            }
            elsif ( 'id' eq lc($column_name) ) {

                # id は自動的に主キーにする
                $sql->{'primarykey'} = 1;
                push @schema, "PRIMARY KEY";
            }

            # デフォルト値
            if ( length( $column->{'default-value'} ) > 0 ) {
                $sql->{'default'} = $column->{'default-value'};
                push @schema, sprintf( "DEFAULT '%s'", $column->{'default-value'} );
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'DATE' ) {

                # 日付は自動的に設定する
                $sql->{'default'} = "('now'::text)::timestamp";
                push @schema, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'TIMESTAMP' ) {

                # 日時は自動的に設定する
                $sql->{'default'} = "('now'::text)::timestamp";
                push @schema, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( 'disable' eq lc($column_name) ) {

                # disable は自動的に 0 にする
                $sql->{'default'} = "0";
                push @schema, "DEFAULT '0'";
            }

            # NOT NULL 制約
            if ( $column->{'mandatory'} eq 'true' ) {
                $sql->{'notnull'} = 1;
                push @schema, "NOT NULL";
            }
            elsif ( 'disable' eq lc($column_name) ) {

                # disable は自動的に NOT NULL にする
                $sql->{'notnull'} = 1;
                push @schema, "NOT NULL";
            }

            # 参照制約
            #if ($indices{$column->{'ID'}}) {
            #    my $relation = $this->get_relation($indices{$column->{'ID'}});
            #    my $src_table = $this->get_table($relation->{'SrcTable'});
            #    my $class_name = sprintf("%s::Model::ShanonDBI::%s",
            #            $helper->{'app'},
            #            $this->get_class_name($src_table->{'Tablename'})
            #          );
            #    $sql->{'references'} = {
            #        class => $class_name, name => 'id', onupdate => 'cascade', ondelete => 'cascade'
            #    };
            #    push @schema, sprintf("CONSTRAINT ref_%s REFERENCES %s (id) ON DELETE cascade ON UPDATE cascade",
            #        $column_name,  $src_table->{'Tablename'}
            #    );
            #}

            # コメント
            if ( 'id' eq lc($column_name) ) {

                # id は自動的に ID にする
                push @schema, '/* ID */';
            }
            elsif ( 'disable' eq lc($column_name) ) {

                # disable は自動的に 削除 にする
                push @schema, '/* 削除 */';
            }
            else {
                push @schema, sprintf( "/* %s */", $this->encode( $column->{'remarks'} ) );
            }

            $config->{'sql'}  = $sql;
            $config->{'name'} = $column_name;

            # 列名によって微妙にカラムの説明を変える
            if ( $column_name eq 'id' ) {
                $config->{'desc'}    = 'ID';
                $config->{'findrow'} = 'default';
                $config->{'metarow'} = 'default';
            }
            elsif ( $column_name eq 'disable' ) {
                $config->{'desc'}    = '削除フラグ';
                $config->{'findrow'} = 'invisible';
                $config->{'metarow'} = 'invisible';
            }
            elsif ( $column_name eq 'date_regist' ) {
                $config->{'desc'}    = '登録日時';
                $config->{'findrow'} = 'visible';
                $config->{'metarow'} = 'visible';
            }
            elsif ( $column_name eq 'date_update' ) {
                $config->{'desc'}    = '更新日時';
                $config->{'findrow'} = 'visible';
                $config->{'metarow'} = 'visible';
            }
            else {
                $config->{'desc'} = $this->encode( $column->{'remarks'} );

                # カラムの説明がないときはカラム名を大文字に変換
                if ( length( $config->{'desc'} ) == 0 ) {
                    $config->{'desc'} = uc $column_name;
                }
                $config->{'findrow'} = 'default';
                $config->{'metarow'} = 'default';
            }

            # 列名によって微妙にフォームを変える
            if (   'id' eq lc($column_name)
                || 'disable'                   eq lc($column_name)
                || 'lastupdate_user_master_id' eq lc($column_name) )
            {
                $config->{'form'} = { 'type' => 'hidden' };
            }
            elsif ('date_regist' eq lc($column_name)
                || 'date_update' eq lc($column_name) )
            {
                $config->{'form'} = { 'type' => 'hidden' };
            }
            elsif ( $indices{ $column->{'ID'} } ) {
                $config->{'form'} = { 'type' => 'select' };
            }
            else {
                $config->{'form'} = { 'type' => 'text', 'size' => 25 };
            }

            push @configs, $config;
            push @schemas, join( " ", @schema );
        }

        # 設定
        $classVar->{'schema'} = \@configs;
        $classVar->{'title'}
            = length( $this->encode( $table->{'remarks'} ) ) > 0 ? $this->encode( $table->{'remarks'} ) : $class_name;
        $classVar->{'table'}               = $table_name;
        $classVar->{'class_name'}          = $class_name;
        $classVar->{'class_template_path'} = $class_name;

        # コンフィグファイル出力
        my $config_vars;
        $config_vars->{'contents'} = Dumper $classVar;
        $helper->render_file( 'config_class', "$config_dir/$class_name.pl", $config_vars );

        # SQL出力
        my $schema_vars;
        $schema_vars->{'table'}   = $table_name;
        $schema_vars->{'comment'} = $this->encode( $table->{'remarks'} );
        $schema_vars->{'columns'} = join( ",\n", @schemas );
        $schema_vars->{'serials'} = join( "", @serials );
        $helper->render_file( 'schema_class', "$schema_dir/$table_name.sql", $schema_vars );
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
[% contents %]
__schema_class__
DROP TABLE [% table %];

-- [% comment %]
CREATE TABLE [% table %] (
[% columns %]
);

GRANT ALL ON [% table %] TO PUBLIC;
[% serials %]
