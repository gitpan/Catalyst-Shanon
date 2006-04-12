package Catalyst::Helper::View::ShanonHTML::Multi;

use strict;
use Data::Dumper;
use DirHandle;
use FileHandle;

# ------------------------------------------------------------
# ./ss_create.pl view Admin ShanonHTML
# 引数
# 1. view
# 2. view directory name
# 3. helper class
# 4. classes (スペースで区切って複数指定可)
# ------------------------------------------------------------

sub mk_compclass {
    my ( $self, $helper, @limited_file ) = @_;
    print "-----------------------------------------------------------\n";

    print Dumper @limited_file;

    # generate view from a configuration files
    # search file from config directory
    my $dir = sprintf( "%s/root/config", $helper->{base} );
    my $conf_dir = DirHandle->new($dir) or die "can't open dir, $!";
    my @files = sort grep -f, map "$dir/$_", $conf_dir->read;

    # create static directory
    $helper->mk_dir( sprintf( "%s/root/static/image", $helper->{'base'} ) );
    $helper->mk_dir( sprintf( "%s/root/static/css",   $helper->{'base'} ) );
    $helper->mk_dir( sprintf( "%s/root/static/js",    $helper->{'base'} ) );
    $helper->render_file( 'change_search_display',
        sprintf( "%s/root/static/js/change_search_display.js", $helper->{'base'} ) );

    # create template directory
    $helper->mk_dir( sprintf( "%s/root/template",    $helper->{'base'} ) );
    $helper->mk_dir( sprintf( "%s/root/template/%s", $helper->{'base'}, $helper->{'name'} ) );

    # create View class directory
    $helper->mk_dir(
        sprintf( "%s/lib/%s/%s/%s", $helper->{'base'}, $helper->{'app'}, $helper->{'type'}, $helper->{'name'} ) );

    # create View base class
    my $base_class = sprintf( "%s::%s::%s", $helper->{'app'}, $helper->{'type'}, $helper->{'name'} );
    $helper->render_file(
        'view_base_class',
        sprintf( "%s/lib/%s/%s/%s.pm", $helper->{'base'}, $helper->{'app'}, $helper->{'type'}, $helper->{'name'} ),
        { base_class => $base_class }
    );

    my %limit;
    $limit{$_} = 1 foreach (@limited_file);

    foreach my $file (@files) {

        # create config_name directory
        my @tmp = split '/', $file;
        my $dir = $tmp[-1];
        $dir =~ s/\.pl$//;
        my $path = sprintf( "%s/root/template/%s/%s", $helper->{'base'}, $helper->{'name'}, $dir );

        # -----------------------------------------------
        # only selected class
        if ( scalar @limited_file ) {
            next unless ( $limit{$dir} );
        }
        $helper->mk_dir($path);

        my $config = do "$file";
        my %vars;

        # -----------------------------------------------
        # class
        my $class_path = sprintf( "%s/lib/%s/%s/%s/%s.pm",
            $helper->{'base'}, $helper->{'app'}, $helper->{'type'}, $helper->{'name'}, $dir );
        $vars{'class'} = sprintf( "%s::%s::%s::%s", $helper->{'app'}, $helper->{'type'}, $helper->{'name'}, $dir );

        # for action url --------
        $vars{'dir'}        = lc($dir);
        $vars{'classname'}  = $dir;
        $vars{'base_class'} = $base_class;
        $vars{'parent'}     = sprintf( "%s::%s::%s", $helper->{'app'}, $helper->{'type'}, $helper->{'name'} );

        # -----------------------
        $helper->render_file( 'view_class', $class_path, \%vars );

        # -----------------------------------------------
        # add
        my @hidden;
        foreach ( @{ $config->{'schema'} } ) {
            if ( $_->{'form'}->{'type'} eq 'hidden' ) {

                # for hidden field
                push( @hidden, $_->{'name'} );
            }
            else {

                # for necessary input
                if ( $_->{'sql'}->{'notnull'} ) {
                    $vars{'line'} .= sprintf( '
<tr>
 <td class="labelCol">%s</td>
 <td class="dataCol col02">
  <div class="requiredInput">
   <div class="requiredBlock"></div>
   <span class="lookupInput">$FORM{%s}</span>
  </div>
 </td>
</tr>',
                        $_->{'desc'}, $_->{'name'} );
                }
                else {
                    $vars{'line'} .= sprintf( '
<tr>
 <td class="labelCol">%s</td>
 <td class="dataCol col02">$FORM{%s}</td>
</tr>',
                        $_->{'desc'}, $_->{'name'} );
                }

                # for search form
                if ( $_->{'form'}->{'default_search_key'} ) {
                    $vars{'default_search_key'} .= sprintf( '
<tr>
 <td>%s</td>
 <td>$FORM{%s}</td>
</tr>',
                        $_->{'desc'}, $_->{'name'} );
                }
                else {
                    $vars{'not_default_search_key'} .= sprintf( '
<tr>
 <td>%s</td>
 <td>$FORM{%s}</td>
</tr>',
                        $_->{'desc'}, $_->{'name'} );
                }
            }
        }
        $vars{'hidden'} .= join( "\n ", map( sprintf( '$FORM{%s}', $_ ), @hidden ) );
        $vars{'user'} = $ENV{'USER'};
        my ( $sec, $min, $hour, $mday, $mon, $year ) = localtime();
        $vars{'timestamp'}
            = sprintf( "%04d/%02d/%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec );

        $vars{'action'} = 'add';
        $helper->render_file( 'add', sprintf( "%s/add.html", $path ), \%vars );

        # -----------------------------------------------
        # preview
        $vars{'action'} = 'preview';
        $helper->render_file( 'preview', sprintf( "%s/preview.html", $path ), \%vars );

        # -----------------------------------------------
        # delete
        $vars{'action'} = 'delete';
        $helper->render_file( 'delete', sprintf( "%s/delete.html", $path ), \%vars );

        # -----------------------------------------------
        # disable
        $vars{'action'} = 'disable';
        $helper->render_file( 'delete', sprintf( "%s/disable.html", $path ), \%vars );

        # -----------------------------------------------
        # list
        $helper->render_file( 'list',   sprintf( "%s/list.html",   $path ), \%vars );
        $helper->render_file( 'search', sprintf( "%s/search.html", $path ), \%vars );

        # -----------------------------------------------
        # plain
        $helper->render_file( 'plain', sprintf( "%s/plain.html", $path ), \%vars );
    }
    print "==========================================================\n";
}

1;

__DATA__

__add__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
<!-- Start page content -->
<form action="$FORM{__baseurl__}[- dir -]/[- action -]" name="[- dir -]" method="post">
<div class="bPageTitle">
  <div class="ptBody secondaryPalette">
    <div class="content">
      <img src="/static/image/s.gif" alt="" class="pageTitleIcon">
      <h1 class="pageType">$FORM{body_title}<span  class="titleSeparatingColon">:</span></h1>
      <h2 class="pageDescription">ホーム</h2>
      <div class="blank">&nbsp;</div>
    </div>
  </div>
  <div class="bPageBlock bEditBlock secondaryPalette" id="ep">
    <div class="pbHeader">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td class="pbTitle"><img src="/static/image/s.gif" alt="" title="" class="minWidth" height="1" width="1">
              <h2 class="mainTitle">登録</h2></td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="pbBody">
      <div class="pbSubheader first tertiaryPalette" id="head_1_ep">
        <span class="pbSubExtra">
          <span class="requiredLegend">
            <span class="requiredExampleOuter">
              <span class="requiredExample">&nbsp;</span>
            </span>
            <span class="requiredText"> = 必須情報</span>
          </span>
        </span>
        <h3>登録情報<span class="titleSeparatingColon">:</span></h3>
      </div>
      <div class="pbSubsection">
        <table class="detailList" border="0" cellpadding="0" cellspacing="0">
          <tbody>
            [- line -]
            $FORM{multi}
          </tbody>
        </table>
      </div>
    </div>
    <div class="pbBottomButtons">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td align="center" class="pbButton">$FORM{submit}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="pbFooter secondaryPalette">
      <div class="bg"></div>
    </div>
  </div>
</div>
[- hidden -]
<input type="hidden" name="action" value="$FORM{action}">
</form>
<!-- End page content -->


__delete__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
<!-- Start page content -->
<form action="$FORM{__baseurl__}[- dir -]/[- action -]" name="[- dir -]" method="post">
<div class="bPageTitle">
  <div class="ptBody secondaryPalette">
    <div class="content">
      <img src="/static/image/s.gif" alt="" class="pageTitleIcon">
      <h1 class="pageType">$FORM{body_title}<span  class="titleSeparatingColon">:</span></h1>
      <h2 class="pageDescription">ホーム</h2>
      <div class="blank">&nbsp;</div>
    </div>
  </div>
  <div class="bPageBlock bEditBlock secondaryPalette" id="ep">
    <div class="pbHeader">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td class="pbTitle"><img src="/static/image/s.gif" alt="" title="" class="minWidth" height="1" width="1">
              <h2 class="mainTitle">削除</h2></td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="pbBody">
      <div class="pbSubheader first tertiaryPalette" id="head_1_ep">
        <span class="pbSubExtra">
          <span class="requiredLegend">
            <span class="requiredExampleOuter">
              <span class="requiredExample">&nbsp;</span>
            </span>
            <span class="requiredText"> = 必須情報</span>
          </span>
        </span>
        <h3>登録情報<span class="titleSeparatingColon">:</span></h3>
      </div>
      <div class="pbSubsection">
        <table class="detailList" border="0" cellpadding="0" cellspacing="0">
          <tbody>
            [- line -]
            $FORM{multi}
          </tbody>
        </table>
      </div>
    </div>
    <div class="pbBottomButtons">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td align="center" class="pbButton">$FORM{submit}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="pbFooter secondaryPalette">
      <div class="bg"></div>
    </div>
  </div>
</div>
[- hidden -]
<input type="hidden" name="action" value="$FORM{action}">
</form>
<!-- End page content -->


__preview__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
<!-- Start page content -->
<form action="$FORM{__baseurl__}[- dir -]/[- action -]" name="[- dir -]" method="post">
<div class="bPageTitle">
  <div class="ptBody secondaryPalette">
    <div class="content">
      <img src="/static/image/s.gif" alt="" class="pageTitleIcon">
      <h1 class="pageType">$FORM{body_title}<span  class="titleSeparatingColon">:</span></h1>
      <h2 class="pageDescription">ホーム</h2>
      <div class="blank">&nbsp;</div>
    </div>
  </div>
  <div class="bPageBlock bEditBlock secondaryPalette" id="ep">
    <div class="pbHeader">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td class="pbTitle"><img src="/static/image/s.gif" alt="" title="" class="minWidth" height="1" width="1">
              <h2 class="mainTitle">詳細</h2></td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="pbBody">
      <div class="pbSubheader first tertiaryPalette" id="head_1_ep">
        <span class="pbSubExtra">
          <span class="requiredLegend">
            <span class="requiredExampleOuter">
              <span class="requiredExample">&nbsp;</span>
            </span>
            <span class="requiredText"> = 必須情報</span>
          </span>
        </span>
        <h3>登録情報<span class="titleSeparatingColon">:</span></h3>
      </div>
      <div class="pbSubsection">
        <table class="detailList" border="0" cellpadding="0" cellspacing="0">
          <tbody>
            [- line -]
            $FORM{multi}
          </tbody>
        </table>
      </div>
    </div>
    <div class="pbBottomButtons">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td align="center" class="pbButton">$FORM{submit}</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="pbFooter secondaryPalette">
      <div class="bg"></div>
    </div>
  </div>
</div>
[- hidden -]
<input type="hidden" name="action" value="$FORM{action}">
</form>
<!-- End page content -->


__list__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
<!-- Start page content -->
<form action="$FORM{__baseurl__}[- dir -]/list" name="[- dir -]" method="post">
<div class="bPageTitle">
  <div class="ptBody secondaryPalette">
    <div class="content">
      <img src="/static/image/s.gif" alt="" class="pageTitleIcon">
      <h1 class="pageType">$FORM{body_title}<span  class="titleSeparatingColon">:</span></h1>
      <h2 class="pageDescription">ホーム</h2>
      <div class="blank">&nbsp;</div>
    </div>
  </div>
  <div class="bPageBlock bEditBlock secondaryPalette" id="ep">
$FORM{search}
  </div>
</div>

<div class="bRelatedList">
  <!-- Begin ListElement -->
  <!-- WrappingClass -->
  <div class="hotListElement">
    <div class="bPageBlock secondaryPalette">
$FORM{table}
    </div>
  </div>
  <div class="listElementBottomNav"></div>
  <!-- End ListElement -->
</div>
<!-- End RelatedListElement -->
</form>
<!-- End page content -->


__search__
[% TAGS [- -] %]
    <!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
    <script language="javascript" type="text/javascript" src="/static/js/change_search_display.js"></script>
    <div class="pbHeader">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td class="pbTitle"><img src="/static/image/s.gif" alt="" title="" class="minWidth" height="1" width="1">
              <h2 class="mainTitle">検索</h2></td>
            <td class="pbButton">
              <span id="search_display_on">
                <input type="button" value=" 詳細検索 " class="btn" name="Discount_:_-D-_:_btn_detail" onClick="javascript:showMoreLite('on'); set_search_type(this.form, 'detail');"></span>
              <span id="search_display_off" style="display:none">
                <input type="button" value=" 簡易検索 " class="btn" name="Discount_:_-D-_:_btn_simple" onClick="javascript:showMoreLite('off'); set_search_type(this.form, 'simple');"></span>
                <input type="submit" value=" 検索条件を保存 " class="btn" name="Session_:_-D-_:_btn_save">
                <input type="submit" value=" 検索条件のクリア " class="btn" name="Session_:_-D-_:_btn_crear"></td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="pbBody">
      <div class="pbSubheader first tertiaryPalette" id="head_1_ep">
        <h3>簡易検索項目<span class="titleSeparatingColon">:</span></h3>
      </div>
      <div class="pbSubsection">
        <table class="detailList" border="0" cellpadding="0" cellspacing="0">
          <tbody>
$FORM{default}
          </tbody>
        </table>
      </div>
      <div id="search_display" style="display:none">
        <div class="pbSubheader first tertiaryPalette" id="head_1_ep">
          <h3>詳細検索項目<span class="titleSeparatingColon">:</span></h3>
        </div>
        <div class="pbSubsection">
          <table class="detailList" border="0" cellpadding="0" cellspacing="0">
            <tbody>
$FORM{visible}
            </tbody>
          </table>
        </div>
      </div>
    </div>
    <div class="pbBottomButtons">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td align="center" class="pbButton">
              <input type="submit" value=" 検索開始 " class="btn" name="[- classname -]_:_-D-_:_btn_search">&nbsp;
              <input type="submit" value=" CSVダウンロード " class="btn" name="[- classname -]_:_-D-_:_btn_csv"></td>
            <td align="center" class="pbButton">&nbsp;</td>
          </tr>
        </tbody>
      </table>
    </div>
    <div class="pbFooter secondaryPalette">
      <div class="bg"></div>
    </div>
    <input type="hidden" name="search_type" value="">

__plain__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
[- line -]
[- hidden -]


__change_search_display__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
<script language="javascript" type="text/javascript">
function showMoreLite(type){
  var oneself_btn = ('search_display_' + (type));
  var target_btn = type == 'on' ? 'search_display_off' : 'search_display_on';
  if(document.getElementById){
    oneself = document.getElementById(oneself_btn);
    target = document.getElementById(target_btn);
    search_body = document.getElementById('search_display');
    oneself.style.display = "none";
    target.style.display = "inline";
    if(type == 'on'){
      search_body.style.display = "inline";
    } else {
      search_body.style.display = "none";
    }
  } else {
    return false;
  }
}
function set_search_type(form, type){
  form.search_type.value=type;
}
</script>


__view_base_class__
package [% base_class %];

use strict;
use base 'Catalyst::View::ShanonHTML';



1;


__view_class__
package [% class %];

use strict;
use base '[% parent %]';

##################################################
# 追加用コールバック群
##################################################
# __PACKAGE__->add_trigger(do_add_after => \&do_add_after);
# sub do_add_after {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }

##################################################
# 入力用コールバック群
##################################################
# __PACKAGE__->add_trigger(input_before_parse_form => \&input_before_parse_form);
# sub input_before_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(input_after_parse_form => \&input_after_parse_form);
# sub input_after_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(input_after_makebutton => \&input_after_makebutton);
# sub input_after_makebutton {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }

##################################################
# 確認用コールバック群
##################################################
# __PACKAGE__->add_trigger(confirm_before_parse_form => \&confirm_before_parse_form);
# sub confirm_before_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(confirm_after_parse_form => \&confirm_after_parse_form);
# sub confirm_after_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(confirm_after_makebutton => \&confirm_after_makebutton);
# sub confirm_after_makebutton {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }

##################################################
# プレビュー用コールバック群
##################################################
# __PACKAGE__->add_trigger(preview_before_parse_form => \&preview_before_parse_form);
# sub preview_before_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(preview_after_parse_form => \&preview_after_parse_form);
# sub preview_after_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(preview_after_makebutton => \&preview_after_makebutton);
# sub preview_after_makebutton {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }

##################################################
# 削除用コールバック群
##################################################
# __PACKAGE__->add_trigger(pre_delete_before_parse_form => \&pre_delete_before_parse_form);
# sub pre_delete_before_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(pre_delete_after_parse_form => \&pre_delete_after_parse_form);
# sub pre_delete_after_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(pre_delete_after_makebutton => \&pre_delete_after_makebutton);
# sub pre_delete_after_makebutton {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(do_delete_after => \&do_delete_after);
# sub do_delete_after {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }

##################################################
# 無効用コールバック群
##################################################
# __PACKAGE__->add_trigger(pre_disable_before_parse_form => \&pre_disable_before_parse_form);
# sub pre_disable_before_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(pre_disable_after_parse_form => \&pre_disable_after_parse_form);
# sub pre_disable_after_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(pre_disable_after_makebutton => \&pre_disable_after_makebutton);
# sub pre_disable_after_makebutton {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }

##################################################
# リスト用コールバック群
##################################################
# __PACKAGE__->add_trigger(list_createtable_set_hash_columns => \&list_createtable_set_hash_columns);
# sub list_createtable_set_hash_columns {
#     my $self = shift;
#     my $c = shift;
# }
#
# __PACKAGE__->add_trigger(before_list_createtable_data_escape => \&before_list_createtable_data_escape);
# sub before_list_createtable_data_escape {
#     my $self = shift;
#     my $c = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(after_list_createtable_data_escape => \&after_list_createtable_data_escape);
# sub after_list_createtable_data_escape {
#     my $self = shift;
#     my $c = shift;
#     my $form = shift;
# }

##################################################
# 検索用コールバック群
##################################################
# __PACKAGE__->add_trigger(list_search_before_parse_form => \&list_search_before_parse_form);
# sub list_search_before_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(list_search_after_parse_form => \&list_search_after_parse_form);
# sub list_search_after_parse_form {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }
#
# __PACKAGE__->add_trigger(list_search_after_makebutton => \&list_search_after_makebutton);
# sub list_search_after_makebutton {
#     my $self = shift;
#     my $c    = shift;
#     my $form = shift;
# }



1;
