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

# ��졼��������
my @relations;

# �ơ��֥����
my @tables;

####################################################################################################
# Cray Core �Υ����Ȥ� EUC-JP ���Ѵ�����
####################################################################################################
sub encode {
    my ( $this, $str ) = @_;
    if ( !defined $str || length($str) == 0 ) {
        return "";
    }
    my @array = split( //, $str );
    my @list;
    for ( my $i = 0; $i < scalar(@array); $i++ ) {

        # \\n �ϡ֡��פ��Ѥ����㤦
        if ( $array[$i] eq '\\' && $array[ $i + 1 ] eq 'n' ) {
            push @list, 129;
            push @list, 66;
            $i++;

            # \\\\ �ϡ�0x5C�פˤ���
        }
        elsif ( $array[$i] eq '\\' && $array[ $i + 1 ] eq '\\' ) {
            push @list, 92;
            $i++;

            # \\144 �ʤ�
        }
        elsif ( $array[$i] eq '\\' ) {
            push @list, $array[ $i + 1 ] . $array[ $i + 2 ] . $array[ $i + 3 ];
            $i += 3;

            # [ �ʤ�
        }
        elsif ( 13 < ord( $array[$i] ) && ord( $array[$i] ) < 128 ) {
            push @list, ord( $array[$i] );
        }
    }

    # SJIS ���� EUC ���Ѵ������֤�
    my $result = pack( "C*", @list );
    return jcode( $result, 'sjis' )->euc;
}

####################################################################################################
# hoge_fuga_master �� HogeFugaMaster ���Ѵ�����
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
# ���ꤵ�줿ID�Υ�졼�������֤�
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
# ���ꤵ�줿ID�Υơ��֥���֤�
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
# ���ꤵ�줿̾���Υ��������ֹ���֤�
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

    # �ե�����̾��ɬ��
    unless ($file) {
        die "usage: xxx_create.pl config ShanonConfig2 ShanonConfig2 [Cray Core File] [some modules]\n";
        return 1;
    }

    # XML�ե��������
    my $parser = new XML::Simple();
    my $tree   = $parser->XMLin($file);

    # ����ե�����SQL�ѤΥǥ��쥯�ȥ����
    my $config_dir = sprintf( "%s/root/config", $helper->{'base'} );
    my $schema_dir = sprintf( "%s/sql/schema",  $helper->{'base'} );
    $helper->mk_dir($config_dir);
    $helper->mk_dir($schema_dir);

    # ��졼�����ȥơ��֥�������������
    @relations = undef;    #@{$tree->{'METADATA'}->{'RELATIONS'}->{'RELATION'}};
    @tables    = undef;    #@{$tree->{'METADATA'}->{'TABLES'}->{'TABLE'}};
    my $table_list = $tree->{'database-model'}->{'schema-list'}->{'schema'}->{'table-list'}->{'table'};

    # ���ꤷ���⥸�塼��Τ�
    my %limit;
    $limit{$_} = 1 foreach (@limited_file);

    foreach my $table_name ( keys %{$table_list} ) {
        my $table      = $table_list->{$table_name};
        my $class_name = $this->get_class_name($table_name);

        # ���ꤷ���⥸�塼��Τ�
        if ( scalar @limited_file ) {
            next unless ( $limit{$class_name} );
        }

        # ����ե�����
        my $classVar;

        # �ƥơ��֥�����������
        #my @columns = @{$table->{'COLUMNS'}->{'COLUMN'}};
        my $columns = $table->{'column-list'}->{'column'};

        # �ƥơ��֥�Υ���ǥå���������
        my %indices;

        #if (ref($table->{'INDICES'}->{'INDEX'}) eq 'HASH') {
        #    # ���ǰ�ĤΤȤ��ϥϥå���ˤʤäƤ��ޤ��ΤǤ����к�
        #    my $key = $table->{'INDICES'}->{'INDEX'}->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
        #    my $val = $table->{'INDICES'}->{'INDEX'}->{'FKRefDef_Obj_id'};
        #    # �祭����̵�뤹��
        #    unless ($val eq '-1') {
        #        $indices{$key} = $val;
        #    }
        #} elsif (ref($table->{'INDICES'}->{'INDEX'}) eq 'ARRAY') {
        #    foreach my $index (@{$table->{'INDICES'}->{'INDEX'}}) {
        #        my $key = $index->{'INDEXCOLUMNS'}->{'INDEXCOLUMN'}->{'idColumn'};
        #        my $val = $index->{'FKRefDef_Obj_id'};
        #        # �祭����̵�뤹��
        #        unless ($val eq '-1') {
        #            $indices{$key} = $val;
        #        }
        #    }
        #}

        my @serials;    # �������󥹰���
        my @configs;    # �ƥ���ե���
        my @schemas;    # ��SQL
        foreach my $column_name ( keys %{$columns} ) {
            my $column = $columns->{$column_name};
            my $sql;
            my $config;
            my @schema;

            # �����̾
            push @schema, "        " . $column_name;

            # ��
            if ( $column->{'auto-increment'} eq "true" ) {

                # AutoInc="1" ���ä���֥ơ��֥�̾_�����̾_seq�פȤ���
                # �ơ��֥�� Postgresql ����ư��������ΤǤ����б�
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

            # �祭�����ɤ���
            if ( $table->{'primary-key'}->{'primary-key-column'}->{'name'} eq lc($column_name) ) {
                $sql->{'primarykey'} = 1;
                push @schema, "PRIMARY KEY";
            }
            elsif ( 'id' eq lc($column_name) ) {

                # id �ϼ�ưŪ�˼祭���ˤ���
                $sql->{'primarykey'} = 1;
                push @schema, "PRIMARY KEY";
            }

            # �ǥե������
            if ( length( $column->{'default-value'} ) > 0 ) {
                $sql->{'default'} = $column->{'default-value'};
                push @schema, sprintf( "DEFAULT '%s'", $column->{'default-value'} );
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'DATE' ) {

                # ���դϼ�ưŪ�����ꤹ��
                $sql->{'default'} = "('now'::text)::timestamp";
                push @schema, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( $column->{'data-type'}->{'name'} eq 'TIMESTAMP' ) {

                # �����ϼ�ưŪ�����ꤹ��
                $sql->{'default'} = "('now'::text)::timestamp";
                push @schema, "DEFAULT ('now'::text)::timestamp";
            }
            elsif ( 'disable' eq lc($column_name) ) {

                # disable �ϼ�ưŪ�� 0 �ˤ���
                $sql->{'default'} = "0";
                push @schema, "DEFAULT '0'";
            }

            # NOT NULL ����
            if ( $column->{'mandatory'} eq 'true' ) {
                $sql->{'notnull'} = 1;
                push @schema, "NOT NULL";
            }
            elsif ( 'disable' eq lc($column_name) ) {

                # disable �ϼ�ưŪ�� NOT NULL �ˤ���
                $sql->{'notnull'} = 1;
                push @schema, "NOT NULL";
            }

            # ��������
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

            # ������
            if ( 'id' eq lc($column_name) ) {

                # id �ϼ�ưŪ�� ID �ˤ���
                push @schema, '/* ID */';
            }
            elsif ( 'disable' eq lc($column_name) ) {

                # disable �ϼ�ưŪ�� ��� �ˤ���
                push @schema, '/* ��� */';
            }
            else {
                push @schema, sprintf( "/* %s */", $this->encode( $column->{'remarks'} ) );
            }

            $config->{'sql'}  = $sql;
            $config->{'name'} = $column_name;

            # ��̾�ˤ�ä���̯�˥������������Ѥ���
            if ( $column_name eq 'id' ) {
                $config->{'desc'}    = 'ID';
                $config->{'findrow'} = 'default';
                $config->{'metarow'} = 'default';
            }
            elsif ( $column_name eq 'disable' ) {
                $config->{'desc'}    = '����ե饰';
                $config->{'findrow'} = 'invisible';
                $config->{'metarow'} = 'invisible';
            }
            elsif ( $column_name eq 'date_regist' ) {
                $config->{'desc'}    = '��Ͽ����';
                $config->{'findrow'} = 'visible';
                $config->{'metarow'} = 'visible';
            }
            elsif ( $column_name eq 'date_update' ) {
                $config->{'desc'}    = '��������';
                $config->{'findrow'} = 'visible';
                $config->{'metarow'} = 'visible';
            }
            else {
                $config->{'desc'} = $this->encode( $column->{'remarks'} );

                # �������������ʤ��Ȥ��ϥ����̾����ʸ�����Ѵ�
                if ( length( $config->{'desc'} ) == 0 ) {
                    $config->{'desc'} = uc $column_name;
                }
                $config->{'findrow'} = 'default';
                $config->{'metarow'} = 'default';
            }

            # ��̾�ˤ�ä���̯�˥ե�������Ѥ���
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

        # ����
        $classVar->{'schema'} = \@configs;
        $classVar->{'title'}
            = length( $this->encode( $table->{'remarks'} ) ) > 0 ? $this->encode( $table->{'remarks'} ) : $class_name;
        $classVar->{'table'}               = $table_name;
        $classVar->{'class_name'}          = $class_name;
        $classVar->{'class_template_path'} = $class_name;

        # ����ե����ե��������
        my $config_vars;
        $config_vars->{'contents'} = Dumper $classVar;
        $helper->render_file( 'config_class', "$config_dir/$class_name.pl", $config_vars );

        # SQL����
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
