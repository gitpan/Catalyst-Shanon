package Catalyst::Helper::View::ShanonHTML;

use strict;
use Data::Dumper;
use DirHandle;
use FileHandle;

# ------------------------------------------------------------
# ./ss_create.pl view Admin ShanonHTML
# ����
# 1. view
# 2. view directory name
# 3. helper class
# 4. classes (���ڡ����Ƕ��ڤä�ʣ�������)
# ------------------------------------------------------------

sub mk_compclass {
    my ( $self, $helper, @limited_file ) = @_;
    print "-----------------------------------------------------------\n";

    print Dumper @limited_file;

    # generate view from a configuration files
    # search file from config directory
    my $dir = sprintf( "%s/config", $helper->{base} );
    my $conf_dir = DirHandle->new($dir) or die "can't open dir, $!";
    my @files = sort grep -f, map "$dir/$_", $conf_dir->read;

    unless (@limited_file) {

        # create static directory
        $helper->mk_dir( sprintf( "%s/root/static/image", $helper->{'base'} ) );
        $helper->mk_dir( sprintf( "%s/root/static/css",   $helper->{'base'} ) );
        $helper->mk_dir( sprintf( "%s/root/static/js",    $helper->{'base'} ) );

        # create static file
        $helper->render_file( 'common_css', sprintf( "%s/root/static/css/common.css", $helper->{'base'} ) );
        $helper->render_file( 'change_search_display',
            sprintf( "%s/root/static/js/change_search_display.js", $helper->{'base'} ) );
    }

    # create template directory
    $helper->mk_dir( sprintf( "%s/root/template",    $helper->{'base'} ) );
    $helper->mk_dir( sprintf( "%s/root/template/%s", $helper->{'base'}, $helper->{'name'} ) );

    unless (@limited_file) {

        # create footer.html
        $helper->render_file( 'footer_html',
            sprintf( "%s/root/template/%s/footer.html", $helper->{'base'}, $helper->{'name'} ) );

        # create header.html
        $helper->render_file( 'header_html',
            sprintf( "%s/root/template/%s/header.html", $helper->{'base'}, $helper->{'name'} ) );

        # create index.html
        $helper->render_file( 'index_html',
            sprintf( "%s/root/template/%s/index.html", $helper->{'base'}, $helper->{'name'} ) );

        # create table.html
        $helper->render_file( 'table_html',
            sprintf( "%s/root/template/%s/table.html", $helper->{'base'}, $helper->{'name'} ) );
    }

    # create View class directory
    $helper->mk_dir(
        sprintf( "%s/lib/%s/%s/%s", $helper->{'base'}, $helper->{'app'}, $helper->{'type'}, $helper->{'name'} ) );

    # app base class
    $helper->render_file(
        'app_base_class',
        sprintf( "%s/lib/%s.pm", $helper->{'base'}, $helper->{'app'} ),
        { base_class => $helper->{'app'} }
    );

    # create View base class
    my $base_class = sprintf( "%s::%s::%s", $helper->{'app'}, $helper->{'type'}, $helper->{'name'} );
    unless (@limited_file) {
        $helper->render_file(
            'view_base_class',
            sprintf( "%s/lib/%s/%s/%s.pm", $helper->{'base'}, $helper->{'app'}, $helper->{'type'}, $helper->{'name'} ),
            { base_class => $base_class }
        );
    }
    my %limit;
    $limit{$_} = 1 foreach (@limited_file);

    foreach my $file (@files) {

        # create config_name directory
        my @tmp = split '/', $file;
        my $dir = $tmp[-1];
        $dir =~ s/\.pl$//;
        my $path = sprintf( "%s/root/template/%s/%s", $helper->{'base'}, $helper->{'name'}, $dir );

        # only selected class
        if ( scalar @limited_file ) {
            next unless ( $limit{$dir} );
        }
        $helper->mk_dir($path);

        my $config = do "$file";
        my %vars;

        # class
        my $class_path = sprintf( "%s/lib/%s/%s/%s/%s.pm",
            $helper->{'base'}, $helper->{'app'}, $helper->{'type'}, $helper->{'name'}, $dir );
        $vars{'class'} = sprintf( "%s::%s::%s::%s", $helper->{'app'}, $helper->{'type'}, $helper->{'name'}, $dir );

        # for action url
        $vars{'dir'}        = lc($dir);
        $vars{'classname'}  = $dir;
        $vars{'base_class'} = $base_class;
        $vars{'app'}        = $helper->{'app'};
        $vars{'parent'}     = sprintf( "%s::%s::%s", $helper->{'app'}, $helper->{'type'}, $helper->{'name'} );

        # view class
        $helper->render_file( 'view_class', $class_path, \%vars );

        # add.html
        my @hidden;
        foreach ( @{ $config->{'schema'} } ) {
            if ( $_->{'temporary'} ) {

                # do nothing
            }
            elsif ( $_->{'form'}->{'type'} eq 'hidden' ) {

                # for hidden field
                push( @hidden, $_->{'name'} );
            }
            else {

                # for necessary input
                if (   $_->{'sql'}->{'notnull'}
                    || $_->{'form'}->{'notnull'} )
                {
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

        # csvupload.html
        $vars{'action'} = 'csvupload';
        $helper->render_file( 'csvupload', sprintf( "%s/csvupload.html", $path ), \%vars );

        # preview.html
        $vars{'action'} = 'view';
        $helper->render_file( 'preview', sprintf( "%s/view.html", $path ), \%vars );

        # delete.html
        $vars{'action'} = 'delete';
        $helper->render_file( 'delete', sprintf( "%s/delete.html", $path ), \%vars );

        # disable.html
        $vars{'action'} = 'disable';
        $helper->render_file( 'delete', sprintf( "%s/disable.html", $path ), \%vars );

        # list.html
        $helper->render_file( 'list',   sprintf( "%s/list.html",   $path ), \%vars );
        $helper->render_file( 'search', sprintf( "%s/search.html", $path ), \%vars );

        # plain.html
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
      <h2 class="pageDescription">$FORM{body_subtitle}</h2>
      <div class="blank">&nbsp;</div>
    </div>
    <div class="links">
      <!-- <a href="javascript:openPopupFocusEscapePounds('#', 'Help', 700, 600, 'width=700,height=600,resizable=yes,toolbar=no,status=no,scrollbars=yes,menubar=yes,directories=no,location=no,dependant=no', false, false);"><span  class="helpLink">���Υڡ����Υإ��</span><img src="/static/image/s.gif" alt="" class="helpImage"></a> -->
    </div>
  </div>
  <div class="ptBreadcrumb"></div>
</div>
$FORM{body_message}
<!-- Begin RelatedListElement -->
<div class="bRelatedList">
  <div class="bPageBlock bEditBlock secondaryPalette" id="ep">
    <div class="pbHeader">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td class="pbTitle"><img src="/static/image/s.gif" alt="" title="" class="minWidth" height="1" width="1">
              <h2 class="mainTitle">��Ͽ</h2></td>
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
            <span class="requiredText"> = ɬ�ܾ���</span>
          </span>
        </span>
        <h3>��Ͽ����<span class="titleSeparatingColon">:</span></h3>
      </div>
      <div class="pbSubsection">
        <table class="detailList" border="0" cellpadding="0" cellspacing="0">
          <tbody>
            [- line -]
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

__csvupload__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
<!-- Start page content -->
<form action="$FORM{__baseurl__}[- dir -]/[- action -]" name="[- dir -]" method="post" enctype="multipart/form-data">
<div class="bPageTitle">
  <div class="ptBody secondaryPalette">
    <div class="content">
      <img src="/static/image/s.gif" alt="" class="pageTitleIcon">
      <h1 class="pageType">$FORM{body_title}<span  class="titleSeparatingColon">:</span></h1>
      <h2 class="pageDescription">$FORM{body_subtitle}</h2>
      <div class="blank">&nbsp;</div>
    </div>
    <div class="links">
      <!-- <a href="javascript:openPopupFocusEscapePounds('#', 'Help', 700, 600, 'width=700,height=600,resizable=yes,toolbar=no,status=no,scrollbars=yes,menubar=yes,directories=no,location=no,dependant=no', false, false);"><span  class="helpLink">���Υڡ����Υإ��</span><img src="/static/image/s.gif" alt="" class="helpImage"></a> -->
    </div>
  </div>
  <div class="ptBreadcrumb"></div>
</div>
$FORM{body_message}
<!-- Begin RelatedListElement -->
<div class="bRelatedList">
  <div class="bPageBlock bEditBlock secondaryPalette" id="ep">
    <div class="pbHeader">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td class="pbTitle"><img src="/static/image/s.gif" alt="" title="" class="minWidth" height="1" width="1">
              <h2 class="mainTitle">��Ͽ</h2></td>
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
            <span class="requiredText"> = ɬ�ܾ���</span>
          </span>
        </span>
        <h3>��Ͽ����<span class="titleSeparatingColon">:</span></h3>
      </div>
      <div class="pbSubsection">
        <table class="detailList" border="0" cellpadding="0" cellspacing="0">
          <tbody>
            
<tr>
 <td class="labelCol">CSV�ե�����</td>
 <td class="dataCol col02">$FORM{csvupload_csv_file}</td>
</tr>
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
      <h2 class="pageDescription">$FORM{body_subtitle}</h2>
      <div class="blank">&nbsp;</div>
    </div>
    <div class="links">
      <!-- <a href="javascript:openPopupFocusEscapePounds('#', 'Help', 700, 600, 'width=700,height=600,resizable=yes,toolbar=no,status=no,scrollbars=yes,menubar=yes,directories=no,location=no,dependant=no', false, false);"><span  class="helpLink">���Υڡ����Υإ��</span><img src="/static/image/s.gif" alt="" class="helpImage"></a> -->
    </div>
  </div>
  <div class="ptBreadcrumb"></div>
</div>
$FORM{body_message}
<!-- Begin RelatedListElement -->
<div class="bRelatedList">
  <div class="bPageBlock bEditBlock secondaryPalette" id="ep">
    <div class="pbHeader">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td class="pbTitle"><img src="/static/image/s.gif" alt="" title="" class="minWidth" height="1" width="1">
              <h2 class="mainTitle">���</h2></td>
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
            <span class="requiredText"> = ɬ�ܾ���</span>
          </span>
        </span>
        <h3>��Ͽ����<span class="titleSeparatingColon">:</span></h3>
      </div>
      <div class="pbSubsection">
        <table class="detailList" border="0" cellpadding="0" cellspacing="0">
          <tbody>
            [- line -]
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
<form action="$FORM{__baseurl__}[- dir -]/preview" name="[- dir -]" method="post">
<div class="bPageTitle">
  <div class="ptBody secondaryPalette">
    <div class="content">
      <img src="/static/image/s.gif" alt="" class="pageTitleIcon">
      <h1 class="pageType">$FORM{body_title}<span  class="titleSeparatingColon">:</span></h1>
      <h2 class="pageDescription">$FORM{body_subtitle}</h2>
      <div class="blank">&nbsp;</div>
    </div>
    <div class="links">
      <!-- <a href="javascript:openPopupFocusEscapePounds('#', 'Help', 700, 600, 'width=700,height=600,resizable=yes,toolbar=no,status=no,scrollbars=yes,menubar=yes,directories=no,location=no,dependant=no', false, false);"><span  class="helpLink">���Υڡ����Υإ��</span><img src="/static/image/s.gif" alt="" class="helpImage"></a> -->
    </div>
  </div>
  <div class="ptBreadcrumb"></div>
</div>
$FORM{body_message}
<!-- Begin RelatedListElement -->
<div class="bRelatedList">
  <div class="bPageBlock bEditBlock secondaryPalette" id="ep">
    <div class="pbHeader">
      <table border="0" cellpadding="0" cellspacing="0">
        <tbody>
          <tr>
            <td class="pbTitle"><img src="/static/image/s.gif" alt="" title="" class="minWidth" height="1" width="1">
              <h2 class="mainTitle">�ܺ�</h2></td>
            <td class="pbButton"><input type="submit" value=" �Խ� " class="btn" name="btn_edit"></td>
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
            <span class="requiredText"> = ɬ�ܾ���</span>
          </span>
        </span>
        <h3>��Ͽ����<span class="titleSeparatingColon">:</span></h3>
      </div>
      <div class="pbSubsection">
        <table class="detailList" border="0" cellpadding="0" cellspacing="0">
          <tbody>
            [- line -]
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
      <h2 class="pageDescription">$FORM{body_subtitle}</h2>
      <div class="blank">&nbsp;</div>
    </div>
    <div class="links">
      <!-- <a href="javascript:openPopupFocusEscapePounds('#', 'Help', 700, 600, 'width=700,height=600,resizable=yes,toolbar=no,status=no,scrollbars=yes,menubar=yes,directories=no,location=no,dependant=no', false, false);"><span  class="helpLink">���Υڡ����Υإ��</span><img src="/static/image/s.gif" alt="" class="helpImage"></a> -->
    </div>
  </div>
  <div class="ptBreadcrumb"></div>
</div>
$FORM{body_message}
<!-- Begin RelatedListElement -->
<div class="bRelatedList">
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
      <h2 class="mainTitle">����</h2></td>
    <td class="pbButton">
      <span id="search_display_on">
        <input type="button" value=" �ܺٸ��� " class="btn" name="btn_detail" onClick="javascript:showMoreLite('on'); set_search_type(this.form, 'detail');"></span>
      <span id="search_display_off" style="display:none">
        <input type="button" value=" �ʰ׸��� " class="btn" name="btn_simple" onClick="javascript:showMoreLite('off'); set_search_type(this.form, 'simple');"></span>
        <input type="submit" value=" �������Υ��ꥢ " class="btn" name="btn_crear"></td>
  </tr>
</tbody>
</table>
</div>
<div class="pbBody">
<div class="pbSubsection">
<table class="detailList" border="0" cellpadding="0" cellspacing="0">
  <tbody>
$FORM{default}
  </tbody>
</table>
</div>
<div id="search_display" style="display:none">
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
      <input type="submit" value=" �������� " class="btn" name="btn_search">&nbsp;
      <input type="submit" value=" CSV��������� " class="btn" name="btn_csvdownload"></td>
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

__footer_html__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
<div class="bPageFooter">
  <div class="body">
    <DIV><A href="#">�����ȥޥå�</A> | <A href="#">�ץ饤�Х����ݥꥷ��</A> | <A href="#">��������</A></DIV>
  </div>
  <div class="footer">
    <DIV id="copyright">Copyright (C) 2000-2006 Shanon, Inc. All Rights Reserved.</DIV>
    <br>
  </div>
</div>

__header_html__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
<table class="tabsNewBar" border="0" cellspacing="0" cellpadding="0">
<tr>
  <td>
    <div class="tabNavigation">
      <table class="tab" cellpadding="0" cellspacing="0" border="0">
$FORM{'menu1'}
      </table>
    </div>
  </tr>
</table>

__index_html__
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<title>Sm@rtWorker</title>
<link href="/static/css/common.css" type="text/css" media="handheld,print,projection,screen,tty,tv" rel="stylesheet">
<!--
<link href="/static/css/custom.css" type="text/css" media="handheld,print,projection,screen,tty,tv" rel="stylesheet">
<link href="/static/css/assistive.css" type="text/css" media="aural,braille,embossed" rel="stylesheet">
<script type="text/javascript" src="/static/css/functions.js"></script>
<script type="text/javascript" src="/static/css/setup.js"></script>
<script type="text/javascript" src="/static/css/roletreenode.js"></script>
<script type="text/javascript" src="/static/js/calendar.js"></script>
<script type="text/javascript" src="/static/js/functions.js"></script>
<script type="text/javascript" src="/static/js/prototype.js"></script>
<script type="text/javascript" src="/static/js/html_edit.js"></script>
<script language="JavaScript1.2" src="/static/css/session.js"></script>
<link href="/static/css/gNavi.css" rel="stylesheet" type="text/css">
<link rel="stylesheet" href="/static/css/debug.css">
<script type="text/javascript" src="/static/js/ie_xmlhttp.js"></script>
<script type="text/javascript" src="/static/js/debug.js"></script>
-->
$FORM{javascript}
</head>
<body onload="$FORM{onload}" class="$FORM{style_main} overviewPage">
$FORM{header}
<table class="outer" border="0" cellpadding="0" cellspacing="0" width="100%">
  <tbody>
    <tr>
      <td class="oLeft">
        <div class="mCustomLink">
          <div class="content$FORM{seminar_palette}">
            <div class="header">
              <h2>��˥塼</h2>
            </div>
            <div class="body">
              <ul>
                $FORM{'menu2'}
              </ul>
            </div>
          </div>
        </div>
        <!--
        <div class="mRecentItem">
          <div class="content">
            <div class="body">
              <a href="/seminar/logout" class="solution"><img src="/static/image/s.gif" alt="" class="mruIcon"><span class="mruText">�����ߥʡ�����</span></a></div>
          </div>
        </div>
        <div class="mRecycle">
          <div class="content">
            <div class="body">
              <img src="/static/image/icon/sm_recycle.gif" width="26" height="19" align="absmiddle"><a href="/public/logout">�����ƥ��������</a></div>
          </div>
        </div>
        <div class="mRecentItem">
          <div class="content">
            <div class="header">
              <h2>�Ƕ�����󤷤����ߥʡ�</h2>
            </div>
            $FORM{'menu3'}
          </div>
        </div>
        <div class="mRecentItem">
          <div class="content">
            <div class="header">
              <h2>�褯�Ȥ��������</h2>
            </div>
            $FORM{'menu4'}
          </div>
        </div>
        <div class="mFind">
          <div class="content">
            <div class="header">
              <h2>Powered by SHANON</h2>
            </div>
            <div align="center"><a href="http://www.shanon.co.jp" class="lead" target="_blank"><img src="/static/image/shanoLogo.gif" alt=""></a></div>
          </div>
        </div>
        -->
      </td>
      <td class="oRight">
        $FORM{'body'}
      </td>
    </tr>
  </tbody>
</table>
$FORM{footer}
</body>
</html>

__table_html__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
<div class="pbHeader">
  <table border="0" cellpadding="0" cellspacing="0">
    <tbody>
      <tr>
        <td class="pbButton">
          ��<input type="submit" value=" ������Ͽ " class="btn" name="btn_new">
          <input type="submit" value=" �����Ͽ " class="btn" name="btn_csvupload"></td>
        <td class="pbTitle"><img src="/static/image/s.gif" class="minWidth" height="1" width="1">
          <h3>$FORM{view_range}</h3></td>
        <td class="pbHelp">
          1�Ǥ�ɽ�����&nbsp;$FORM{page_list}&nbsp;<input type="submit" class="btn" value=" �ѹ� " name="btn_change"></td>
        <td class="pbHelp">
          �ǰ�ư&nbsp;$FORM{page_num}&nbsp;<input type="submit" class="btn" value= " ��ư " name="btn_go"></td>
      </tr>
    </tbody>
  </table>
</div>
<div class="pbBody">
  <table class="list" border="0" cellpadding="0" cellspacing="0">
    <tbody>
      $FORM{table}
    </tbody>
  </table>
</div>
<div class="pbFooter secondaryPalette">
  <div class="bg"></div>
</div>

__common_css__
/* -------------- */
/* skin: Salesforce */
/* cssSheet: common */
/* postfix:  */

/* common.css */
/* this is a great place for application-wide styles (comomon.html.* entities & so on) */
/* It will import into every page of the app (popups, setup, 'regular pages' etc... */


/* BEGIN General page styles */

pre.exception {
    font-size: 145%;
}

body, td {
    margin:0px;
    color:#333;
}

body {
/*  background-image: url(../images/bgTop.gif); */
    background-repeat: repeat-x;
    background-position: left top;
    font-size: 75%;
    font-family: 'Arial', 'Helvetica', sans-serif;
    background-color: #FFF;
}

a {
    color:#333;
}

a:hover {
    text-decoration:underline;
}

th {
    text-align: left;
    font-weight: bold;
    white-space: nowrap;
}

form {
    margin:0px;
    padding:0px;
}

h1, h2, h3, h4, h5, h6 {
    font-family: 'Verdana', 'Geneva', sans-serif;
    font-size: 100%;
    margin:0px;
    display:inline;
}

textarea {
    font-family: 'Arial', 'Helvetica', sans-serif;
    font-size: 100%;
 }

select {
    color:#000;
}
/* prevent browsers from overwriting the font-size. It should be the same as the select. */
select option,
select optgroup {
    font-size: 100%;
}

img { border:0; }

dl { margin-left: 1em; }

dt { font-weight: bold; }

fieldset legend {
    font-weight: bold;
    color: black;
}

fieldset ul {
    padding: 0;
}

ul li {
    margin-left: 1.5em;
    padding-left: 0;
}

input { /* added to make inputs on detail elements look ok */
    padding-top: 0;
}

/* use this to clear floats */
.clearingBox {
    clear:both;
    font-size:1px;
}

.advisory {
    font-style: italic;
}

.hidden {
    display:none;
}

.errorStyle,
.errorMsg,
.importantWarning {
   font-weight: bold;
   color: #C00;
}

.allSeminarMode {
    font-weight: bold;
    background-color: #C00;
    color: #FFFFFF;
}

.requiredMark {
    color: white;
    display: none;
}

.requiredInput .requiredMark {
    display: inline;
}

.fewerMore {
    text-align: center;
    font-size: 109%;
}

.topLinks {
    text-align: center;
    margin-bottom: 2px;
}
.topLinks .calendarIconBar img {
    float: none;
    display: inline;
}

/* Colons after titles in Classic mode */
.titleSeparatingColon {
    display: none;
}

/* Added by rchen for Campaign Add Contacts Wizard */
.statusMsg {
    padding: 4px;
    margin: 4px;
    border: 1px solid #333;
    background-color: #FFC;
    display: block;
}
.disabledInput {
    background-color: #EBEBE4;
}

/* Used in reports */
.confidential {
    padding: 10px;
    text-align: center;
    font-size: 91%;
    font-style: italic;
    color: #777;
}

/* Used in wizards */

.exampleBox {
    background-color: #FFFFEE;
    border: 1px solid #AAA;
    margin: 0 0.5em;
    padding: 0 0.25em;
}

.selectAndClearAll {
    display: block;
}

/* for textareas, to warn about going over the limit */
.textCounterOuter {
    text-align: right;
    padding: 2px 0;
}

.textCounterMiddle {
    border: 1px solid #fff;
    padding: 2px;
    display: none;
}
.textCounterMiddle.warn,
.textCounterMiddle.over {
    display: inline;
}
.textCounter {
    padding: 0 2px;
    display: inline;
    font-size: 93%;
}
.warn .textCounter {
    background-color: #FF6;
    color: #000;
}
.over .textCounter {
    background-color: #F33;
    color: #FFF;
}

/* END General page styles */
/* --------------------------------------------- */
/* BEGIN Toolbar nav links */

.multiforce {
    padding-top: 2px;
    white-space: nowrap;
    font-weight: bold;
    text-align: right;
}

.multiforce select {
    font-weight:bold;
    font-size: 100%;
}

.multiforce #toolbar{
    display: inline;
    padding: 8px 10px 8px 116px;
    background: url(/static/image/tab/abg.gif) no-repeat bottom left;
}

.multiforce #toolbar .btnGo {
    margin: 0;
}

.multiforce .navLinks  {
    color:#999;
    padding-bottom: 8px;
}

.multiforce .navLinks a {
    padding: 0 2px;
    color: #000;
}

.multiforce .navLinks .links {
    position: relative;
}

.multiforce .poweredBy {
    padding-right: 4px;
}

.multiforce .currentlySu {
    color: #C00;
    font-weight: bold;
    text-transform: uppercase;
}

.multiforce .poweredBy a {
    font-weight: normal;
    font-size: 93%;
    text-decoration: none;
    margin-right: 0.5em;
}

.multiforce .poweredBy a:hover {
    text-decoration: underline;
}

.multiforce .warning {
    font-weight:bold;
}

/* END Toolbar nav links */
/* -------------------------------------- */
/* BEGIN Tab bar */
.bPageHeader .phHeader,
.tabsNewBar {
  width:100%;
  border: 0;
  margin: 0;
  padding: 0;
}
table.tabsNewBar tr.newBar {
  display:none;
}

.tabNavigation {
    padding-bottom:10px;
    padding-left: 10px;
    margin-bottom:6px;
    font-size: 91%;
    font-family: 'Verdana', 'Geneva', sans-serif;
}
table.tab {
    line-height:normal;
}
.tab td {
    text-align:center;
    background-image: url(/static/image/tab/left.gif);
    background-repeat: no-repeat;
    background-position: left top;
    margin:0;
    padding:0 0 0 6px;
    border-bottom:1px solid #A4A29E;
}
.tab a {
    text-decoration:none;
    color:#444;
}
.tab div {
    background-image:url(/static/image/tab/right.gif);
    background-repeat: no-repeat;
    background-position: right top;
    padding:3px 9px 5px 3px;
}
.tab a:hover {
    text-decoration:underline;
    color:#333;
}
.tab td.currentTab {
    color:#FFFFFF;
    font-weight:bold;
    background-color: transparent;
    border-bottom-width: 1px;
    border-bottom-style: solid;
}
.tab .currentTab div {
    color:#FFFFFF;
    padding:4px 9px 4px 3px;
}
.tab .currentTab a,
.tab .currentTab a:hover {
    color: #FFF;
}

.tab .last div {
    background-image:url(/static/image/tab/last.gif);
}

.tabNavigation,
.blank .tabNavigation {
    background-image:url(/static/image/tab/blank_bg.gif);
    background-repeat: repeat-x;
    background-position: bottom;
}

.allTabsArrow { background-image: url(/static/image/tab/arrow.gif);
        width:6px;
        height:9px; }

.allTab .currentTab .allTabsArrow { background-image: url(/static/image/tab/arrowWhite.gif);
        width:6px;
        height:9px; }

/* END Tab Bar */
/* ------------------------------------------- */
/* BEGIN Legacy tab styles for MH pages */
/* Don't use these */
.tabOn {
   font-family: 'Verdana', 'Arial', 'Helvetica';
   font-weight: bold;
   font-size: 10pt;
   color: #FFFFFF;
   text-decoration: none;
   background-color: #669900;
}

A:link.tabOn {
   font-family: 'Verdana', 'Arial', 'Helvetica';
   font-weight: bold;
   font-size: 10pt;
   color: #FFFFFF;
   text-decoration: none;
   background-color: #669900;
}

.tabOff {
   font-family: 'Verdana', 'Arial', 'Helvetica';
   font-weight: normal;
   font-size: 10pt;
   color: #FFFFFF;
   text-decoration: none;
   background-color: #336699;
}

A:link.tabOff {
   font-family: 'Verdana', 'Arial', 'Helvetica';
   font-weight: normal;
   font-size: 10pt;
   color: #FFFFFF;
   text-decoration: none;
   background-color: #336699;
}
/* END Legacy tab styles */
/* ---------------------------------------- */
/* BEGIN Layout Table - outer */
.outerNoSidebar {
    padding:0px 10px 10px 10px;
    width:100%;
}
.outer {
    margin:0px 0px 0px 0px;
}
.outer td.oRight {
    padding:0 5px 10px 10px;
    background-color:#FFFFFF;
}
.outer td {
    vertical-align:top;
}

.outer .oRight .spacer{
    width:678px;
}
.outer .oLeft .spacer, .outer td.oLeft {
    background-color:#E8E8E8;
    width:195px;
}

.setup .outer td.oLeft {
  width:205px;
}
.outer .fullSpan {
    padding:0px 0px 10px 14px;
    background-color:#FFFFFF;
}
.outer .fullSpan .spacer{
    width:678px;
}

/* END Layout Table - outer */
/*---------------------------------------------- */
/* BEGIN Page Header */
.bPageHeader, .bPageHeader td.left{
    background-image: url(/static/image/bgTop.gif);
    background-position: left top;
    background-repeat: repeat-x;
}
.bPageHeader .phHeader {
    background-image:  url(/static/image/bgTopNav.gif);
    background-repeat: no-repeat;
    background-position: right top;
}

.bPageHeader .phHeader td{
    vertical-align:top;
}

.bPageHeader .previewIndicator {
    float: left;
    height: 100%;
    padding: 20px 0 0 2em;
    font-weight: bold;
    color: #900;
}

.bPageHeader .phHeader td.right {
    width: 100%;
    text-align: right;
    white-space: nowrap;
}

.bPageHeader .phHeader .buildMsg,
.bPageHeader .phHeader .preRelease  {
    font-weight: bold;
    color: #F00;
    background-color: #FFD;
    padding: 2px 4px;
    border: 1px solid #CCC;
    position: absolute;
    top: 2em;
    left: 2px;
}

.bPageHeader .phHeader .preRelease a {
    font-weight: normal;
    font-size: 93%;
    margin-left: 3px;
}

.bPageHeader .phHeader .right .spacer{
    width:533px;
}
.bPageHeader .phHeader .left .spacer, .bPageHeader .phHeader td.left {
    width:230px;
}
/* END Page Header */

/*BEGIN Setup */

.mTreeSelection{
    background-color:#E8E8E8;
    padding: 0.80em;
    font-size: 109%;
    text-align: left;
}

.mTreeSelection .helpTreeHeading{
    font-weight:bold;
}

.mTreeSelection .treeLine {
    background-color:#333;
    height:1px;
    margin-top: 0.33em;
    margin-bottom: 0.69em;
    font-size:0px

}

.mTreeSelection h2 {
    display:block;
    margin-top:15px;
    font-weight:bold;
    padding:0.33em 0.33em 0.33em 0.00em;
    border-bottom: 2px solid #ccc;
}

.helpTree {
    font-size: 88%;
}

.helpTree .mTreeSelection .setupLeaf,
.helpTree .mTreeSelection .setupHighlightLeaf{
    padding-bottom:2px;

}
.mTreeSelection .setupHighlightLeaf {
    background-color:#fff;
    margin-left:1.27em;
}
.mTreeSelection .setupHighlightLeaf a {
    text-decoration:none;
}


.mTreeSelection .setupLeaf{
    margin-left:1.27em;
}

.mTreeSelection  a:hover  {
   text-decoration: underline;
}

.mTreeSelection a.setupHighlightFolder{
    text-decoration:none;
    background-color:#fff;
}


.setupFolder {
    text-decoration: none;
    line-height: 1.5em;

}
.childContainer{
        margin-left: 1.00em;
}

.setupLeaf a {
    text-decoration: none;
    line-height: 1.5em
}

.setupSection {
   font-weight:bold;
   text-decoration: none;
   padding:0.33em;
}

.setupLink {
   font-weight:bold;
   text-decoration: underline;
   padding:0.33em;
}

.setupImage {
    padding:0.23em 0.33em 0.23em 0.33em;
    cursor:pointer;
}

/* Text in headers of Get Info boxes in Setup should be bold white,
   but DON'T USE IT! */
.bodyBoldWhite {
    color: #FFF;
    font-weight: bold;
}


/* END Setup */
/* --------------------------------------------- */
/* BEGIN Page Footer */

.bPageFooter {
    padding:10px 0px 20px 0px;
    border-top:1px solid #E8E8E8;
    text-align:center;
    line-height:1.8em;
}

.bPageFooter .footer, .bPageFooter .footer a{
    color:#333;
}
.bPageFooter .spacer {
    width:935px;
}

/* END Page Footer */
/* --------------------------------------------- */
/* BEGIN Styles for create new */

#newEntityList{
    display: none;
}

#newEntityTarget{
    display: block;
    height: 20px;
}
/* END Styles for create new */
/* --------------------------------------------- */
/* BEGIN Common page Elements */

/* Help buttons */
.help td {
    vertical-align:middle;
}
.help a {
    color:#333;
}

/* LookupInputElement */
.lookupInput {
    display: inline;
    white-space: nowrap;
    vertical-align: middle;
}
.lookupInput img {
    margin-right: .25em;
    background-repeat: no-repeat;
}

/* ColorInputElement */
.colorInputElement .sample {
    border: 1px solid #A5ACB2;
    margin: 0 5px 0 1px;
}

/* DuelingListBoxElement */
.duelingListBox table.layout td{
    vertical-align: middle;
    text-align: center;
}

.duelingListBox .selectTitle {
    padding: .5em 0 .5em 0;
    font-weight: bold;
}

.duelingListBox .text {
    padding: .1em 0 .1em 0;
}

/* Alert Box - BEGIN */
.alertBox {
    margin:10px 0px 20px 0px;
    padding:0px 15px 0px 13px;
    background-repeat: no-repeat;
    background-position: left top;
    background-image:  url("/static/image/bgmMessage.gif");
}

.alertBox .content {
    padding:5px 10px;
    background-color:#FFC;
    font-size: 109%;
}
/* Alert Box - END */

/* Date Picker */
.dateInput {
    white-space: nowrap;
}
.datePicker  {
    padding:0em 0.33em 0em 0.33em;
/*    vertical-align:bottom; - removed by polcari for the new Event page*/
}

/* HTML Input Element */
.htmlInput .controls {
    padding: 5px;
    border: 1px solid #000;
    background-color: #CCC;
}

.htmlInput .htmlEditor {
    border: 1px solid #000;
}

/* Mini-tabs */
.miniTab {
    padding: 6px 0 0 10px;
    font-family: 'Verdana', 'Geneva', sans-serif;
}

.miniTab ul {
    list-style-type: none;
    padding: 0.235em 0;
    margin: 0;
}


.miniTab .links {
    text-align: right;
    margin-right: 5px;
    float: right;
    color: #FFF;
    font-size: 91%;
}

.miniTab .links a {
    color: #FFF;
    font-size: 91%;
}

/*Needs to be more specific than the palette*/
.miniTab ul.miniTabList li {
    display: inline;
    border-style: solid;
    border-width: 1px 1px 2px 1px;
    /*border-color-bottom is from the palette*/
    border-top-color: black;
    border-left-color: black;
    border-right-color: black;
    padding: 4px 8px 1px 8px;
    margin-left: 0;
    margin-right: 5px;
    background-image: url(/static/image/tab/miniTab_off.gif);
    background-repeat: repeat-x;
}

.miniTab ul li a {
    text-decoration: none;
}

.miniTab ul li a:hover {
    text-decoration: underline;
}

.miniTab ul li.currentTab {
    padding-bottom: 3px;
    border-bottom-style: none;
    background-image: url(/static/image/tab/miniTab_on.gif);
    background-repeat: repeat-x;
    font-weight: bold;
}

.bMiniTab .bPageBlock {
    border-top-style: none;
}

.bMiniTab .bPageBlock .pbHeader{
    padding-top: 4px;
}

.bMiniTab .bPageBlock .pbHeader .pbButton {
    text-align: center;
}

/* AFAIK just used in Adv. Forecast edit minitabs */
.bMiniTabFilter {
    margin-top: 4px;
}

/* for blocks that contain stuff other than just a single bPageBlock */
.bMiniTabBlock {
    padding-top: 4px;
}

.bWizardBlock .miniTabOn {
    background-color: #FFF;
    width: 100%;
}

/* Show Me More */
.pShowMore{
   padding:9px 0 2px 5px;
   text-align: left;
}

.bDescription {
    padding: 0.8em 0 0.8em 0;
    font-size: 109%;
    text-align:left;
}

.bDescriptionUi {
    padding: 0.1em 0 0.8em 0;
    font-size: 109%;
    text-align:left;
}

 /* Added for opportunities summary element - but named very abstractly, so maybe good for future use. */
.opportunitySummary {
    width: 100%;
}
.opportunitySummary th {
    font-weight: bold;
    width: 30%;
}

.opportunitySummary .btn {
    margin: 0;
}

/* Prev/next buttons.  Used by ListElement, Calendar */
.bNext {
    margin:0px 0px 4px 18px;
    margin-right:15px;
}
.bNext .rolodex {
    padding-top: 15px;
    margin-right: 0.5em;
    text-align:left;
    font-size: 91%;
    float: left;
    white-space: nowrap;
}
.bNext .rolodex a {
    padding:0px 2px 0px 2px;
}
.bNext .rolodex a:link,
.bNext .rolodex a:visited,
.bNext .rolodex a:active {
    text-decoration:none;
}
.bNext .rolodex a:hover {
    text-decoration:underline;
}
.bNext .next {
    padding-top: 5px;
    text-align:right;
    font-size: 91%;
    float: right;
    white-space: nowrap;
}

.bNext .current {
    font-weight:bold;
}

.bNext .recycle {
    color:#336600;
    font-weight:bold;
}

.bNext .withFilter {
    height: 1%;
}

.bNext .withFilter .filter {
    float: left;
}

.bNext .rolodex {
    padding-top: 0px;
    margin-right: 0em;
    text-align:center;
    float: none;
}


/* FilterElements */
.bFilter {
    margin:0 0 15px 18px;
}

.bSubBlock .bFilter {
    margin-left: 0;
    margin-bottom: 0;
}

.bFilter .btn {
    vertical-align: middle;
    margin-right: .69em;
}
.bFilter .view {
    padding-right:15px;
}
.bFilter .fBody span {
    vertical-align:middle;
}
.bFilter .fBody .leftPad ,
.bFilter .fDescription  {
    margin-left: 10px;
}

.bFilter input ,
.bFilter select {
    vertical-align: middle;
    margin: 2px auto;
}

.bFilter select {
    font-size: 91%;
}

.bFilter .fHeader,
.bFilter h2 {
    text-align:left;
    font-weight:bold;
    padding-right: .69em;
}

.bFilterSearch .fHeader,
.bFilterSearch .fDescription {
    display:inline;
    margin-left:0;
}

.bFilter .fFooter {
    padding-left:8px;
    padding-top:2px;
    text-align:left;
    font-size: 91%;
}
.bFilter th {
    text-align:left;
    font-size: 91%;
    font-weight:normal;
    padding-right:10px;
    padding-top:8px;
}
.bFilter td {
    text-align:left;
    padding-right:10px;
}
.bFilter .btnRow {
    padding-top:8px;
}

.bFilterView .bFilter .fBody {
    vertical-align:middle;
}

.bFilterSearch .bFilter .messages,
.bFilterSearch .bFilter .view {
    float: left;
    margin-bottom:10px;
}

.bFilterSearch .bFilter .fBody {
    vertical-align:top;
}

.bFilterSearch .bFilter .fBody input.btn {
    vertical-align:top;
    margin-top:2px;
}

.bFilterSearch .bFilter .messages {
    width:50%;
}

.filterOverview {
    padding-bottom: 15px;
}

.filterOverview .bFilter {
    margin: 0px 0px 0px 0px;
}

.home div.recurrenceHeader {
    padding: 8px 0 8px 5px;
    border-right-style: solid;
    border-right-width: 2px;
    background-color: #F3F3EC;
}

/* Search Elements */
.bOverviewSearch .messages {
    width: 50%;
}
.bOverviewSearch .messages,
.bOverviewSearch .view {
    float: left;
}
.bOverviewSearch .view {
    padding-right:15px;
}
.bOverviewSearch .pbSearch {
    margin-top: 5px;
}
.bOverviewSearch {
    margin: 0 0 18px 15px;
}

/* Mouseover info element */
.mouseOverInfoOuter {
    position: relative;
}

.mouseOverInfo{
    position: absolute;
    display: none;
    left: 22px;
    top: 20px;
    width: 20em;
    background-color: #FEFDB9;
    padding:  2px;
    border: 1px solid black;
    z-index: 1;
    /*Mozilla:*/
    opacity: 0;
}

.whatIsThisElement {
  margin-left: 0.5em;
  vertical-align: bottom;
}


/* END Common Page Elements */
/* --------------------------------------------- */
/* BEGIN buttons */
.btn, .button, .formulaButton {
    font-family: 'Verdana', 'Geneva', sans-serif;
    background-image:  url("/static/image/bgButton.gif");
    background-repeat: repeat-x;
    background-position: left top;
    border-right:1px solid #5C5D61;
    border-bottom:1px solid #5C5D61;
    border-top:none;
    border-left:none;
    font-size: 80%;
    color:#FFFFFF;
    padding:1px 3px 1px 3px;
    cursor:pointer;
    font-weight:bold;
    display:inline;
}
.btnGo {
    font-family: 'Verdana', 'Geneva', sans-serif;
    background-image:  url("/static/image/bgButton.gif");
    background-repeat: repeat-x;
    background-position: left top;
    border-right:1px solid #5C5D61;
    border-bottom:1px solid #5C5D61;
    border-top:none;
    border-left:none;
    font-size: 80%;
    color:#FFFFFF;
    padding:0px 3px 1px 3px;
    cursor:pointer;
    font-weight:bold;
}
.btnImportant {
    font-family: 'Verdana', 'Geneva', sans-serif;
    background-image:  url("/static/image/bgButtonImportant.gif");
    background-repeat: repeat-x;
    background-position: left top;
    border-right:1px solid #5C5D61;
    border-bottom:1px solid #5C5D61;
    border-top:none;
    border-left:none;
    font-size: 80%;
    color:#FFFFFF;
    padding:1px 3px 1px 3px;
    cursor:pointer;
    font-weight:bold;
}
.upgradeNow, .subscribeNow, .btnSharing {
    font-family: 'Verdana', 'Geneva', sans-serif;
    background-image:  url("/static/image/bgButtonSharing.gif");
    background-repeat: repeat-x;
    background-position: left top;
    border-right:1px solid #5C5D61;
    border-bottom:1px solid #5C5D61;
    border-top:none;
    border-left:none;
    color:#FFFFFF;
    padding:1px 3px 1px 3px;
    cursor:pointer;
    font-weight:bold;
}
.btnSharing{
    font-size: 80%;
}
.upgradeNow, .subscribeNow {
    font-size: 100%;
}
.btnDisabled {
    font-family: 'Verdana', 'Geneva', sans-serif;
    background-image:  url("/static/image/bgButtonDisabled.gif");
    background-repeat: repeat-x;
    background-position: left top;
    border-right:1px solid #999999;
    border-bottom:1px solid #999999;
    border-top:1px solid #CCCCCC;
    border-left:1px solid #CCCCCC;
    font-size: 80%;
    color:#C1C1C1;
    padding:0 3px 1px 3px;
    cursor:default;
    font-weight:bold;
}
.btnHelp {
    margin-right:5px;
}
/* Same as .btn, but with extra margin-left */
.btnCancel {
    font-family: 'Verdana', 'Geneva', sans-serif;
    background-image:  url("/static/image/bgButton.gif");
    background-repeat: repeat-x;
    background-position: left top;
    border-right:1px solid #5C5D61;
    border-bottom:1px solid #5C5D61;
    border-top:none;
    border-left:none;
    font-size: 80%;
    color:#FFFFFF;
    padding:1px 3px 1px 3px;
    cursor:pointer;
    font-weight:bold;
    display:inline;
    margin-left: 2em;
}

.btnGo, .btnImportant, .btnSharing, .btnDisabled, .btn,
.bEditBlock .btnGo, .bEditBlock .btnImportant, .bEditBlock .btnSharing, .bEditBlock .btnDisabled, .bEditBlock .btn {
    margin: 0 2px;
}
/* END buttons */
/* --------------------------------------------- */
/* BEGIN Page Title */
.bPageTitle {
    margin-bottom:15px;
}

.bPageTitle .ptBody {
    padding-top: 5px;
    width:100%;
    overflow: hidden;
}

.bPageTitle .ptBreadcrumb {
    font-family: 'Verdana', 'Geneva', sans-serif;
    font-size: 91.3%;
    color: #333;
    margin-bottom: -15px;
    height:15px;
    vertical-align:middle;
}

.bPageTitle h1, .bPageTitle h2{
    color:#FFF;
    display: block;
}

/* used in places where the h1 is too high (because the h2 is empty).  */
h1.noSecondHeader,
.introPage h1 {
    margin: 10px 0 15px;
}

.bPageTitle .ptHeader a {
    color:#fff;
    text-decoration:underline;
}

.bPageTitle .ptBody .content {
    color:#fff;
    display: inline; /* IE double-margin float fix */
    float: left;
    width: 40.0%;
    vertical-align: middle;
    position: relative;
    padding-left: 42px;
}

.pageTitleIcon {
    position: absolute;
    left: 5px;
    width: 32px;
}

/* Pages without pageTitleIcons */
.sysAdmin .bPageTitle .ptBody .content,
.home.homepage .bPageTitle .ptBody .content,
.home.allTab .bPageTitle .ptBody .content {
    padding-left: 10px;
}

.bPageTitle .ptBody .links {
    padding: 10px 5px 10px 0px;
    float: right;
    text-align: right;
    width: 40.0%;
    vertical-align:middle;
    color: #fff;
    font-size: 91%;
}

.bPageTitle .ptBody .links .configLinks {
    text-decoration:underline;
}

.bPageTitle .ptBody .links .helpLink,
.bWizardBlock .helpLink {
    text-decoration:underline;
    padding-right: 5px;
}

.bPageTitle .ptBody .links  .helpImage,
.bWizardBlock .helpImage {
    vertical-align:bottom;
}

.bPageTitle .ptBody .links  a,
.bWizardBlock .pbLinks a {
    text-decoration:none;
    color: #fff;
}
.bWizardBlock .pbWizardHelpLink a {
    text-decoration: none;
}

.bPageTitle .content .blank {
    font-size: 0px;
    clear:both;
}

.bPageTitle .ptBody .content .icon{
    position: absolute;
    margin-top: -5px;
}
.bPageTitle .ptSubheader .content {
    padding-left:20px;
    padding-bottom:2px;
    padding-top:2px;
    height:40px;
    color:#fff;
}
.bPageTitle .ptBody .pageType {
    font-size: 91%;
    color:#fff;
}
.bPageTitle .ptBody .pageDescription {
    font-size: 109%;
    color:#fff;
    font-weight:bold;
}

.bPageTitle .ptSubheader .pageType {
    font-size: 91%;
    color:#fff;
}
.bPageTitle .ptSubheader .pageDescription {
    font-size: 109%;
    color:#fff;
    font-weight:bold;
}

.bPageTitleButton {
  float: right;
}



.oRight .bPageTitle .ptBody a,
.oRight .bPageTitle .ptSubheader a,
.outerNoSidebar .bPageTitle a .helpLink {
    color:#FFF;
}
/* begin record types */
.oRight .recordTypesHeading{
    display: block;
     font-weight: bold;
     padding: 1em 0 1em 0;
}

.oRight .infoTable {
     background-color:#666666;
     text-align: left;
}

.oRight .infoTable .headerRow th{
     white-space: nowrap;
     background-color:#CCC;
     padding:3px;
     margin:1px;
     font-weight: bold;
     border: none;
}

.oRight .infoTable td,
.oRight .infoTable th{
     white-space: nowrap;
     background-color:#FFF;
     padding:4px;
     margin:1px;
     border: solid #DDD;
     border-width: 0 1px 1px 0;
 }

.oRight .infoTable th{
     border-left-width: 1px;
}
/* END record types */


/* working defaults, so you can at least read the text */
.bPageTitle .ptHeader{
    background-color: black;
}

/* this should be a not-very specific case so that it doesn't override custom tab pages */
.ptBody {
    background-color: #666;
}

/* END Page Title */
/* --------------------------------------------- */
/* BEGIN Overview Page elements */
/* Added to set up two-column divs for Tools displayed at bottom of each tab */
.toolsContent {
    width: 100%;
}
/* Overview Page Headers */
.overviewHeaderDescription {
    float: left;
    padding: 5px 15px 15px 5px;
}
.overviewHeaderContent {
    float: right;
    padding: 5px 15px 15px 5px;
}
.overviewHeaderBlank {
    clear: both;
    font-size: 0px;
}

/* bSubBlock */

.bSubBlock{
    margin-bottom:15px;
    border-top:0px;
    border-right:0px;
    border-bottom:2px solid #000;
    border-left:0px;
}

.bSubBlock .lbHeader {
    color:#fff;
    padding:2px 13px 2px 13px;
    font-weight:bold;
    font-family: 'Arial', 'Helvetica', sans-serif;
    display:block;
    float: none;
}
.bSubBlock .lbHeader .spacer {
    clear: both;
    font-size: 0px;
}

.bSubBlock .lbSubheader {
    padding:10px 0px 1px 13px;
    font-weight:bold;
}
.bSubBlock .lbBodyDescription {
    background-color:#F3F3EC;
    padding:10px 23px 5px 26px;
}
.bSubBlock .lbBody {
    background-color:#F3F3EC;
    padding:10px 23px 10px 26px;
    line-height:1.6em;
}
.bSubBlock .lbBody td , .bSubBlock .lbBody th {
    padding:0px 5px 1px 0px;
    vertical-align:middle;
    text-align:left;
}
.bSubBlock .lbBody span{
    vertical-align:middle;
}
.bSubBlock .lbBody UL {
    margin: 0px;
    padding: 0px;
    list-style-type: none;
}
.bSubBlock .lbBody LI, .bSubBlock .lbBody .bSummary {
    line-height: 2em;
    padding: 0px;
    margin: 0px;
}
 .bSubBlock .lbBody .bSummary td,
  .bSubBlock .lbBody .bSummary th  {
    padding:.10em .69em .10em .00em;
    vertical-align:middle;

 }

.bSubBlock .lbBody .mainLink {
    font-weight: bold;
}

.bReport .bSubBlock .lbHeader, .bTool .bSubBlock .lbHeader {
    background-color:#DF8810;
}
.bReport .bSubBlock, .bTool .bSubBlock{
    border-right-color:#DF8810;
    border-bottom-color:#DF8810;
}

.bSubBlock .textDate{
    width:80px;
    margin:1px;
    margin-right:1px;
    font-size: 91%;
}
.bSubBlockselect {
    font-size: 91%;
}
.bSubBlock .lbHeader .primaryInfo {
    float: left;
    width: 50%;
}
.bSubBlock .lbHeader .secondaryInfo {
    text-align: right;
    float: left;
    width: 50%;
}
/* END Overview Page Elements */
/* --------------------------------------------- */
/* BEGIN Basic DetailElement */
.bPageBlock {
    border-top:7px solid #222;
    margin-bottom:17px;
    background-color:#222;
    background-image: url(/static/image/bgPageBlockLeft.gif);
    background-repeat: no-repeat;
    background-position: left bottom;
    padding-bottom:9px;
    clear: both;
}

.bPageBlock .pbError{
   font-weight: bold;
   color: #C00;
   text-align: center;
}

.bPageBlock .pbHeader {
    color:#222;
    border-bottom:1px solid #F3F3EC;
    margin:0px 2px 2px 0px;
    background-color:#FFF;
}
.bPageBlock .pbSubheader{
    background-color:#222;
    color:#FFF;
    font-weight:bold;
    font-size: 91%;
    padding:2px 2px 2px 5px;
    margin-top: 15px;
    overflow: hidden;
    margin-bottom: 2px;
}
.bPageBlock .pbSubheader.first {
    margin-top: 0;
}

.bPageBlock .pbSubheader .pbSubExtra {
    float: right;
    margin-right: 2em;
}

.bPageBlock .pbSubheader .pbSubExtra a{
    color: white;
}

.bPageBlock .pbSubbody {
    padding: 10px;
}

.bPageBlock .pbSubbody ul {
    padding: 0;
    margin: 0;
}

.bRelatedList .bPageBlock .pbButton .relatedInfo {
  padding-right:3.7em;
  vertical-align: bottom;
  white-space: normal;
}
.bRelatedList .bPageBlock .pbButton .relatedInfo .mouseOverInfoOuter{
  vertical-align: bottom;
}

/* added by polcari 9/27 in an effort simplify spacing & alignment issues (see new event page) */
.bEditBlock input,
.bEditBlock select,
.bEditBlock img  {
    vertical-align: middle;
    margin-right: .25em;
}
.bEditBlock input.radio {
    vertical-align: baseline;
}

.requiredLegend {
    padding: 0 2px;
    background-color: #FFF;
    font-weight: normal;
    color: #000;
}

/*For EditHeaderElement*/
.headerTitle .requiredLegend {
    float: right;
}

.requiredExampleOuter {
    margin: 0 0.2em 0 0.3em;
    padding: 1px 0;
}

.requiredExample {
    border-left: 3px solid #c00;
    font-size: 80%;
    vertical-align: 1px;
    width: 100%;
}

.bPageBlock .pbHeader .pbIcon{
    width: 44px;
}

.bPageBlock .pbTitle{
  vertical-align:middle;
  color:#222;
  font-size: 91%;
  width: 30%;
  margin:0px;
}

/*this enforces a minimum width for the pbTitle cell */
.bPageBlock .pbTitle img.minWidth {
  height:1px;
  width:190px;
  margin: 0 0 -1px 0;
  padding: 0;
  border: 0;
  visibility:hidden;
  /* vertical-align:auto; */
}

.bPageBlock .pbHeader table,
.bPageBlock .pbBottomButtons table {
   width: 100%;
}

.bPageBlock .pbButton {
    padding: 1px 0px;
    white-space: nowrap;
    vertical-align: middle;
}
.bPageBlock .pbButtonb{
    padding: 1px 0px;
    white-space: nowrap;
}
.bPageBlock .pbDescription {
    text-align:right;
}

.bPageBlock .pbHeader .pbLinks {
    font-size: 91%;
    text-align:right;
    padding:1px 5px 1px 1px;
    vertical-align:middle;
}
.bPageBlock .pbCopy {
    text-align:left;
    font-size: 91%;
    padding:3px 0px 5px 0px;
}
.bPageBlock .pbDescription span {
    font-size: 91%;
    padding:3px 0px 5px 0px;
}

.bPageBlock .pbHeader  select {
    font-size: 91%;
    margin:1px 7px 0px 0px;
}

.customLinks {
    width: 100%;
}

.customLinks td {
    width:33%;
    padding:2px;
}

.customLinks td .bullet {
    display:none;
}

/* h2 used for detail element headers */
/* h3 used for related list headers */
.pbHeader .pbTitle h2 ,
.pbHeader .pbTitle h3 {
    margin: 0 0 0 4px;
    padding: 0;
    display:block;
    color: #333;
}

.bPageBlock .pbHeader .pbTitle .twisty {
    width:16px;
    height:10px;
    background-color:#222222;
    border-bottom:none;
}
.bPageBlock .pbHeader .pbHelp .help{
    font-size: 91%;
    vertical-align:middle;
    width:auto;
}
.bPageBlock .pbHeader .pbHelp .help .imgCol{
    width: 22px;
}
.bPageBlock .pbHeader .pbHelp .help a.linkCol{
/*  white-space: nowrap; */
    padding-right: 0.5em;
    vertical-align:bottom;
    text-decoration:none;
}

.bPageBlock .pbHeader .pbHelp .help .linkCol .linkSpan{
    font-size: 100%;
/*  white-space: nowrap; */
    vertical-align:bottom;
    margin-right:0.40em;
    text-decoration:underline;
}

.bPageBlock .pbHeader .pbHelp .help .linkCol .helpImage{
    vertical-align:bottom;
}

.bPageBlock .pbHeader .pbHelp {
    text-align:right;
    padding:1px 5px 1px 1px;
    vertical-align:middle;
}

.bPageBlock .pbHeader .pbCustomize {
    font-size: 91%;
    padding:3px 2px 2px 4px;
    vertical-align:middle;
    text-align:right;
}
.bPageBlock .pbBody {
    margin-right:2px;
    padding:6px 20px 0 20px;
    background-color:#F3F3EC;
}
.bPageBlock .pbFooter,
.bWizardBlock .pbFooter {
    background-color:#222;
    height:9px;
    width:9px;
    display:block;
    float:right;
    background-image:  url(/static/image/bgPageBlockRight.gif);
    background-repeat: repeat-x;
    background-position: right bottom;
}

.bPageBlock .pbBottomButtons {
    background-color: #F3F3EC;
    margin: 1px 2px 0 0;
}

.bPageBlock .noRecords {
    font-weight:bold;
    color:#333;
    padding-bottom: 15px;
}

/* Detail List - BEGIN */
.bPageBlock .detailList {
    width:100%;

}

.bPageBlock .detailList th,
.bPageBlock .detailList td {
    vertical-align:top;
    color:#333;
}

/* RPC: Made less specific so these classes can be used in FilterEditPage */
.bPageBlock .labelCol{
    padding:2px 10px 2px 2px;
    text-align:right;
    font-size: 91%;
    font-weight: bold;
}
.bPageBlock .detailList .labelCol {
    width: 18%;
}
/* RPC: Made less specific so these classes can be used in FilterEditPage */
.bPageBlock .dataCol {
    padding:2px 2px 2px 10px;
    text-align:left;
}
.bPageBlock .detailList .dataCol {
    width:32%;
}

.bPageBlock .detailList .data2Col {
    padding: 2px 2px 2px 10px;
    text-align: left;
    width: 82%;
}

.bPageBlock .buttons {
    text-align: center;
    padding: 3px 20px;
}

/* Note: this overrides the above selector on edit pages,
   so it must come afterwards
*/
.bEditBlock .detailList .dataCol,
.bEditBlock .detailList .data2Col {
    padding: 0 2px 0 10px;
}

.bPageBlock .detailList .col02{
    border-right: 20px solid #F3F3EC
}

.bPageBlock .detailList tr td, .bPageBlock .detailList tr th {
    border-bottom:1px solid #E3DEB8;
}
.bPageBlock .detailList th.last,
.bPageBlock .detailList td.last,
.bPageBlock.bLayoutBlock .detailList tr td,
.bPageBlock.bLayoutBlock .detailList tr th {
    border-bottom:none;
}
.bPageBlock .detailList table td,
.bPageBlock .detailList table th {
    border-bottom-style: none;
}

.bPageBlock .detailList .bRelatedList .pbTitle {
  vertical-align: middle;
}

.bPageBlock .detailList .error {
    border: 2px solid #C00;
}

.bPageBlock .detailList .empty {
    border-bottom: none;
}

.bPageBlock .detailList .errorMsg {
    padding-left: 3px;
}

/* RPC: detailList commented out so others can use requiredInput */
.bPageBlock .requiredInput {
    position: relative;
    height: 100%;
}

.bPageBlock .requiredInput .requiredBlock{
    background-color: #C00;
    position: absolute;
    left: -4px;
    width: 3px;
    top: 1px;
    bottom: 1px;
}

.bPageBlock .doubleCol{
    width: 100%;
}

.bPageBlock .doubleCol th{
    width: 14.5%;
}

.bPageBlock .requiredMark {
    color: #F3F3EC;
}

.pbBody .bPageBlock .pbHeader,
.pbBody .bPageBlock .pbTitle,
.pbBody .bPageBlock .pbLinks ,
.pbBody .bPageBlock .pbLinks a {
    color: #FFF;
}
/* Detail List - END */

/* END Basic DetailElement */
/* ------------------------------------------ */
/* BEGIN Related List*/
.bPageBlock .pbHeader .listHeader {
    padding: 3px 2px 4px 2px;
    text-align: center;
    vertical-align: middle;
}

.bPageBlock .pbHeader .listHeader span {
    font-size: 100%;
    padding-right: 0.91em;
}

.bPageBlock .alignCenter {
    text-align:center;
}
.bPageBlock .list {
    width:100%;
}

/* polcari: I dropped the .bPageBlock to make this less specific in in hopes of fixing some problems w/ font color on the custom-tab picker page.
   Let me know if it causes problems & i'll devise a better workaround */
.list td,
.list th,
body.oldForecast .list .last td,
body.oldForecast .list .last th {
    padding:4px 2px 4px 5px;
    color:#333;
    border-bottom:1px solid #E3DEB8;
}

.bPageBlock .list .last td,
.bPageBlock .list .last th,
body.oldForecast .list .totalRow td,
body.oldForecast .list .totalRow th {
    border-bottom-width: 0;
}


.bPageBlock td.actionColumn .actionLink {
    color: #333;
    font-weight:bold;
    vertical-align: top;
}

.list th.actionColumn * {
    vertical-align: top;
}

/*ie behaves slightly differently - check common_ie for details */
.list .actionColumn input {
    margin-top:2px;
    vertical-align: top;
    margin-bottom: 1px;
}

/* Related List text formatting */
.list .headerRow th {
    border-bottom: 2px solid #CCC;
    white-space: nowrap;
}

.list .noRows, .bRelatedList .list .noRowsHeader {
    padding-bottom: 0;
    border-bottom: none;
    font-weight: normal;
    font-size: 91%;
}

/*  Removed by polcari 9/29 - this causes empty list-view headers to become too big
.list .noRowsHeader a {
    font-weight: bold;
    font-size: 110%;
}
*/
/* this is causing RL's to display disjointedly
.list th {
    text-align:left;
    padding-top:0px;
}
*/
.list tr.even th,
.list tr.odd th {
    font-weight: normal;
    white-space: normal;
}

.list tr.even th,
.list tr.odd th ,
.list tr.even td,
.list tr.odd td {
    vertical-align: top;
}

.list .booleanColumn {
    text-align: center;
}

.list .numericalColumn,
.list .numericalColumn,
.list .CurrencyElement {
    text-align:right;
}

.bPageBlock .pbInnerFooter table {
    width: 100%;
}

.list .CurrencyElement, .list .PhoneNumberElement, .list .DateElement {
    white-space: nowrap;
}
/*polcari: I cut out ".bPageBlock .list" to make this less specific and not conflict tables inside a row (custom tab picker).
If this causes problems, let me know there is another easy solution i can pursue */
.highlight td,
.highlight th {
    background-color:#FFF;
}

.listAction {
    font-size: 91%;
}

.actionColumn {
    white-space:nowrap;
}

/* End Related List text formatting */

.bPageBlock .list .divide td {
    border-bottom:none;
    padding-bottom:15px;
}

.bPageBlock .reportHeader {
    padding-bottom:10px;
}
.bPageBlock .reportHeader .booleanFilter,
.bPageBlock .reportHeader .itemNumber,
.bPageBlock .reportHeader .filterField,
.bPageBlock .reportHeader .filterValue,
.bPageBlock .reportHeader .filterAction {
    font-weight: bold;
}
.bPageBlock .reportOutput td, .bPageBlock .reportOutput th {
    vertical-align:top;
    padding:3px 2px 3px 5px;
    color:#333;
    white-space: normal;
}
.bPageBlock .reportOutput td.nowrapCell,
.bPageBlock .reportOutput th.nowrapCell {
    white-space: nowrap;
}
.bPageBlock .reportOutput {
    padding-bottom:15px;
    width:100%;
}
.bPageBlock .reportOutput .colSpan td {
    vertical-align:middle;
}
.bPageBlock .reportOutput th {
    border-top:none;
    text-align:left;
}
.bPageBlock .reportOutput .odd {
    background-color: #FFF;
}
.bPageBlock .reportOutput .even {
    background-color: #F3F3EC;
}
.bPageBlock .componentTable .col01, .bPageBlock .componentTable .col02 {
    padding-right:15px;
}

.categoryTitle {
    margin-bottom:10px;
    font-weight:bold;
}
.bPageBlock .categoryList td, .bPageBlock .categoryList th {
    text-align:left;
    padding:3px 2px 3px 5px;
    color:#333;
}
.bPageBlock .categoryList {
    padding-bottom:15px;
}
.bPageBlock .formTable h3 {
    padding:15px 0px 10px 0px;
    display:block;
    font-weight:bold;
}
.bPageBlock .formTable td {
    padding-left:0.89em;
}
.bPageBlock .formTable .bHeader {
    text-indent:-0.63em;
    font-weight:bold;
}
.bPageBlock .formTable .bBody {
    font-size: 91%;
}
.bPageBlock .formTable .asterisk{
    color:#c00;
}
.bPageBlock .textBox {
    width:160px;
    margin:1px;
    margin-right:7px;
}

.bPageBlock .cbCol {
    vertical-align:middle;
}
.bPageBlock .cbCol input {
    margin:-2px 0px -2px 0px;
}

/* we don't want to see the rolodex & prev/next buttons in most places */
.listElementBottomNav {
    display:none;
}

/* ok, it's nice to see the rolodex & prev/next buttons here */

.recycleBin .listElementBottomNav,
.listPage .listElementBottomNav,
.product .listElementBottomNav {
    display: block;
}

.listElementBottomNav .bNext .clear {
    clear:none;
    display:none;
}

/* END Related List */




/* begin document styles */

/* Center the New Document and New Email Template buttons and fix padding */
/* rchen - removing this because I don't think it's needed any more*/
/*.listDocument .bPageBlock .pbHeader {
    text-align: center;
    padding: 2px 0 2px 0;
}*/



/* End document Styles */


/* Begin dashboard */
.mComponent {
    padding-left:2px;
    margin-bottom:10px;
    margin-top:2px;
}
.mComponent .shadow {
  background-color: #D5D5D5;
}
.mComponent .cBody {
    background-color:#fff;
    text-align:center;
    background-image: url(../images/graphs/bgComponent.gif);
    background-repeat: repeat-x;
    background-position: left top;
}

.mComponent .cContent {
    background-color:#F3F3EC;
    width:100%;
    position: relative;
    left: -2px;
    top: -2px;
    border: none;
}

.mComponent .cContent .dashboardRowValue {
    float: right;
    padding: 3px;
    display: block;
}

.mComponent .cContent .dashboardRowLabel {
    padding: 3px;
    display: block;
}

/* ensure that tables and error msgs don't have a dark background */

.dashPreview .cContent table,
.cContent table.list,
.cContent span.errorMsg {
    background-color:#F3F3EC;
    position:relative;
    left: 2px;
    top: 2px;
}


.mComponent .cContent span.errorMsg {
    display:block;
}
.mComponent .cContent table td{
    padding: 0;
}
.mComponent .cContent table th {
    padding:3px;
    white-space: normal;
}

.mComponent .cContent .tableTitle {
    border: none;
    text-align: center;
}

.mComponent .cContent .tableTitle a {
    font-weight: bold;
}

.mComponent .headerRow .drilldownLink {
    text-decoration: none;
}

.mComponent .cContent .list {
    cursor: pointer;
}

.mComponent .cContent .list tr.last td {
  border-bottom-width:2px;
}

/* END dashboard */

/* BEGIN Intro Page elements */

.introBody {
    width:951px;
}

.introBody .introTitle{
    font-weight:bold;
}
.introBody .introForm {
    background-color: #E8E8E8;
    width: 225px;
    vertical-align:top;
    border-left:20px solid #fff;
}

.introBody .introFormBody {
    padding:1em;
    font-size:91%;
    text-align: center;
}
.introBody .introFormBody .formDescription {
    padding: 10px 0 20px 0;
    text-align: left;
}

.introBody .introForm .requiredMark {
    color:red;
    font-size:109%;
}

.introBody .introForm .inputLabel {
    padding-top:10px;
    font-weight:bold;
}

.introBody .introForm .formDescription{
    padding-top:10px;
    padding-bottom:15px;
}

.introBody .introForm .requiredDescription{
    padding-bottom:20px;
    text-align:right;
    font-weight:bold;

}

.introBody .formTitle {
    background-color: #999;
    padding:0.1em 1em 0.1em 1em;
    font-weight:bold;
    color:#fff;
}

.introBody .introDescription {
    background-color:#F3F3EC;
    padding:1.0em;
    background-repeat: no-repeat;
    background-position: left top;
    width:951px;
}

.introBody .introDescription .contentDescription {
    font-size:109%;
    width:70%;
    float:left;
    padding: 5px 0 20px 0;
}

.introBody .introDescription .demoDescription {
    font-size:109%;
    width:27.5%;
    float:right;
    padding-left:2.5%;

}

.introBody .introDescription .helpAndTraining{
        vertical-align:top;
        width:28%;
        float:right;
        padding-left:2%;
}

.introBody .introDescription .benefitsDescription{
        vertical-align:top;
        width:70%;
        float:left;
}

.introBody .introDescription .demoBox {
    background-color:#FFF;
    border:1px solid #000;
    margin:10px;
    width:170px;
}

.introBody .introDescription .demoBox .demoTitle {
    background-color:#000;
    color:#FFF;
    font-weight:bold;
    text-align:left;
}

.introBody .introDescription .demoBox .demoText {
    color: #333;
}

.introBody .introDescription .demoBox .arrow {
    color: #333;
    padding:0.4em;
}

.introBody .introDescription .demoBox .demoImage {
    background-color:#000;
    border-bottom:1px solid #000;
    width:71px;
}

.introBody  .introDescription .mMessage {
    background-color: #F3F3EC;
    font-size:91%;
}

.introBody  .introDescription .mMessage .content{
    padding-bottom:70px;
}

.introBody  .introDescription .continue {
    text-align:right;
    float:right;
    width:8%;

}

.introBody  .introDescription .buttons {
    width:98%;
    clear: both;
    overflow:hidden;

}

.introBody  .upperBorder {
    padding-top:1.31em;
}

.introBody  .lowerBorder {
    padding-bottom:2px;
}

 .introBody .screenShot {
     margin-top:25px;
     margin-left:auto;
     margin-right:auto;
     margin-bottom:25px;
     width:100%;
     vertical-align:bottom;
 }


.account .introBody .screenShot { background-image: url(/static/image/keys_new_accounts.gif);
        width:710px;
        height:175px; }
.campaign .introBody .screenShot { background-image: url(/static/image/keys_new_camp.gif);
        width:710px;
        height:175px; }
.case .introBody .screenShot { background-image: url(/static/image/keys_new_cases.gif);
        width:710px;
        height:175px; }
.contact .introBody .screenShot { background-image: url(/static/image/keys_new_contacts.gif);
        width:710px;
        height:175px; }
.contract .introBody .screenShot { background-image: url(/static/image/keys_new_contract.gif);
        width:710px;
        height:175px; }
.dashboard .introBody .screenShot { background-image: url(/static/image/keys_new_dashboards.gif);
        width:710px;
        height:175px; }
.document .introBody .screenShot { background-image: url(/static/image/keys_new_document.gif);
        width:710px;
        height:175px; }
.forecast .introBody .screenShot { background-image: url(/static/image/keys_new_forecasting.gif);
        width:710px;
        height:175px; }
.lead .introBody .screenShot { background-image: url(/static/image/keys_new_leads.gif);
        width:710px;
        height:175px; }
.opportunity .introBody .screenShot { background-image: url(/static/image/keys_new_opps.gif);
        width:710px;
        height:175px; }
.portal .introBody .screenShot { background-image: url(/static/image/keys_new_portals.gif);
        width:710px;
        height:175px; }
.product .introBody .screenShot { background-image: url(/static/image/keys_new_products.gif);
        width:710px;
        height:175px; }
.report .introBody .screenShot { background-image: url(/static/image/keys_new_reports.gif);
        width:710px;
        height:175px; }
.solution .introBody .screenShot { background-image: url(/static/image/keys_new_solutions.gif);
        width:710px;
        height:175px; }




.account .introBody .introDescription { background-image: url(/static/image/accountsSplashBg.gif); }
.campaign .introBody .introDescription {  background-image: url(/static/image/campaignsSplashBg.gif); }
.case .introBody .introDescription {  background-image: url(/static/image/casesSplashBg.gif); }
.contact .introBody .introDescription { background-image: url( /static/image/contactsSplashBg.gif); }
.contract .introBody .introDescription {background-image: url( /static/image/contractsSplashBg.gif); }
.dashboard .introBody .introDescription { background-image: url(/static/image/dashboardsSplashBg.gif); }
.document .introBody .introDescription { background-image: url(/static/image/documentsSplashBg.gif); }
.forecast .introBody .introDescription { background-image: url(/static/image/forecastsSplashBg.gif); }
.lead .introBody .introDescription { background-image: url(/static/image/leadsSplashBg.gif); }
.opportunity .introBody .introDescription {background-image: url( /static/image/opportunitiesSplashBg.gif); }
.portal .introBody .introDescription { background-image: url(/static/image/portalsSplashBg.gif); }
.product .introBody .introDescription {background-image: url( /static/image/productsSplashBg.gif); }
.report .introBody .introDescription { background-image: url(/static/image/reportsSplashBg.gif); }
.solution .introBody .introDescription { background-image: url(/static/image/solutionsSplashBg.gif); }


/* END Intro Page elements */
/* --------------------------------------- */
/* BEGIN EventPage */

.home div.recurrenceHeader {
    padding: 8px 0 8px 5px;
    border-right-style: solid;
    border-right-width: 2px;
    background-color: #F3F3EC;
}

/* END EventPage */
/* --------------------------------------- */
/* BEGIN Tree pages */
.bTitle {
    border-bottom: 1px solid #000;
    margin-bottom: 4px;
    padding-bottom: 6px;
}

.bTitle h2 {
    font-size: 109%;
}

.bTitle .viewSelect {
    float: right;
}
/* END Tree pages */
/* --------------------------------------- */
/* BEGIN single user calendar */

.bCalendar .taskList {
    width: 50%;
    padding-left: 10px;
}

.bCalendar .calendarBlock {
    width: 50%;
}

.bCalendar .bTopButtons {
    text-align: right;
    margin-bottom: 2px;
}

.bCalendar .calHeader {
    clear: both;
    padding-top: 5px;
    white-space: nowrap;
}

.bCalendar .calendarIconBar {
    text-align: right;
}

.bCalendar .bPageBlock .calendarIconBar * {
    float: none;
    display: inline;
}

.bCalendar .bPageBlock .pbTitle h3{
    margin: 3px 0 7px 0;
    font-weight: bold;
    width: auto;
    white-space: nowrap;
}

.bCalendar .bPageBlock .calendarView,
.bCalendar .bPageBlock .calendarWeekView {
    width: 100%;
    border-style:solid;
    border-width: 1px;
    background: none;
}

.bCalendar .calendarView td {
    padding: 1px 0 1px 2px;
    width: 90%;
}

.calendarBlock th {
    padding: 3px;
    font-weight: bold;
    text-align: right;
    border-right: 1px solid #D4D4D4;
    border-bottom: 1px solid #D4D4D4;
    background-color: #E7E7D8;
}
.bCalendar .taskList th {
    border-right: none;
}

.bCalendar .even td,
.bCalendar .odd td{
    border-bottom: 1px solid #E8E3C3;
}

.bCalendar .calendarWeekView th {
    text-align: left;
    border: none;
}

.bCalendar .calendarWeekView .newLink {
    text-align: right;
    background-color: #E7E7D8;
    padding-right: 2px;
}

.bCalendar .calendarWeekView .event {
    border-bottom: 1px solid #E8E3C3;
    padding: 2px 0;
}
.bCalendar .calendarWeekView .event.last {
    border-bottom: none;
}

.bCalendar .calendarMonthView {
    width: 100%;
    border: 1px solid;
}

.bCalendar .calendarMonthView .headerRow {
    background-color: #E7E7D8;
}

.bCalendar .calendarMonthView .headerRow th {
    font-weight: bold;
    width: 14%;
    padding: 3px;
    text-align: center;
    border-color: #FFF;
    border-width: 0 0 1px 1px;
    border-style: solid;
    border-bottom-color: #A7A7A7;
}

.bCalendar .calendarMonthView td {
    border: solid #A7A7A7;
    border-width: 0 1px 1px 0;
    width: 14%;
    padding: 0;
}

.bCalendar .calendarMonthView td.upperLeft {
    border-width: 0;
    border-bottom: 1px solid #A7A7A7;
    background-color: #E7E7D8;
    padding: 0;
}

.bCalendar .calendarMonthView .calInactive {
    background-color: #D4D4D4;
}

.bCalendar .calendarMonthView .calActive{
    background-color: #F3F3EC;
}
.bCalendar .calendarMonthView .calToday {
    background-color: #FFFFD4;
}

.bCalendar .calendarMonthView .date {
    background-color: #C3BBB7;
    border-bottom: 1px solid #A7A7A7;
    margin-bottom: 1px;
    padding: 1px 3px;
    font-size: 90%;
}

.bCalendar .calendarMonthView .calToday .date {
    background-color: #EEE;
    font-weight: bold;
}

.bCalendar .calendarMonthView td .event {
    display: block;
    font-weight: bold;
}
.bCalendar td .event {
    font-weight: bold;
    margin-right: 0.4em;
}

.bCalendar .calendarMonthView .date .newLink {
    float: right;
    font-weight: normal;
}

.bCalendar .calendarMonthView .weekLink {
    width: 18px;
    background-color: #C3BBB7;
    padding: 30px 5px;
    vertical-align: middle;
    text-align: center;
}

.print .bCalendar .calendarWeekView th {
    background-color: #F3F3EC;
}

/* END single user calendar */

/* --------------------------------------- */
/* BEGIN MultiuserCalendar */

.bMultiuserCalendar .bPageBlock {
    border-top-color: #506749;
}
.bMultiuserCalendar .bPageBlock .pbHeader .pbTitle,
.bMultiuserCalendar .bPageBlock .pbHeader .pbTitle h2{
    color:#506749;
}
.bMultiuserCalendar .bPageBlock .pbFooter,
.bMultiuserCalendar .bPageBlock,
.bMultiuserCalendar .bPageBlock .pbHeader .pbTitle .twisty {
    background-color:#506749;
}
.bMultiuserCalendar .bPageBlock .pbSubheader{
    background-color:#506749;
}
.bMultiuserCalendar  .pbButton, .bMultiuserCalendar  .pbDescription {
    vertical-align:middle;
}
.bMultiuserCalendar  .pbDescription {
    text-align:right;
}
.bMultiuserCalendar  .pbButton .iconBar {
    margin-top:0px;
    padding:1px 1px 1px 1px;
}
.bMultiuserCalendar  .pbButton .iconBar img {
    margin-right:4px;
    vertical-align:middle;
}
.bMultiuserCalendar  .pbButton .iconBar img.extra {
    margin-right:15px;
}
.bMultiuserCalendar  .pbButton .iconBar img.last {
    margin-right:24px;
}

.multiuserCalendar {
    border:1px #506749 solid;
}
.multiuserCalendar .calendarTable {
    /* todo: polcari can we scrap this? */
    /* IE 5.x 100% Table Work-Around Begin */
    width:90%;
    voice-family: "\"}\"";
    voice-family: inherit;
    width:100%;
    /* IE 5.5x 100% Table Work-Around End */
}
.multiuserCalendar .sunCol, .multiuserCalendar .monCol,
.multiuserCalendar .tueCol, .multiuserCalendar .wedCol,
.multiuserCalendar .thuCol, .multiuserCalendar .friCol,
.multiuserCalendar .satCol{
    width:11%;
    border-left:1px solid #999999;
}
.multiuserCalendar th.sunCol, .multiuserCalendar th.monCol,
.multiuserCalendar th.tueCol, .multiuserCalendar th.wedCol,
.multiuserCalendar th.thuCol, .multiuserCalendar th.friCol,
.multiuserCalendar th.satCol, .multiuserCalendar th.timeCol,
.multiuserCalendar tr.dateRow .nameCol {
    border-left:none;
}
.multiuserCalendar .nameCol,
.multiuserCalendar .typeCol {
    border-left:1px solid #E3DEB8;
}
.multiuserCalendar th.sunCol, .multiuserCalendar th.monCol,
.multiuserCalendar th.tueCol, .multiuserCalendar th.wedCol,
.multiuserCalendar th.thuCol, .multiuserCalendar th.friCol,
.multiuserCalendar th.satCol, .multiuserCalendar th.nameCol {
/*  background-image: url(../images/calendar/bgBorderMUCalendar.gif); */
    background-repeat: no-repeat;
    background-position: left bottom;
}

.multiuserCalendar .error .nameCol {
    background-color: #C00;
    color: #FFF;
}

.multiuserCalendar .lastLineOdd, .multiuserCalendar .lastLineEven {
    border-bottom:none;
}

/* Outer block surrounding the calendar, shared with single-user cal */
.calHeader {
    text-align: center;
    color: #333;
    font-weight: bold;
    padding-bottom: 5px;
}

.calHeader a {
    font-size: 100%;
}

.calHeader .prev{
    margin-right: 1em;
}

.calHeader .next{
    margin-left: 1em;
}

.calHeader .picker {
    margin: 0 1em 0;
    padding-top: 2px;
}


.multiuserCalendar .dateRow td{
    background-color: #B8AFAB;
    color:#fff;
    border-top:1px #999999 solid;
    border-bottom:1px #999999 solid;
    font-weight:bold;
    font-size: 91%;
    padding:1px 0px 0px 4px;
}

.multiuserCalendar .dateRow td a {
    color:#fff;
    font-weight:bold;
    font-size: 109%;
}

.superDetail .multiuserCalendar{
    overflow: auto;
}

.multiuserCalendar th, .multiuserCalendar .headerRow th.nameCol {
    background-color:#E2E2D1;
    color:#506749;
    font-weight:bold;
    padding:3px 0px 3px 0px;
}
.multiuserCalendar .calendarTable td.cbCol {
    text-align:center;
    vertical-align:middle;
}
.multiuserCalendar .btnCalendarPlus {
    padding-top:1px;
    float:right;
    height:10px;
    width:10px;
}
.multiuserCalendar .odd td, .multiuserCalendar .lastLineOdd td {
    background-color:#fff;
}
.multiuserCalendar .even td, .multiuserCalendar .lastLineEven td {
    background-color:#F9F9F9;
}
.multiuserCalendar .even td, .multiuserCalendar .odd td{
    border-bottom:1px solid #E3DEB8;
}
.multiuserCalendar .odd td, .multiuserCalendar .lastLineOdd td,
.multiuserCalendar .even td, .multiuserCalendar .lastLineEven td{
    padding:0px;
}
.multiuserCalendar .horario  div {
    height:22px;
    float:left;
    display:inline;
}
.multiuserCalendar td.nameCol,
.multiuserCalendar th.nameCol,
.multiuserCalendar td.typeCol {
    color:#5A5A5A;
    padding:4px 0px 4px 4px;
    vertical-align:middle;
}

.multiuserCalendar .eventCtnr {
    position: relative;
    min-height: 1.2em;
}

.multiuserCalendar .eventCtnr .eventBusy,
.multiuserCalendar .eventCtnr .eventFree,
.multiuserCalendar .eventCtnr .eventOOO
{
    text-decoration: none;
    display: block;
    position: absolute;
    top: 0;
    bottom: 0;
}

.superDetail .multiuserCalendar .eventCtnr .eventBusy,
.superDetail .multiuserCalendar .eventCtnr .eventFree,
.superDetail .multiuserCalendar .eventCtnr .eventOOO {
    position: relative;
}

.multiuserCalendar .eventCtnr .inner{
    display:block;
    width: 100%;
    height: 100%;
}

.multiuserCalendar .eventCtnr .callout{
    position: absolute;
    display: none;
    left:-2em;
    bottom: 120%;
    width: 15em;
    background-color: #FEFDB9;
    padding:  2px;
    border: 1px solid black;
    /*Mozilla:*/
    opacity: 0;
}

.superDetail .eventCtnr .eventBusy div,
.superDetail .eventCtnr .eventFree div,
.superDetail .eventCtnr .eventOOO div {
    margin: 0 4px;
    background-color: #FEFDB9;
    font-size: 75%;
}

.multiuserCalendar .eventCtnr .eventBusy {
    background-color: #69C;
}


.multiuserCalendar .eventCtnr .eventFree {
/*  intentionally blank - slevine bug #54128 */
}

.multiuserCalendar .eventCtnr .eventOOO {
    background-color: #B6624F;
}

.legend {
    padding:4px 5px 4px 0px;
    text-align:right;
}
.legend div {
    display:inline;
    height: 9px;
    padding-right: 9px;
}
.legend span {
    margin:0px 6px 0px 2px;
    padding-bottom:2px;
}

.legend .busy {
    background-color: #6699CC;
}
.legend .outOfOffice {
    background-color: #B6624F;
}

/* END MultiuserCalendar */
/* --------------------------------------------- */
/* BEGIN Entity Merge */
.mergeEntity {
    width: 100%;
}

.mergeEntity .headerRow td,
.mergeEntity .headerRow th{
    background-color: #DDD;
    text-align: left;
    font-weight: bold;
}

.mergeEntity .requiredInput th {
    color: white;
}

.account .mergeEntity .requiredInput th {
    background-color: #36C;
}
.account .mergeEntity .requiredMark {
   color: #36C;
}
.lead .mergeEntity .requiredInput th {
    background-color: #E1A21A;
}
.lead .mergeEntity .requiredMark {
   color: #E1A21A;
}
.contact .mergeEntity .requiredInput th {
    background-color: #56458C;
}
.contact .mergeEntity .requiredMark {
   color: #56458C;
}
.mergeEntity th{
    background-color: #DDD;
    text-align: right;
    vertical-align: top;
    border-bottom: 1px solid #BBB;
    padding-right: 2px;
}

.mergeEntity td {
    background-color: white;
    vertical-align: top;
    white-space: normal;
    border-bottom: 1px solid #BBB;
}

.mergeEntity .last td,
.mergeEntity .last th{
    border-bottom: none;
}

/* END Entity Merge */
/* --------------------------------------------- */
/* BEGIN Icons */
/* If possible we try to keep all icon substitions together */
/*  for the sake of classic mode & PNG->GIF swaps per browser sheet */

/* general skinnable utility icons */
.helpImage { background-image: url(/static/image/btn_help.gif);
        width:18px;
        height:16px; }

.printWinIcon { background-image: url(/static/image/print_icon.gif);
        width:18px;
        height:16px; }
.lookupPopup { background-image: url(/static/image/lookup.gif);
        width:18px;
        height:16px; }
.groupEventIcon { background-image: url(/static/image/group_event.gif);
        width:16px;
        height:16px; }
.doubleArrowUp { background-image: url(/static/image/double_arrow_up.gif);
        width:24px;
        height:20px; }
.doubleArrowDwn { background-image: url(/static/image/double_arrow_dwn.gif);
        width:24px;
        height:20px; }
.comboIcon { background-image: url(/static/image/combo.gif);
        width:18px;
        height:16px; }
.colorIcon { background-image: url(/static/image/color_icon.gif);
        width:18px;
        height:16px; }
.downArrowIcon { background-image: url(/static/image/arrow_dwn.gif);
        width:24px;
        height:20px; }
.leftArrowIcon { background-image: url(/static/image/arrow_lt.gif);
        width:24px;
        height:20px; }
.rightArrowIcon { background-image: url(/static/image/arrow_rt.gif);
        width:24px;
        height:20px; }
.upArrowIcon{ background-image: url(/static/image/arrow_up.gif);
        width:24px;
        height:20px; }
.datePickerIcon { background-image: url(/static/image/date_picker.gif);
        width:18px;
        height:16px; }
.escalatedLarge { background-image: url(/static/image/escalated_lg.gif);
        width:16px;
        height:16px;
  vertical-align: middle;
  margin-left: 3px;
  margin-top: 3px;
}
.escalatedSmall {
  background-image: url(/static/image/escalated.gif);
        width:16px;
        height:16px;
  vertical-align: middle;
  margin-left: 3px;
  margin-top: -2px;
}
.mouseover { background-image: url(/static/image/mouseover_icon.gif);
        width:18px;
        height:16px; }

.imgNewDataSmall, .imgNewData {
  vertical-align: top;
  margin-left: .5em;
}

/* multiforce bar */
.tab .multiforce div {
background-image: url(/static/image/tab/mf_picklist.gif);
        width:47px;
        height:21px;
background-repeat: no-repeat;
 }


/* End general utility icons */
/* Shared Icon Styles for entities  */
/* bAccount comes from listDefaultClassName in motif (used only on search results) */
/* .searchResults .bAccount .relatedListIcon, */
.listAccount .relatedListIcon,
.listContact .relatedListIcon,
.listLead .relatedListIcon,
.listOpportunity .relatedListIcon,
.listCase .relatedListIcon,
.listCampaign .relatedListIcon,
.listContract .relatedListIcon,
.listOrder .relatedListIcon,
.listInvoice .relatedListIcon,
.listCustom .relatedListIcon,
.listForecast .relatedListIcon,
.listReport .relatedListIcon,
.listProduct .relatedListIcon,
.listSolution .relatedListIcon,
.listHome .relatedListIcon,
.listDocument .relatedListIcon
 {
   position: relative;
  float:left;
  margin-top:-4px;
  margin-left:5px;
  display: inline;
}

/* indent headers of entities with icons */
/*.searchResults .bAccount .pbTitle h3 ,*/
.listAccount .pbTitle h3 ,
.listContact .pbTitle h3 ,
.listLead .pbTitle h3 ,
.listOpportunity .pbTitle h3 ,
.listCase .pbTitle h3 ,
.listCampaign .pbTitle h3 ,
.listContract .pbTitle h3 ,
.listOrder .pbTitle h3 ,
.listInvoice .pbTitle h3 ,
.listCustom .pbTitle h3,
.listForecast .pbTitle h3,
.listSolution .pbTitle h3,
.listProduct .pbTitle h3,
.listHome .pbTitle h3,
.listDocument .pbTitle h3,
.listReport .pbTitle h3
{
    margin: 3px 0 0 32px;
}


/* begin related list icon hiding */

.relatedListIcon { display: none; }

body.setup .noCustomTab .pbTitle h3,
 .noCustomTab .pbTitle h3 { margin-left: 4px; }
body.setup .noCustomTab .relatedListIcon,
 .noCustomTab .relatedListIcon { display:none; }

/* end related list icon hiding */


.relatedListIcon,
.mruIcon {
    background-repeat:no-repeat;
}

.hideListButton { background-image: url(/static/image/twistySubhDown.gif);
        width:16px;
        height:10px; }
.showListButton { background-image: url(/static/image/twistySubhRight.gif);
        width:16px;
        height:10px; }
/* on the AllTabs page, we are relying on icons appearing in the order: pageTitleIcon, relatedListIcon */

.lookup .pageTitleIcon { background-image: url(/static/image/icon/lookup32.png);
        width:32px;
        height:32px; }

.home .pageTitleIcon {  background-image: url(/static/image/icon/home32.png);
        width:32px;
        height:32px; }
.listHome .relatedListIcon { background-image: url(/static/image/icon/home24.png);
        width:24px;
        height:24px; }
/* why is this A tag necessary? So that the class from the body tag is not counted */
.account .pageTitleIcon { background-image: url(/static/image/icon/accounts32.png);
        width:32px;
        height:32px; }
.listAccount .relatedListIcon { background-image: url(/static/image/icon/accounts24.png);
        width:24px;
        height:24px; }
a.account .mruIcon { background-image: url(/static/image/icon/accounts16.gif);
        width:16px;
        height:16px; }

.campaign .pageTitleIcon { background-image: url(/static/image/icon/campaigns32.png);
        width:32px;
        height:32px; }
.listCampaign .relatedListIcon { background-image: url(/static/image/icon/campaigns24.png);
        width:24px;
        height:24px; }
a.campaign .mruIcon { background-image: url(/static/image/icon/campaigns16.gif);
        width:16px;
        height:16px; }

.case .pageTitleIcon { background-image: url(/static/image/icon/cases32.png);
        width:32px;
        height:32px; }
.listCase .relatedListIcon { background-image: url(/static/image/icon/cases24.png);
        width:24px;
        height:24px; }
a.case .mruIcon { background-image: url(/static/image/icon/cases16.gif);
        width:16px;
        height:16px; }

.contact .pageTitleIcon { background-image: url(/static/image/icon/contacts32.png);
        width:32px;
        height:32px; }
.listContact .relatedListIcon { background-image: url(/static/image/icon/contacts24.png);
        width:24px;
        height:24px; }
a.contact .mruIcon { background-image: url(/static/image/icon/contacts16.gif);
        width:16px;
        height:16px; }

.contract .pageTitleIcon { background-image: url(/static/image/icon/contracts32.png);
        width:32px;
        height:32px; }
.listContract .relatedListIcon { background-image: url(/static/image/icon/contracts24.png);
        width:24px;
        height:24px; }
a.contract .mruIcon { background-image: url(/static/image/icon/contracts16.gif);
        width:16px;
        height:16px; }

.dashboard .pageTitleIcon { background-image: url(/static/image/icon/dashboards32.png);
        width:32px;
        height:32px; }
.listDashboard .relatedListIcon { background-image: url(/static/image/icon/dashboards24.png);
        width:24px;
        height:24px; }

.document .pageTitleIcon { background-image: url(/static/image/icon/documents32.png);
        width:32px;
        height:32px; }
.listDocument .relatedListIcon { background-image: url(/static/image/icon/documents24.png);
        width:24px;
        height:24px; }
a.document .mruIcon { background-image: url(/static/image/icon/documents16.gif);
        width:16px;
        height:16px; }

.forecast .pageTitleIcon { background-image: url(/static/image/icon/forecasts32.png);
        width:32px;
        height:32px; }
.listForecast .relatedListIcon { background-image: url(/static/image/icon/forecasts24.png);
        width:24px;
        height:24px; }

.listInvoice .relatedListIcon { background-image: url(/static/image/icon/invoices24.png);
        width:24px;
        height:24px; }
a.invoice .mruIcon { background-image: url(/static/image/icon/invoices16.gif);
        width:16px;
        height:16px; }

.lead .pageTitleIcon { background-image: url(/static/image/icon/leads32.png);
        width:32px;
        height:32px; }
.listLead .relatedListIcon { background-image: url(/static/image/icon/leads24.png);
        width:24px;
        height:24px; }
a.lead .mruIcon { background-image: url(/static/image/icon/leads16.gif);
        width:16px;
        height:16px; }

.opportunity .pageTitleIcon { background-image: url(/static/image/icon/opportunities32.png);
        width:32px;
        height:32px; }
.listOpportunity .relatedListIcon { background-image: url(/static/image/icon/opportunities24.png);
        width:24px;
        height:24px; }
a.opportunity .mruIcon { background-image: url(/static/image/icon/opportunities16.gif);
        width:16px;
        height:16px; }

.product .pageTitleIcon {background-image: url(/static/image/icon/products32.png);
        width:32px;
        height:32px; }
.listProduct .relatedListIcon {  background-image: url(/static/image/icon/products24.png);
        width:24px;
        height:24px; }
a.product .mruIcon { background-image: url(/static/image/icon/products16.gif);
        width:16px;
        height:16px; }

.report .pageTitleIcon {    background-image: url(/static/image/icon/reports32.png);
        width:32px;
        height:32px; }
.listReport .relatedListIcon { background-image: url(/static/image/icon/reports24.png);
        width:24px;
        height:24px; }
a.report .mruIcon { background-image: url(/static/image/icon/reports16.gif);
        width:16px;
        height:16px; }

.solution .pageTitleIcon {  background-image: url(/static/image/icon/solutions32.png);
        width:32px;
        height:32px; }
.listSolution .relatedListIcon {    background-image: url(/static/image/icon/solutions24.png);
        width:24px;
        height:24px; }
a.solution .mruIcon {   background-image: url(/static/image/icon/solutions16.gif);
        width:16px;
        height:16px; }

.portal .pageTitleIcon { background-image: url(/static/image/icon/portals32.png);
        width:32px;
        height:32px; }
.listPortal .relatedListIcon { background-image: url(/static/image/icon/portals24.png);
        width:24px;
        height:24px; }
a.portal .mruIcon { background-image: url(/static/image/icon/portal16.gif);
        width:16px;
        height:16px; }

.order .pageTitleIcon { background-image: url(/static/image/icon/orderBell32.png);
        width:32px;
        height:32px; }
.listOrder .relatedListIcon { background-image: url(/static/image/icon/orderBell24.png);
        width:24px;
        height:24px; }
a.order .mruIcon { background-image: url(/static/image/icon/orderBell16.gif);
        width:16px;
        height:16px; }

/* begin custom icons */

a.noCustomTab .mruIcon { background-image: url(/static/image/icon/custom16.gif);
        width:16px;
        height:16px; }
.noCustomTab .pageTitleIcon { background-image: url(/static/image/icon/custom32.png);
        width:32px;
        height:32px; }
.listCustom.noCustomTab .relatedListIcon { background-image: url(/static/image/icon/custom24.png);
        width:24px;
        height:24px; }

.custom1 .mruIcon { background-image: url(/static/image/icon/heart16.gif);
        width:16px;
        height:16px; }
.customTab1 .pageTitleIcon { background-image: url(/static/image/icon/heart32.png);
        width:32px;
        height:32px; }
.listCustom.custom1 .relatedListIcon { background-image: url(/static/image/icon/heart24.png);
        width:24px;
        height:24px; }

.custom2 .mruIcon { background-image: url(/static/image/icon/fan16.gif);
        width:16px;
        height:16px; }
.customTab2 .pageTitleIcon { background-image: url(/static/image/icon/fan32.png);
        width:32px;
        height:32px; }
.listCustom.custom2 .relatedListIcon { background-image: url(/static/image/icon/fan24.png);
        width:24px;
        height:24px; }

.custom3 .mruIcon { background-image: url(/static/image/icon/sun16.gif);
        width:16px;
        height:16px; }
.customTab3 .pageTitleIcon { background-image: url(/static/image/icon/sun32.png);
        width:32px;
        height:32px; }
.listCustom.custom3 .relatedListIcon { background-image: url(/static/image/icon/sun24.png);
        width:24px;
        height:24px; }

.custom4 .mruIcon { background-image: url(/static/image/icon/hexagon16.gif);
        width:16px;
        height:16px; }
.customTab4 .pageTitleIcon { background-image: url(/static/image/icon/hexagon32.png);
        width:32px;
        height:32px; }
.listCustom.custom4 .relatedListIcon { background-image: url(/static/image/icon/hexagon24.png);
        width:24px;
        height:24px; }

.custom5 .mruIcon { background-image: url(/static/image/icon/leaf16.gif);
        width:16px;
        height:16px; }
.customTab5 .pageTitleIcon { background-image: url(/static/image/icon/leaf32.png);
        width:32px;
        height:32px; }
.listCustom.custom5 .relatedListIcon { background-image: url(/static/image/icon/leaf24.png);
        width:24px;
        height:24px; }

.custom6 .mruIcon { background-image: url(/static/image/icon/triangle16.gif);
        width:16px;
        height:16px; }
.customTab6 .pageTitleIcon { background-image: url(/static/image/icon/triangle32.png);
        width:32px;
        height:32px; }
.listCustom.custom6 .relatedListIcon { background-image: url(/static/image/icon/triangle24.png);
        width:24px;
        height:24px; }

.custom7 .mruIcon { background-image: url(/static/image/icon/square16.gif);
        width:16px;
        height:16px; }
.customTab7 .pageTitleIcon { background-image: url(/static/image/icon/square32.png);
        width:32px;
        height:32px; }
.listCustom.custom7 .relatedListIcon { background-image: url(/static/image/icon/square24.png);
        width:24px;
        height:24px; }

.custom8 .mruIcon { background-image: url(/static/image/icon/diamond16.gif);
        width:16px;
        height:16px; }
.customTab8 .pageTitleIcon { background-image: url(/static/image/icon/diamond32.png);
        width:32px;
        height:32px; }
.listCustom.custom8 .relatedListIcon { background-image: url(/static/image/icon/diamond24.png);
        width:24px;
        height:24px; }

.custom9 .mruIcon { background-image: url(/static/image/icon/lightning16.gif);
        width:16px;
        height:16px; }
.customTab9 .pageTitleIcon { background-image: url(/static/image/icon/lightning32.png);
        width:32px;
        height:32px; }
.listCustom.custom9 .relatedListIcon { background-image: url(/static/image/icon/lightning24.png);
        width:24px;
        height:24px; }

.custom10 .mruIcon { background-image: url(/static/image/icon/moon16.gif);
        width:16px;
        height:16px; }
.customTab10 .pageTitleIcon { background-image: url(/static/image/icon/moon32.png);
        width:32px;
        height:32px; }
.listCustom.custom10 .relatedListIcon { background-image: url(/static/image/icon/moon24.png);
        width:24px;
        height:24px; }

.custom11 .mruIcon { background-image: url(/static/image/icon/star16.gif);
        width:16px;
        height:16px; }
.customTab11 .pageTitleIcon { background-image: url(/static/image/icon/star32.png);
        width:32px;
        height:32px; }
.listCustom.custom11 .relatedListIcon { background-image: url(/static/image/icon/star24.png);
        width:24px;
        height:24px; }

.custom12 .mruIcon { background-image: url(/static/image/icon/circle16.gif);
        width:16px;
        height:16px; }
.customTab12 .pageTitleIcon { background-image: url(/static/image/icon/circle32.png);
        width:32px;
        height:32px; }
.listCustom.custom12 .relatedListIcon { background-image: url(/static/image/icon/circle24.png);
        width:24px;
        height:24px; }

.custom12 .mruIcon { background-image: url(/static/image/icon/circle16.gif);
        width:16px;
        height:16px; }
.customTab12 .pageTitleIcon { background-image: url(/static/image/icon/circle32.png);
        width:32px;
        height:32px; }
.listCustom.custom12 .relatedListIcon { background-image: url(/static/image/icon/circle24.png);
        width:24px;
        height:24px; }

.custom13 .mruIcon { background-image: url(/static/image/icon/box16.gif);
        width:16px;
        height:16px; }
.customTab13 .pageTitleIcon { background-image: url(/static/image/icon/box32.png);
        width:32px;
        height:32px; }
.listCustom.custom13 .relatedListIcon { background-image: url(/static/image/icon/box24.png);
        width:24px;
        height:24px; }

.custom14 .mruIcon {    background-image: url(/static/image/icon/hands16.gif);
        width:16px;
        height:16px; }
.customTab14 .pageTitleIcon { background-image: url(/static/image/icon/hands32.png);
        width:32px;
        height:32px; }
.listCustom.custom14 .relatedListIcon { background-image: url(/static/image/icon/hands24.png);
        width:24px;
        height:24px; }

.custom15 .mruIcon {    background-image: url(/static/image/icon/people16.gif);
        width:16px;
        height:16px; }
.customTab15 .pageTitleIcon { background-image: url(/static/image/icon/people32.png);
        width:32px;
        height:32px; }
.listCustom.custom15 .relatedListIcon { background-image: url(/static/image/icon/people24.png);
        width:24px;
        height:24px; }

.custom16 .mruIcon {    background-image: url(/static/image/icon/bank16.gif);
        width:16px;
        height:16px; }
.customTab16 .pageTitleIcon { background-image: url(/static/image/icon/bank32.png);
        width:32px;
        height:32px; }
.listCustom.custom16 .relatedListIcon { background-image: url(/static/image/icon/bank24.png);
        width:24px;
        height:24px; }

.custom17 .mruIcon {    background-image: url(/static/image/icon/sack16.gif);
        width:16px;
        height:16px; }
.customTab17 .pageTitleIcon { background-image: url(/static/image/icon/sack32.png);
        width:32px;
        height:32px; }
.listCustom.custom17 .relatedListIcon { background-image: url(/static/image/icon/sack24.png);
        width:24px;
        height:24px; }

.custom18 .mruIcon {    background-image: url(/static/image/icon/form16.gif);
        width:16px;
        height:16px; }
.customTab18 .pageTitleIcon { background-image: url(/static/image/icon/form32.png);
        width:32px;
        height:32px; }
.listCustom.custom18 .relatedListIcon { background-image: url(/static/image/icon/form24.png);
        width:24px;
        height:24px; }

.custom19 .mruIcon {    background-image: url(/static/image/icon/wrench16.gif);
        width:16px;
        height:16px; }
.customTab19 .pageTitleIcon { background-image: url(/static/image/icon/wrench32.png);
        width:32px;
        height:32px; }
.listCustom.custom19 .relatedListIcon { background-image: url(/static/image/icon/wrench24.png);
        width:24px;
        height:24px; }

.custom20 .mruIcon {    background-image: url(/static/image/icon/plane16.gif);
        width:16px;
        height:16px; }
.customTab20 .pageTitleIcon { background-image: url(/static/image/icon/plane32.png);
        width:32px;
        height:32px; }
.listCustom.custom20 .relatedListIcon { background-image: url(/static/image/icon/plane24.png);
        width:24px;
        height:24px; }

.custom21 .mruIcon {    background-image: url(/static/image/icon/computer16.gif);
        width:16px;
        height:16px; }
.customTab21 .pageTitleIcon { background-image: url(/static/image/icon/computer32.png);
        width:32px;
        height:32px; }
.listCustom.custom21 .relatedListIcon { background-image: url(/static/image/icon/computer24.png);
        width:24px;
        height:24px; }

.custom22 .mruIcon {    background-image: url(/static/image/icon/phone16.gif);
        width:16px;
        height:16px; }
.customTab22 .pageTitleIcon { background-image: url(/static/image/icon/phone32.png);
        width:32px;
        height:32px; }
.listCustom.custom22 .relatedListIcon { background-image: url(/static/image/icon/phone24.png);
        width:24px;
        height:24px; }

.custom23 .mruIcon {    background-image: url(/static/image/icon/mail16.gif);
        width:16px;
        height:16px; }
.customTab23 .pageTitleIcon { background-image: url(/static/image/icon/mail32.png);
        width:32px;
        height:32px; }
.listCustom.custom23 .relatedListIcon { background-image: url(/static/image/icon/mail24.png);
        width:24px;
        height:24px; }

.custom24 .mruIcon {    background-image: url(/static/image/icon/building16.gif);
        width:16px;
        height:16px; }
.customTab24 .pageTitleIcon { background-image: url(/static/image/icon/building32.png);
        width:32px;
        height:32px; }
.listCustom.custom24 .relatedListIcon { background-image: url(/static/image/icon/building24.png);
        width:24px;
        height:24px; }

.custom25 .mruIcon {    background-image: url(/static/image/icon/alarmClock16.gif);
        width:16px;
        height:16px; }
.customTab25 .pageTitleIcon { background-image: url(/static/image/icon/alarmClock32.png);
        width:32px;
        height:32px; }
.listCustom.custom25 .relatedListIcon { background-image: url(/static/image/icon/alarmClock24.png);
        width:24px;
        height:24px; }

.custom26 .mruIcon {    background-image: url(/static/image/icon/flag16.gif);
        width:16px;
        height:16px; }
.customTab26 .pageTitleIcon { background-image: url(/static/image/icon/flag32.png);
        width:32px;
        height:32px; }
.listCustom.custom26 .relatedListIcon { background-image: url(/static/image/icon/flag24.png);
        width:24px;
        height:24px; }

.custom27 .mruIcon {    background-image: url(/static/image/icon/laptop16.gif);
        width:16px;
        height:16px; }
.customTab27 .pageTitleIcon { background-image: url(/static/image/icon/laptop32.png);
        width:32px;
        height:32px; }
.listCustom.custom27 .relatedListIcon { background-image: url(/static/image/icon/laptop24.png);
        width:24px;
        height:24px; }

.custom28 .mruIcon {    background-image: url(/static/image/icon/cellPhone16.gif);
        width:16px;
        height:16px; }
.customTab28 .pageTitleIcon { background-image: url(/static/image/icon/cellPhone32.png);
        width:32px;
        height:32px; }
.listCustom.custom28 .relatedListIcon { background-image: url(/static/image/icon/cellPhone24.png);
        width:24px;
        height:24px; }

.custom29 .mruIcon {    background-image: url(/static/image/icon/pda16.gif);
        width:16px;
        height:16px; }
.customTab29 .pageTitleIcon { background-image: url(/static/image/icon/pda32.png);
        width:32px;
        height:32px; }
.listCustom.custom29 .relatedListIcon { background-image: url(/static/image/icon/pda24.png);
        width:24px;
        height:24px; }

.custom30 .mruIcon {    background-image: url(/static/image/icon/radarDish16.gif);
        width:16px;
        height:16px; }
.customTab30 .pageTitleIcon { background-image: url(/static/image/icon/radarDish32.png);
        width:32px;
        height:32px; }
.listCustom.custom30 .relatedListIcon { background-image: url(/static/image/icon/radarDish24.png);
        width:24px;
        height:24px; }

.custom31 .mruIcon {    background-image: url(/static/image/icon/car16.gif);
        width:16px;
        height:16px; }
.customTab31 .pageTitleIcon { background-image: url(/static/image/icon/car32.png);
        width:32px;
        height:32px; }
.listCustom.custom31 .relatedListIcon { background-image: url(/static/image/icon/car24.png);
        width:24px;
        height:24px; }

.custom32 .mruIcon {    background-image: url(/static/image/icon/factory16.gif);
        width:16px;
        height:16px; }
.customTab32 .pageTitleIcon { background-image: url(/static/image/icon/factory32.png);
        width:32px;
        height:32px; }
.listCustom.custom32 .relatedListIcon { background-image: url(/static/image/icon/factory24.png);
        width:24px;
        height:24px; }

.custom33 .mruIcon {    background-image: url(/static/image/icon/desk16.gif);
        width:16px;
        height:16px; }
.customTab33 .pageTitleIcon { background-image: url(/static/image/icon/desk32.png);
        width:32px;
        height:32px; }
.listCustom.custom33 .relatedListIcon { background-image: url(/static/image/icon/desk24.png);
        width:24px;
        height:24px; }

.custom34 .mruIcon {    background-image: url(/static/image/icon/insect16.gif);
        width:16px;
        height:16px; }
.customTab34 .pageTitleIcon { background-image: url(/static/image/icon/insect32.png);
        width:32px;
        height:32px; }
.listCustom.custom34 .relatedListIcon { background-image: url(/static/image/icon/insect24.png);
        width:24px;
        height:24px; }

.custom35 .mruIcon {    background-image: url(/static/image/icon/microphone16.gif);
        width:16px;
        height:16px; }
.customTab35 .pageTitleIcon { background-image: url(/static/image/icon/microphone32.png);
        width:32px;
        height:32px; }
.listCustom.custom35 .relatedListIcon { background-image: url(/static/image/icon/microphone24.png);
        width:24px;
        height:24px; }

.custom36 .mruIcon {    background-image: url(/static/image/icon/train16.gif);
        width:16px;
        height:16px; }
.customTab36 .pageTitleIcon { background-image: url(/static/image/icon/train32.png);
        width:32px;
        height:32px; }
.listCustom.custom36 .relatedListIcon { background-image: url(/static/image/icon/train24.png);
        width:24px;
        height:24px; }

.custom37 .mruIcon {    background-image: url(/static/image/icon/bridge16.gif);
        width:16px;
        height:16px; }
.customTab37 .pageTitleIcon { background-image: url(/static/image/icon/bridge32.png);
        width:32px;
        height:32px; }
.listCustom.custom37 .relatedListIcon { background-image: url(/static/image/icon/bridge24.png);
        width:24px;
        height:24px; }

.custom38 .mruIcon {    background-image: url(/static/image/icon/camera16.gif);
        width:16px;
        height:16px; }
.customTab38 .pageTitleIcon { background-image: url(/static/image/icon/camera32.png);
        width:32px;
        height:32px; }
.listCustom.custom38 .relatedListIcon { background-image: url(/static/image/icon/camera24.png);
        width:24px;
        height:24px; }

.custom39 .mruIcon {    background-image: url(/static/image/icon/telescope16.gif);
        width:16px;
        height:16px; }
.customTab39 .pageTitleIcon { background-image: url(/static/image/icon/telescope32.png);
        width:32px;
        height:32px; }
.listCustom.custom39 .relatedListIcon { background-image: url(/static/image/icon/telescope24.png);
        width:24px;
        height:24px; }

.custom40 .mruIcon {    background-image: url(/static/image/icon/creditCard16.gif);
        width:16px;
        height:16px; }
.customTab40 .pageTitleIcon { background-image: url(/static/image/icon/creditCard32.png);
        width:32px;
        height:32px; }
.listCustom.custom40 .relatedListIcon { background-image: url(/static/image/icon/creditCard24.png);
        width:24px;
        height:24px; }

.custom41 .mruIcon {    background-image: url(/static/image/icon/cash16.gif);
        width:16px;
        height:16px; }
.customTab41 .pageTitleIcon { background-image: url(/static/image/icon/cash32.png);
        width:32px;
        height:32px; }
.listCustom.custom41 .relatedListIcon { background-image: url(/static/image/icon/cash24.png);
        width:24px;
        height:24px; }

.custom42 .mruIcon {    background-image: url(/static/image/icon/chest16.gif);
        width:16px;
        height:16px; }
.customTab42 .pageTitleIcon { background-image: url(/static/image/icon/chest32.png);
        width:32px;
        height:32px; }
.listCustom.custom42 .relatedListIcon { background-image: url(/static/image/icon/chest24.png);
        width:24px;
        height:24px; }

.custom43 .mruIcon {    background-image: url(/static/image/icon/jewel16.gif);
        width:16px;
        height:16px; }
.customTab43 .pageTitleIcon { background-image: url(/static/image/icon/jewel32.png);
        width:32px;
        height:32px; }
.listCustom.custom43 .relatedListIcon { background-image: url(/static/image/icon/jewel24.png);
        width:24px;
        height:24px; }

.custom44 .mruIcon {    background-image: url(/static/image/icon/hammer16.gif);
        width:16px;
        height:16px; }
.customTab44 .pageTitleIcon { background-image: url(/static/image/icon/hammer32.png);
        width:32px;
        height:32px; }
.listCustom.custom44 .relatedListIcon { background-image: url(/static/image/icon/hammer24.png);
        width:24px;
        height:24px; }

.custom45 .mruIcon {    background-image: url(/static/image/icon/ticket16.gif);
        width:16px;
        height:16px; }
.customTab45 .pageTitleIcon { background-image: url(/static/image/icon/ticket32.png);
        width:32px;
        height:32px; }
.listCustom.custom45 .relatedListIcon { background-image: url(/static/image/icon/ticket24.png);
        width:24px;
        height:24px; }

.custom46 .mruIcon {    background-image: url(/static/image/icon/stamp16.gif);
        width:16px;
        height:16px; }
.customTab46 .pageTitleIcon { background-image: url(/static/image/icon/stamp32.png);
        width:32px;
        height:32px; }
.listCustom.custom46 .relatedListIcon { background-image: url(/static/image/icon/stamp24.png);
        width:24px;
        height:24px; }

.custom47 .mruIcon {    background-image: url(/static/image/icon/knight16.gif);
        width:16px;
        height:16px; }
.customTab47 .pageTitleIcon { background-image: url(/static/image/icon/knight32.png);
        width:32px;
        height:32px; }
.listCustom.custom47 .relatedListIcon { background-image: url(/static/image/icon/knight24.png);
        width:24px;
        height:24px; }

.custom48 .mruIcon {    background-image: url(/static/image/icon/trophy16.gif);
        width:16px;
        height:16px; }
.customTab48 .pageTitleIcon { background-image: url(/static/image/icon/trophy32.png);
        width:32px;
        height:32px; }
.listCustom.custom48 .relatedListIcon { background-image: url(/static/image/icon/trophy24.png);
        width:24px;
        height:24px; }

.custom49 .mruIcon {    background-image: url(/static/image/icon/cd16.gif);
        width:16px;
        height:16px; }
.customTab49 .pageTitleIcon { background-image: url(/static/image/icon/cd32.png);
        width:32px;
        height:32px; }
.listCustom.custom49 .relatedListIcon { background-image: url(/static/image/icon/cd24.png);
        width:24px;
        height:24px; }

.custom50 .mruIcon {    background-image: url(/static/image/icon/bigtop16.gif);
        width:16px;
        height:16px; }
.customTab50 .pageTitleIcon { background-image: url(/static/image/icon/bigtop32.png);
        width:32px;
        height:32px; }
.listCustom.custom50 .relatedListIcon { background-image: url(/static/image/icon/bigtop24.png);
        width:24px;
        height:24px; }
/* end custom icons */

/* END Icons */
/* --------------------------------------------- */
/* BEGIN Calendar buttons, used on multiple pages */
.calendarIconBar {
    padding-top: 3px;
}

.calendarIconBar .dayViewIconOn {
    background-image: url(/static/image/cal/btnDay_on.gif);
        width:24px;
        height:18px;
    display:block;
}

.calendarIconBar .dayViewIcon {
    background-image: url(/static/image/cal/btnDay_off.gif);
        width:24px;
        height:18px;
    display:block;
}

.calendarIconBar .weekViewIconOn {
    background-image: url(/static/image/cal/btnWeek_on.gif);
        width:24px;
        height:18px;
    display:block;
}

.calendarIconBar .weekViewIcon {
    background-image: url(/static/image/cal/btnWeek_off.gif);
        width:24px;
        height:18px;
    display:block;
}

.calendarIconBar .monthViewIconOn {
    background-image: url(/static/image/cal/btnMonth_on.gif);
        width:24px;
        height:18px;
    display:block;
    padding-right: 13px;
}

.calendarIconBar .monthViewIcon {
    background-image: url(/static/image/cal/btnMonth_off.gif);
        width:24px;
        height:18px;
    display:block;
    padding-right: 13px;
}

.calendarIconBar .singleUserViewIconOn {
    background-image: url(/static/image/cal/btnOnePerson_on.gif);
        width:24px;
        height:18px;
    display:block;
}

.calendarIconBar .singleUserViewIcon {
    background-image: url(/static/image/cal/btnOnePerson_off.gif);
        width:24px;
        height:18px;
    display:block;
}

.calendarIconBar .multiUserViewIconOn {
    background-image: url(/static/image/cal/btnMultiPerson_on.gif);
        width:24px;
        height:18px;
    display:block;
    padding-right: 13px;
}

.calendarIconBar .multiUserViewIcon {
    background-image: url(/static/image/cal/btnMultiPerson_off.gif);
        width:24px;
        height:18px;
    display:block;
    padding-right: 13px;
}

.calendarIconBar .listViewIconOn {
    background-image: url(/static/image/cal/btnListView_on.gif);
        width:24px;
        height:18px;
    display:block;
    padding-right: 0px;
}

.calendarIconBar .listViewIcon {
    background-image: url(/static/image/cal/btnListView_off.gif);
        width:24px;
        height:18px;
    display:block;
    padding-right: 0px;
}

/* this can probably be changed to regular inline layout */
.calendarIconBar img {
    float: left;
    background-repeat: no-repeat;
    padding-right: 3px;
    width: 24px;
    height: 18px;
}

.calendarIconBar .clear {
    clear: both;
}

.prevCalArrow { background-image: url(/static/image/cal/btnLeft.gif);
        width:19px;
        height:13px; }

.nextCalArrow { background-image: url(/static/image/cal/btnRight.gif);
        width:19px;
        height:13px; }


/* END calendar Buttons */
/* -------------------------------- */
/* BEGIN Sidebar Modules */
/* - html Area Left -*/

.oLeft .bHtmlArea{
    background-color:#E8E8E8;
    padding:15px 6px 16px 11px;
    border-top:2px #FFF solid;
}

.oLeft .bHtmlArea .header {
    padding:2px 2px 2px 4px;
    font-weight:bold;
}

.topButton,
.bottomButton {
    padding: 2px 0;
    text-align: center;
}

/* - Generic -*/
.mStandard {
    background-color:#E8E8E8;
    padding:15px 6px 16px 11px;
    border-top:2px #FFF solid;
}

.mStandard .requiredMark {
    color: #E8E8E8;
}

.mStandard .header {
    padding:2px 2px 2px 4px;
    font-weight:bold;
}

.mStandard h3 {
    margin-top: 5px;
    padding: 2px 2px 2px 1px;
    font-weight: normal;
    display: block;
}

.mStandard .body  {
    padding:1px 2px 5px 4px;
}

.mStandard .body input, .mStandard .body select{
    font-size: 100%;
}

.mStandard .footer {
    padding: 2px 0;
}

/* - Create New - */
.mCreateNew {
    background-color:#E8E8E8;
    padding:15px 6px 16px 11px;
    border-top:2px #FFF solid;
}
.mCreateNew .header {
    padding:2px 2px 2px 4px;
    font-weight:bold;
}

.mCreateNew select {
    width:165px;
    font-size: 91%;
    margin:1px 7px 0px 0px;
}
   /* only in accessible mode */
.mCreateNew .btn {
    float: right;
}

/* - Recycle Bin - */
.recycleBin .undelButtons {
    text-align: center;
}

body.recycleBin .bFilter {
  margin-left: 0;
}

body.recycleBin .bFilter input {
  margin-left: .25em;
  margin-right: .25em;
}
.mRecycle {
    border-top:#FFFFFF solid 2px;
    border-bottom:#FFFFFF solid 2px;
    background-color:#E8EEE3;
}
.mRecycle .body{
    padding:10px 12px 10px 16px;
    font-weight:bold;
}
.mRecycle a {
    color:#336600;
    text-decoration:none;
}

/* - Recent Items - */
.mRecentItem {
    padding:12px 8px 2px 8px;
    background-color:#E8E8E8;
    border-top:2px #FFF solid;
    margin-bottom:10px;
}
.mRecentItem .header {
    padding:2px 2px 0px 6px;
    font-weight:bold;
}

.mRecentItem .body  {
    position: relative;
    margin: .6em 2px .6em 31px;
}

.mRecentItem .body img {
    position: absolute;
    left: -25px;
}

.mRecentItem a {
    text-decoration: none;
}

.mRecentItem .mruText {
    text-decoration: underline;
}

.mRecentItem .calendarSidebarShortcut {
  margin-bottom: 1em;
}

/* - Search - */
.pbSearch input.searchTextBox {
    margin-right: 3px;
    vertical-align: middle;
}

.mSearch, .mFind {
    background-color:#D9D9D9;
    padding:11px 6px 5px 11px;
    color:#333;
}
.mFind {
    background-color:#E8E8E8;
    border-top:2px #ffffff solid;
    padding-bottom:12px;
}
.mSearch .header, .mFind .header {
    padding:2px 2px 2px 4px;
    font-weight:bold;
}
.mSearch input.searchTextBox, .mFind input.searchTextBox {
    width:160px;
    margin:1px;
    margin-right:7px;
    font-size: 91%;
    vertical-align: middle;
}

.mSearch .pbSearch  input.searchTextBox{
    margin-bottom:0;
}

.mSearch .footer, .mFind .footer {
    padding:6px 2px 0px 30px;
  display: inline;
    font-size: 91%;
}

.mSearch div.body {
  display: inline;
}

.mMessage, .mCustomLink {
    margin:10px 0px 20px 0px;
    background-color: #E8E8E8;
    padding:0px 15px 0px 13px;
    background-image:  url("/static/image/bgmMessage.gif");
    background-repeat: no-repeat;
    background-position: left top;
}

.mMessage .content div, .mCustomLink .content div {
    margin:0px 10px;
}
.mMessage .content, .mCustomLink .content {
    background-color:#FFFFFF;
    padding-bottom:4px;
}
.mMessage .header, .mCustomLink .header {
    color:#333333;
    font-weight:bold;
    text-align:left;
    padding:7px 3px 8px 5px;
    border-bottom:solid 1px #CCCCCC;
}
.mMessage .subheader h3, .mCustomLink .subheader h3{
    font-family: 'Arial', 'Helvetica', sans-serif;
    font-weight: bold;
    font-size: 91%;
    color:#333333;
    text-align:left;
    padding:11px 3px 2px 5px;
}
.mMessage .divide, .mCustomLink .divide {
    margin:0px 5px 0px 5px;
    padding-top: 1px;
    background-color: #FFFFFF;
    background-image:  url("/static/image/divmMessage.gif");
    background-repeat: repeat-x;
    background-position: left top;
}
/* - Custom Links - */
.mCustomLink .header {
    margin-bottom:5px;
}

.mCustomLink .body ul {
    padding-left: 0;
    margin-left: 0;
}

.mCustomLink .body li {
    list-style: disc;
    padding:2px 3px 4px 5px;
    color:#333333;
    text-align:left;
}
.mMessage .body {
    line-height:1.6em;
    color:#333333;
    text-align:left;
    font-weight: normal;
    padding:0px 3px 8px 5px;
}
.mCustomLink .content {
    background-color:#FFFFFF;
    padding-bottom:12px;
}

/* - Division - */
.mDivision  {
    background-color:#D9D9D9;
    height: 1%;
    padding:11px 6px 5px 11px;
    color:#333;
    border-bottom:#FFFFFF solid 2px;
}

.mDivision .header {
    padding:2px 2px 2px 4px;
    font-weight:bold;
    margin-bottom:1px;
}

.mDivision .body {
    padding-right: 2px;
    margin-bottom:4px;
}

.mDivision select {
    width:165px;
    font-size: 91%;
    margin:1px 7px 0px 0px;
}

.mQuickCreate .requiredInput .requiredMark {
    display: inline;
    color: #C00;
}
/* END Sidebar Modules */
/* --------------------------------------- */
/* BEGIN Wizard */
.bWizardBlock {
    border-bottom: 2px solid #747E96;
    margin-right: 11px;
}
.bWizardBlock .pbWizardTitle {
    background-position: bottom;
    background-repeat: repeat-x;
    font-weight: bold;
    color: white;
    padding: 2px 15px 6px 15px;
}
.report .bWizardBlock .pbWizardTitle {
    background-image: url(/static/image/bgReportsWizard.gif);
}
.campaign .bWizardBlock .pbWizardTitle {
    background-image: url(/static/image/bgCampaignsWizard.gif);
}

.bWizardBlock .pbWizardTitle .ptRightTitle{
    float: right;
}

.bWizardBlock .pbWizardHeader {
    margin-bottom: 6px;
}

.bWizardBlock .pbDescription {
    color: #333;
    font-size: 109%;
    clear: right;
}
.bWizardBlock .pbTopButtons {
    color: #333;
}
.bWizardBlock .pbTopButtons label {
    font-size: 109%;
}
.bWizardBlock .pbTopButtons #navsel {
    font-size: 91%;
}

.bWizardBlock .pbBody {
    background-color: #F3F3EC;
    background-image: url(/static/image/bgScanline.gif);
    background-repeat: repeat;
    padding: 6px 20px 2px 20px;
}

.bWizardBlock .quickLinks,
.bWizardBlock .pbWizardHelpLink {
    float: right;
    margin: 4px 0;
}

.bWizardBlock fieldset {
    background-color: white;
}

.bWizardBlock .pbWizardBody {
    clear: both;
}

/* Magic to make the div clear its floats.  X-Browser */
.bWizardBlock .pbWizardFooter,
.bWizardBlock .pbWizardHeader {
    overflow: hidden;
    height: 1%;
}

.bWizardBlock .pbTopButtons {
    float: right;
    margin: 2px 5px 2px 1em;
}

.bWizardBlock .pbBottomButtons {
    float: right;
    margin-right: 5px;
}

.bWizardBlock .bPageBlock {
    margin: 0;
}


.bWizardBlock .pbBody .bPageBlock,
.bWizardBlock .pbBody .bPageBlock .pbFooter,
.bWizardBlock .pbBody .bPageBlock .pbHeader{
    background: none;
    border: none;
}

.bWizardBlock .bPageBlock .pbTitle,
.bWizardBlock .bPageBlock .pbBody {
    background: none;
    padding: 0;
    margin: 0;
}

.bWizardBlock .bPageBlock .detailList tr td,
.bWizardBlock .bPageBlock .detailList tr th {
    border-bottom: none;
}

.bWizardBlock .bPageBlock .detailList .col02 {
    border-right: none;
    padding-right: 20px;
}

.bWizardBlock .bPageBlock .detailList .labelCol,
.bWizardBlock .bPageBlock .detailList .dataCol,
.bWizardBlock .bPageBlock .detailList .data2Col,
.bWizardBlock .bPageBlock .detailList .detailRow,
.bWizardBlock .bRelatedList .bPageBlock .pbBody,
.bWizardBlock .listReport .bPageBlock .pbBody {
    background-color: #F3F3EC;
}

/* Defaults: */
.bWizardBlock .pbWizardTitle,
.bWizardBlock .pbSubheader{
    background-color: black;
}

/* In a pageblock, these are black, in a wizard, these should
 * behave like subblocks TODO: polcari - link palette bg color with FG color*/
.bWizardBlock .pbHeader .pbTitle h2,
.bWizardBlock .pbHeader .pbTitle h3 {
    color: #FFF;
}
/* END Wizard */
/* ----------------------------------- */
/* BEGIN Lookup */
/* subjectSelectionPopup is also mixed in */

div.lookup,
div.invitee,
.popup {
    padding: 10px 10px 0 10px;
}

.popup .bPageBlock .labelCol{
    width: 30%;
}

.lookup .actionColumn {
    width: 1%;
}

.lookup .pBody {
    padding-left: 30px;
    color: black;
    font-weight: bold;
}

/* Don't need bold text in lookup body text or bottom padding */
.lookup .bDescription{
    font-size: 100%;
    font-weight: normal;
}
.lookup .bPageBlock,
.popup .bPageBlock {
    padding-right: 0;
    padding-bottom: 0;
    background-image: none;
    border-bottom-width: 2px;
    border-bottom-style: solid;
}

.lookup .bPageBlock .pbBody,
.lookup .bPageBlock .pbBottomButtons,
.popup .bPageBlock .pbBody,
.popup .bPageBlock .pbBottomButtons {
    margin-right: 0;
}
.lookup .bPageBlock .pbHeader,
.lookup .bPageBlock .pbFooter,
.popup .bPageBlock .pbHeader,
.popup .bPageBlock .pbFooter{
    display: none;
}
/* Specific for calendar invitee lookup */
.invitee .bPageTitle h1 {
    font-size: 93%;
}
.invitee .relatedListIcon {
    display: none;
}
.invitee .bPageBlock .pbTitle h3 {
    margin-left: 10px;
}

.lookup .footer {
    margin-top: 20px;
    border-top: 2px solid #D9D9D9;
    padding-top: 0.5em;
    text-align: center;
    color: #878787;
}

.lookup .content h1 {
    margin: 0.5em 0;
}
.lookup .bPageBlock .list .errorMsg {
    color: #C00;
    text-align: center;
    border-bottom: none;
}
/* Remove all bottom padding so there's less change a vertical scrollbar appears */
.lookup,
.lookup .pBody,
.lookup .bDescription {
    padding-bottom: 0;
}
.lookup #division,
.lookup #lksrch {
    margin: 0 1em;
}

/* New asset in lookup */
.newAssetLookupHeader .step {
    font-weight: bold;
    float: right;
}

.newAssetLookupHeader h2 {
    margin-bottom: 6px;
}

.newAssetLookupHeader p {
    margin: 0;
}

/* subjectSelectionPopup */
.subjectSelectionPopup h1 {
    margin: 0.5em;
}
body.subjectSelectionPopup div.choicesBox {
  width: 90%;
  padding: 0px;
  border-top-width: 5px;
  border-top-style: solid;
  margin-left: auto;
  margin-right: auto;
    background-color:#F3F3EC;
}
.subjectSelectionPopup .footer {
    margin: 20px auto 0 auto;
    border-top: 2px solid #D9D9D9;
    padding-top: 0.5em;
    text-align: center;
    color: #878787;
    font-size: 91%;
    width:90%;
}
.subjectSelectionPopup ul {
  width: 95%;
  padding: 0;
  margin: 0 auto;
  list-style: none;
}
.subjectSelectionPopup li {
  margin: 0;
  padding: 4px;
  border-top: 1px solid #E3DEB8;
  vertical-align : middle;
}
.subjectSelectionPopup li a {
     font-size: 91%;
}
.subjectSelectionPopup li.listItem0 {
  border-top: none;
}
.choicesBox br {
  display:none;
}
/* END Lookup */
/* ----------------------------------- */
/* BEGIN Specifc Page colors */

/* noCustomTab should be overridden by everything else */
.noCustomTab .primaryPalette,
.noCustomTab .secondaryPalette,
.setup .primaryPalette,
.setup .secondaryPalette {
    border-color: #747E96;
    background-color: #747E96;
}

.noCustomTab .tertiaryPalette,
.setup .tertiaryPalette {
    border-color: #8E9DBE;
    background-color: #8E9DBE;
}

/*todo: polcari - do we need this bhome ? */
body .bHome .primaryPalette,
.home .primaryPalette {
    background-color: #44A12C;
    border-color: #44A12C;
}

body .bHome .secondaryPalette,
.home .secondaryPalette {
    background-color: #638658;
    border-color: #638658;
}

body .bHome .tertiaryPalette,
.home .tertiaryPalette{
    background-color: #8DAE84;
    border-color: #8DAE84;
}
.home .tabNavigation {
    background-image: url(/static/image/tab/home_bg.gif);
}
.home .tab .currentTab {
    background-image:url(/static/image/tab/home_left.gif);
}
.home .tab .currentTab div {
    background-image:url(/static/image/tab/home_right.gif);
}
.home .bPageTitle .ptBody .greeting .pageType {
    font-size: 109%;
    font-weight: bold;
}
.home .bPageTitle .ptBody .greeting .pageDescription{
    font-size: 91%;
    font-weight: normal;
}
.home .bPageTitle .ptBody .greeting h1,
.home .bPageTitle .ptBody .greeting h2 {
    padding-left: 0px;
}

body .bAccount .primaryPalette,
.account .primaryPalette {
    background-color: #236FBD;
    border-color: #236FBD;
}

body .bAccount .secondaryPalette,
.searchResults .listAccount .secondaryPalette,
.account .secondaryPalette {
    background-color: #4579B5;
    border-color: #4579B5;
}

body .bAccount .tertiaryPalette,
.account .tertiaryPalette {
    background-color: #8A9EBE;
    border-color: #8A9EBE;
}
.account .tabNavigation {
    background-image:url(/static/image/tab/account_bg.gif);
}
.account .tab .currentTab {
    background-image:url(/static/image/tab/account_left.gif);
}
.account .tab .currentTab div {
    background-image:url(/static/image/tab/account_right.gif);
}

body .bContact .primaryPalette,
body .bContact .secondaryPalette,
.searchResults .listContact .secondaryPalette,
.contact .primaryPalette,
.contact .secondaryPalette {
    background-color: #56458C;
    border-color: #56458C;
}

body .bContact .tertiaryPalette,
.contact .tertiaryPalette {
    background-color: #8370C2;
    border-color: #8370C2;
}
.contact .tabNavigation {
    background-image:url(/static/image/tab/contact_bg.gif);
}
.contact .tab .currentTab {
    background-image:url(/static/image/tab/contact_left.gif);
}
.contact .tab .currentTab div {
    background-image:url(/static/image/tab/contact_right.gif);
}

body .bCase .primaryPalette,
body .bCase .secondaryPalette,
.searchResults .listCase .secondaryPalette,
.case .primaryPalette,
.case .secondaryPalette {
    background-color: #B7A752;
    border-color: #B7A752;
}

body .bCase .tertiaryPalette,
.case .tertiaryPalette {
    background-color: #C0BE72;
    border-color: #C0BE72;
}
.case .tabNavigation {
    background-image:url(/static/image/tab/case_bg.gif);
}
.case .tab .currentTab {
    background-image:url(/static/image/tab/case_left.gif);
}
.case .tab .currentTab div {
    background-image:url(/static/image/tab/case_right.gif);
}

body .bCampaign .primaryPalette,
body .bCampaign .secondaryPalette,
.searchResults .listCampaign .secondaryPalette,
.campaign .primaryPalette,
.campaign .secondaryPalette {
    background-color: #CC9933;
    border-color: #CC9933;
}

body .bCampaign .tertiaryPalette,
.campaign .tertiaryPalette {
    background-color: #E3B14F;
    border-color: #E3B14F;
}
.campaign .tabNavigation {
    background-image:url(/static/image/tab/campaign_bg.gif);
}
.campaign .tab .currentTab {
    background-image:url(/static/image/tab/campaign_left.gif);
}
.campaign .tab .currentTab div {
    background-image:url(/static/image/tab/campaign_right.gif);
}

body .bSolution .primaryPalette,
.solution .primaryPalette {
    background-color: #608B06;
    border-color: #608B06;
}

body .bSolution .secondaryPalette,
.searchResults .listSolution .secondaryPalette,
.solution .secondaryPalette {
    background-color: #567A00;
    border-color: #567A00;
}

body .bSolution .tertiaryPalette,
.solution .tertiaryPalette {
    background-color: #8A9744;
    border-color: #8A9744;
}
.solution .tabNavigation {
    background-image: url(/static/image/tab/solution_bg.gif);
}
.solution .tab .currentTab {
    background-image:url(/static/image/tab/solution_left.gif);
}
.solution .tab .currentTab div {
    background-image:url(/static/image/tab/solution_right.gif);
}

.bMyDashboard .bPageBlock {
    border-top-color: #7E1E14;
}
.bMyDashboard .bPageBlock .pbHeader .pbTitle {
    color:#7E1E14;
}
.bMyDashboard .bPageBlock .pbFooter,
.bMyDashboard .bPageBlock,
.bMyDashboard .bPageBlock .pbHeader .pbTitle .twisty {
    background-color:#7E1E14;
}
.bMyDashboard .bPageBlock .pbSubheader{
    background-color:#7E1E14;
}

body .bDashboard .primaryPalette,
body .bDashboard .secondaryPalette,
.searchResults .listDashboard .secondaryPalette,
.dashboard .primaryPalette,
.dashboard .secondaryPalette {
    background-color: #861614;
    border-color: #861614;
}

body .bDashboard .tertiaryPalette,
.dashboard .tertiaryPalette {
    background-color: #A55647;
    border-color: #A55647;
}
.dashboard .tabNavigation {
    background-image:url(/static/image/tab/dashboard_bg.gif);
}
.dashboard .tab .currentTab {
    background-image:url(/static/image/tab/dashboard_left.gif);
}
.dashboard .tab .currentTab div {
    background-image:url(/static/image/tab/dashboard_right.gif);
}

body .bLead .primaryPalette,
body .bLead .secondaryPalette,
.searchResults .listLead .secondaryPalette,
.lead .primaryPalette,
.lead .secondaryPalette {
    background-color: #E39321;
    border-color: #E39321;
}

body .bLead .tertiaryPalette,
.lead .tertiaryPalette {
    background-color: #EBAF59;
    border-color: #EBAF59;
}
.lead .tabNavigation {
    background-image: url(/static/image/tab/lead_bg.gif);
}
.lead .tab .currentTab {
    background-image:url(/static/image/tab/lead_left.gif);
}
.lead .tab .currentTab div {
    background-image:url(/static/image/tab/lead_right.gif);
}

body .bNote .primaryPalette,
.note .primaryPalette {
    background-color: #44A12C;
    border-color: #44A12C;
}

body .bNote .secondaryPalette,
.searchResults .listNote .secondaryPalette,
.note .secondaryPalette {
    background-color: #638658;
    border-color: #638658;
}

body .bOpportunity .primaryPalette,
body .bOpportunity .secondaryPalette,
.searchResults .listOpportunity .secondaryPalette,
body.oldForecast .listOpportunity .primaryPalette,
body.oldForecast .listOpportunity .secondaryPalette,
.opportunity .primaryPalette,
.opportunity .secondaryPalette {
    background-color: #D2AE1E;
    border-color: #D2AE1E;
}

body .bOpportunity .tertiaryPalette,
.opportunity .tertiaryPalette {
    background-color: #DDB929;
    border-color: #DDB929;
}
.opportunity .tabNavigation {
    background-image: url(/static/image/tab/opportunity_bg.gif) ;
}
.opportunity .tab .currentTab {
    background-image:url(/static/image/tab/opportunity_left.gif);
}
.opportunity .tab .currentTab div {
    background-image:url(/static/image/tab/opportunity_right.gif);
}

.bMyCalendar .primaryPalette,
.bMyCalendar .secondaryPalette,
.bMultiuserCalendar .primaryPalette,
.bMultiuserCalendar .secondaryPalette {
    background-color: #506749;
    border-color: #506749;
}

.bMultiuserCalendar  .pbButton, .bMultiuserCalendar  .pbDescription {
    vertical-align:middle;
}
.bMultiuserCalendar  .pbDescription {
    text-align:right;
}
.bMultiuserCalendar  .pbButton .iconBar {
    margin-top:0px;
    padding:1px 1px 1px 1px;
}
.bMultiuserCalendar  .pbButton .iconBar img {
    margin-right:4px;
    vertical-align:middle;
}
.bMultiuserCalendar  .pbButton .iconBar img.extra {
    margin-right:15px;
}
.bMultiuserCalendar  .pbButton .iconBar img.last {
    margin-right:24px;
}
.bMyCalendar .bPageBlock .pbBody .eventList{
    padding-top:10px;
}

body .bReport .primaryPalette,
body .bReport .secondaryPalette,
.searchResults .listReport .secondaryPalette,
.report .primaryPalette,
.report .secondaryPalette {
    background-color: #A55647;
    border-color: #A55647;
}

body .bReport .tertiaryPalette,
.report .tertiaryPalette {
    background-color: #AF756A;
    border-color: #AF756A;
}
.report .tabNavigation {
    background-image:url(/static/image/tab/report_bg.gif);
}
.report .tab .currentTab {
    background-image:url(/static/image/tab/report_left.gif);
}
.report .tab .currentTab div {
    background-image:url(/static/image/tab/report_right.gif);
}

body .bContract .primaryPalette,
body .bContract .secondaryPalette,
.searchResults .listContract .secondaryPalette,
.contract .primaryPalette,
.contract .secondaryPalette {
    background-color: #66895F;
    border-color: #66895F;
}

body .bContract .tertiaryPalette,
.contract .tertiaryPalette {
    background-color: #8CAB87;
    border-color: #8CAB87;
}
.contract .tabNavigation {
    background-image:url(/static/image/tab/contract_bg.gif);
}
.contract .tab .currentTab {
    background-image:url(/static/image/tab/contract_left.gif);
}
.contract .tab .currentTab div {
    color:#FFFFFF;
    background-image:url(/static/image/tab/contract_right.gif);
}

body .bDocument .primaryPalette,
body .bDocument .secondaryPalette,
.searchResults .listDocument .secondaryPalette,
.document .primaryPalette,
.document .secondaryPalette {
    background-color: #419BA6;
    border-color: #419BA6;
}
body .bDocument .tertiaryPalette,
.document .tertiaryPalette {
    background-color: #86B2B6;
    border-color: #86B2B6;
}
.document .tabNavigation {
    background-image:url(/static/image/tab/document_bg.gif);
}
.document .tab .currentTab {
    background-image:url(/static/image/tab/document_left.gif);
}
.document .tab .currentTab div {
    background-image:url(/static/image/tab/document_right.gif);
}

body .bOrder .primaryPalette,
body .bOrder .secondaryPalette,
.searchResults .listOrder .secondaryPalette,
.order .primaryPalette,
.order .secondaryPalette {
    background-color: #00655A;
    border-color: #00655A;
}
body .bOrder .tertiaryPalette,
.order .tertiaryPalette {
    background-color: #6AAFA2;
    border-color: #6AAFA2;
}
.order .tabNavigation {
    background-image:url(/static/image/tab/order_bg.gif);
}
.order .tab .currentTab {
    background-image:url(/static/image/tab/order_left.gif);
}
.order .tab .currentTab div {
    background-image:url(/static/image/tab/order_right.gif);
}


body .bForecast .primaryPalette,
body .bForecast .secondaryPalette,
.searchResults .listForecast .secondaryPalette,
.forecast .primaryPalette,
.forecast .secondaryPalette {
    background-color: #5889D6;
    border-color: #5889D6;
}

body .bForecast .tertiaryPalette,
.forecast .tertiaryPalette {
    background-color: #829DC9;
    border-color: #829DC9;
}
.forecast .tabNavigation {
    background-image:url(/static/image/tab/forecast_bg.gif);
}
.forecast .tab .currentTab {
    background-image:url(/static/image/tab/forecast_left.gif);
}
.forecast .tab .currentTab div {
    background-image:url(/static/image/tab/forecast_right.gif);
}

body .bProduct .primaryPalette,
body .bProduct .secondaryPalette,
.searchResults .listProduct .secondaryPalette,
.product .primaryPalette,
.product .secondaryPalette {
    background-color: #317992;
    border-color: #317992;
}

body .bProduct .tertiaryPalette,
.product .tertiaryPalette {
    background-color: #4D91B3;
    border-color: #4D91B3;
}
.product .tabNavigation {
    background-image: url(/static/image/tab/product_bg.gif);
}
.product .tab .currentTab {
    color:#FFFFFF;
    background-image:url(/static/image/tab/product_left.gif);
}
.product .tab .currentTab div {
    background-image:url(/static/image/tab/product_right.gif);
}

body .bPortal .primaryPalette,
body .bPortal .secondaryPalette,
.searchResults .listPortal .secondaryPalette,
.portal .primaryPalette,
.portal .secondaryPalette {
    background-color:  #993;
    border-color:  #993;
}

body .bPortal .tertiaryPalette,
.portal .tertiaryPalette {
    background-color: #ADB380;
    border-color: #ADB380;
}

.portal .tabNavigation {
    background-image: url(/static/image/tab/bg999933.gif);
}
.portal .tab .currentTab {
    background-image: url(/static/image/tab/left999933.gif);
}
.portal .tab .currentTab div {
    background-image: url(/static/image/tab/right999933.gif);
}
/*invoices */
body .bInvoice .primaryPalette,
body .bInvoice .secondaryPalette,
.searchResults .listInvoice .secondaryPalette,
.invoice .primaryPalette,
.invoice .secondaryPalette {
    background-color:  #66AA99;
    border-color:  #66AA99;
}

body .bInvoice .tertiaryPalette,
.invoice .tertiaryPalette {
    background-color: #39B698;
    border-color: #39B698;
}

.invoice .tabNavigation {
    background-image: url(/static/image/tab/bg66AA99.gif);
}
.invoice .tab .currentTab {
    background-image: url(/static/image/tab/left66AA99.gif);
}
.invoice .tab .currentTab div {
    background-image: url(/static/image/tab/right66AA99.gif);
}

/* blacktab */
.sysAdmin .primaryPalette{
    background-color: #000;
    border-color: #000;
}

.sysAdmin .tabNavigation {
    background-image: url(/static/image/tab/bg000000.gif);
}
.sysAdmin .tab .currentTab {
    background-image: url(/static/image/tab/left000000.gif);
}
.sysAdmin .tab .currentTab div {
    background-image: url(/static/image/tab/right000000.gif);
}

body .bLookup .primaryPalette,
.lookup .primaryPalette,
.searchLayoutExample .primaryPalette{
    background-color: #737E96;
    border-color: #737E96;
}

body .bLookup .secondaryPalette,
body .bLookup .tertiaryPalette,
.lookup .secondaryPalette,
.lookup .tertiaryPalette,
.searchLayoutExample .secondaryPalette
.searchLayoutExample .tertiaryPalette{
    background-color: #8E9DBE;
    border-color: #8E9DBE;
}

.bGeneratedReport .bPageBlock,
.report .csvSetup .bPageBlock {
    border-top-color:#A85548;
}

.bGeneratedReport .bPageBlock .pbFooter,
.bGeneratedReport .bPageBlock,
.bGeneratedReport .bPageBlock .pbHeader .pbTitle .twisty,
.report .csvSetup .bPageBlock,
.report .csvSetup .bPageBlock .pbFooter,
.report .csvSetup .bPageBlock .pbHeader .pbTitle .twisty  {
    background-color:#A85548;
}
.bGeneratedReport .bPageBlock .pbSubheader,
.report .csvSetup .bPageBlock .pbSubheader {
    background-color:#A85548;
}

/* END Specific page colors */
/* -------------------------------- */
/* BEGIN reports */

/* This is here because reports don't have rolodexes on their views */
.report .lbBody .bFilterView {
    margin-bottom: 0px;
}

.report .bFilterView {
    margin-bottom: 15px;
}

.bFilterReport h3 {
    text-align:left;
    font-size: 91%;
    font-weight:normal;
    padding: 8px 10px 0 0;
    display:block;
}
.bFilterReport {
    margin-left: 18px;
}
.reportParameters .row {
    margin-bottom: 15px;
}
.reportParameters .row tr {
    vertical-align: top;
}
.reportParameters .row td {
    padding-right: 10px;
}
.reportParameters label,
.reportParameters .label {
    font-size: 91%;
    display:block;
}
/*
 * Selects and text inputs all have quirks on how they're displayed;
 * therefore, we'll strip their top and bottom margins and align them all to the top.
 */
.bFilterReport select,
.bFilterReport input {
    margin-top: 0;
    margin-bottom: 0;
    vertical-align: top;
    font-size: 91%;
}
/* only these two buttons appear inside of bFilterReport. Add more as needed. */
.bFilterReport input.btn,
.bFilterReport input.btnDisabled {
    font-size: 80%;
}
/* This is to align the second "interval" select box of ReportParameterQuarter */
.reportParameters #timeInterval {
    vertical-align: bottom;
}
.bFilterReport .reportActions {
    white-space: nowrap;
    margin-bottom: 15px;
}

.bGeneratedReport .bPageBlock .pbHeader .pbTitle {
    color:#A85548;
    display:block;
}

.bGeneratedReport .bPageBlock .pbBody {
    padding:5px 20px 0px 20px;
}

.report .roleSelector {
    margin-bottom: 15px;
}
.report .roleSelector .drillDownPath,
.report .roleSelector .drillDownOptions {
    margin-left: 18px;
    font-weight: bold;
}
.report .roleSelector .drillDownPath a,
.report .roleSelector .drillDownOptions a {
    font-size: 109%;
}

.report .reportList .folderName {
  margin-bottom: 2px;
    padding-left: 3px;
    font-weight: bold;
    color: #fff;
}

.report .reportList .entryActions {
  margin-right: 1.2em;
  font-weight: bold;
}

.report .reportList .entryName {
  margin-right: 0.6em;
}

.report .reportList .entryDesc {
  margin-left: 0.6em;
}

.report .reportList .reportListFolder {
  padding: 5px 0;
}
.report .reportList .reportEntry {
    padding: 1px 0;
}
.bGeneratedReport .chartEditLinks {
    padding-bottom: 5px;
}
.bGeneratedReport .chartEditLinks a {
    padding: 0.25em;
}

/* Progress Indicator - BEGIN */
.progressIndicator {
    margin-left: 18px;
    margin-bottom: 15px;
    overflow: hidden;
}

.progressIndicator h2 {
    vertical-align: top;
    float: left;
}

.progressIndicator #status {
    width: 75%;
    vertical-align: top;
    font-size: 91%;
    padding-left: 1em;
    float: left;
}
/* Progress Indicator - END */

/*
 * Report Wizard Page-specific Things
 * ----------------------------------------
 * These are here for now to get the report wizards looking right until we can decide
 * where they should go in the grand scheme of things. These are listed in the order
 * of the steps for a matrix report.
 *
 * These should go into their respecive pages, but ReportWizard is messy.
 */

/* 1. Type Step */
.report .bWizardBlock .typeStep .reportTypeList {
    padding-bottom:15px;
    width:100%;
}

.report .bWizardBlock .typeStep .reportTypeList th,
.report .bWizardBlock .typeStep .reportTypeList td {
    padding:4px 2px 4px 5px;
    color:#333;
}

/* 2. Grouping Step */
.report .bWizardBlock .groupingStep  h3 {
    text-align: left;
    display: block;
}

.report .bWizardBlock .groupingStep  .text {
    font-size: 91%;
}

.report .bWizardBlock .groupingStep  .subtotalRow h3 {
    text-align: left;
    font-size: 91%;
    font-weight: normal;
    padding-top: 8px;
    display: block;
}

/* 4. Columns Step */
.report .bWizardBlock .columnsStep .selectReportColumns .action {
    text-align: right;
}
.report .bWizardBlock .columnsStep .selectReportColumns .categoryHeader {
    margin: .5em 0 0 0;
}

/* 5. Order Columns Step */
.report .bWizardBlock .orderColumnsStep .duelingListBox .selectBox .selectTitle {
     font-weight: bold;
     color: #333;
}

/* 6. Criteria Step */
.report .bWizardBlock .criteriaStep .bFilterReport th {
    font-size: 91%;
    font-weight: normal;
}
.report .bWizardBlock .criteriaStep .advancedSettings {
    overflow: hidden;
}
/* At some point, all the fiteredit styles should be merged. */
.report .bWizardBlock .criteriaStep .bPageBlock .textBox {
    font-size: 91%;
    margin: 0 1em;
}
.report .bWizardBlock .criteriaStep .bPageBlock .addRemoveControl {
    font-size: 91%;
}
.report .bWizardBlock .criteriaStep #reportCriteriaAdvancedHints {
    float: right;
    width: 66%;
}
.report .bWizardBlock .criteriaStep #toggleReportDetailsAndPickCurrency .toggleDetails {
    font-size: 91%;
    width: 33%;
}


/*
 * 7. Chart Step
 */
 /* TODO: Place holder for when we get comps and fully reskin this page */

.report .bPageTitle .ptHeader {
    background-color:#A85548;
    color:#DCDEE6;
}
.report .bPageTitle .ptHeader a{
    color:#DCDEE6;
    text-decoration:underline;
}
.report .bPageTitle .ptBody, .report .bPageTitle .ptSubheader {
    background-color:#A85548;
    color:#FFF;
}

/* END reports */

/* begin forecast - used on the forecast pages & on user-setup page (Quotas) */

.forecastListFilter {
    width:70%;
}

.opportunity .bPageBlock .pbHeader table.forecastListFilter {
    width:auto;
}
.opportunity .bPageBlock .pbHeader table.forecastListFilter input {
    margin-left: -4px;
    margin-top:1px;
}

.opportunity .bPageBlock .pbHeader table.forecastListFilter label {
    margin-left: -1em;
}

.forecastListFilter td,
.forecastListFilter th {
    padding:2px;
    white-space:nowrap;
    text-align: center;
}

.forecastListFilter td {
    padding:2px 2px 2px 6px;
}

.forecastListFilter th {
    padding:2px;
}

.forecast .forecastListFilter {
    margin-bottom: 10px;
}

/* begin old forecast */
.oldForecast .list .totalRow * {
    font-weight: bold;
}

.oldForecast h4 {
    margin-bottom: .5em;
}

/* END forecast */


/* EMM TODO  Check if necessary */
/* TODO: polcari - use 'dashboard' instead */
/* i believe .bComponentBlock can be replaced with .dashboard */
.bComponentBlock .bPageBlock {
    border-top-color: #7E1D14;
}
.bComponentBlock .bPageBlock .pbHeader .pbTitle {
    color:#7E1D14;
}
.bComponentBlock .bPageBlock .pbFooter,
.bComponentBlock .bPageBlock,
.bComponentBlock .bPageBlock .pbHeader .pbTitle .twisty {
    background-color:#7E1D14;
}
.bComponentBlock .bPageBlock .pbSubheader{
    background-color:#7E1D14;
}

.bComponentBlock .bPageBlock .pbBody {
    padding:5px 20px 0px 20px;
}


/* ---------- Multi-Select List ---------- */

/* Hide selected rows in the available block */
.multiSelectList .available .selected {
    display:none;
}


/* ---------- General Tree ---------- */
.treeNode .label {
    font-size: 109%;
    font-weight: bold;
}

.treeNode .actions,
.treeNode .actions a {
    margin-left: 4px;
    color: #666;
}

.treeNode .addChild,
.treeNode .addChild a {
    font-weight: bold;
    color: #666;
}

.treeNode .roleHighlight {
    font-weight: bold;
    background-color: #ddd;
}

.treeNode .roleUser {
    color: #22D;
}

.treeNode .roleUserNon {
    font-weight: bold;
    color: #666;
    font-size: 93%;
}

.treeNode .actions a {
    font-size: 93%;
}

.treeNode .actions a.roleAssign {
    color: #D22;
}


/* ---------- Multi-Select Tree ---------- */

.treeMultiSelect div {
    overflow: hidden;
}

.treeMultiSelect .pbTitle {
    float: left;
    width: 190px;
}

.treeMultiSelect .pbHeader {
    padding-top: 2px;
}

.treeMultiSelect .pbButton {
    float: left;
}

.treeMultiSelect .viewTypeSelect {
    float: right;
}

.treeMultiSelect .pbBottomButtons {
    padding-left: 190px;
    padding-top: 2px;
    clear: left;
}

.treeMultiSelect .tmsBlocks {
    width: 100%;
    float: left;
    clear: left;
}

.treeMultiSelect .tmsBlock {
    overflow: auto;
    border-width: 0px;
    margin: 0px;
    padding: 0px 0px 1px 3px;
}

.treeMultiSelect .tmsBlock.v {
    width: 50%;
}

.treeMultiSelect .tmsBlock .pbSubheader {
    font-size: 100%;
}

/* Hide unselected rows in the selections block */
.treeMultiSelect .tmsBlock.selections .selection {
    display: none;
}

/* Display selected rows in the selections block */
.treeMultiSelect .tmsBlock.selections .selection.selected {
    display: block;
}


/* ---------- Criteria Detail ---------- */

.criteriaDetail {
    font-family: 'Arial', 'Helvetica', sans-serif;
    color: #333;
}

/* Field */
.criteriaDetail .fld {
    font-size: 105%;
    font-family: "Courier New", 'Courier', mono;
    color: #0000FF;
}

/* Operator */
.criteriaDetail .op {
    font-size: 80%;
    color: red;
    text-transform: uppercase;
    padding: .5em;
}

/* Value(s) */
.criteriaDetail .val {
    color: green;
}

/* AND/OR */
.criteriaDetail .lop {
    font-size: 80%;
    color: black;
    text-transform: uppercase;
}

/* Parentheses */
.criteriaDetail .par {
    font-weight: bold;
}

/*used on the package editing - ProjectPage.generateAddToProjectUi()*/
.packageEdit .actionColumn {
    width: 50px;
}

/*end package editing */


/* Category Browser */
A.categoryNode {
   font-size: 10pt;
   font-family: Arial, Helvetica;
   font-weight: bold;
   color: #000000;
   text-decoration: underline;
   vertical-align:top;
}

A.categorySubNode {
   font-size: 9pt;
   font-family: Arial, Helvetica;
   font-weight: normal;
   color: #000000;
   text-decoration: underline;
   vertical-align:top;
}

table.solutionNode {
    margin-bottom:.81em;
    margin-top:.81em;
    width:100%;
    vertical-align:top;
}

table.solutionBrowser {
    margin-left:-16px;
    margin-right:-13px;
    width:100%;
}

table.solutionBrowser td{
    vertical-align:top;
}

table.solutionBrowser .lbHeader {
    display:inline;
}

table.solutionBrowser div.pagetitle {
  display:inline;
}

.solutionHeader{
    margin-left:-16px;
}
table.solutionBrowser td.solutionBrowserHeader img {
    vertical-align:middle;
    margin:2px;;
}
table.solutionBrowser td.solutionBrowserHeader h3{
    vertical-align:middle;
    margin-left:-10px;
}

table.solutionBrowser .solutionFolder{
    vertical-align:top;
}

.solutionSuggestionsPage .listSolution .pbTitle {
    width: 75%;
    white-space: nowrap;
}

/*Special styles for the 'solution search' related list header element */
.solutionSearchHeader .pbTitle {
  white-space: nowrap;
  width:1%;
  padding-right:1em;
}
.solutionSearchHeader .pbTitle .minWidth {
  display: none;
}


/* End Solution Browser Styles */


/*used in import wizards*/

.importWizardTitle {
    font-family: 'Arial','Helvetica', sans-serif;
    font-weight: normal;
    font-size: 1em;
    color: rgb(255, 255, 255);
    text-decoration: none;
}


/*start genericTable*/

/* DEPRECATED: do not use this style for new development */
table.genericTable {
    border: 1px solid #333;
    background-color:#F3F3EC;
    padding:0.2em;
    margin-top:0.5em;
    border-top: 3px solid #333;

}

.genericTable .numericalColumn {
    text-align: right;
}

/*end genericTable*/


/*start infoElement*/

.setup .infoBoxElement {
  border-bottom: 2px solid #747E96;
  height:99.5%;
  background-color:#FFFFCC;

}
.infoBoxElement table{
  background-color:#FFFFCC;
  padding-left:3px;
}

.infoBoxElement .infoRow .infoHeader {
    font-weight:bold;
    color:white;

}

.infoBoxElement .infoRow {
  background-color:#747E96;
  font-weight:bold;
  text-align:center;
}

.infoBoxElement .blackLine {
    font-weight:bold;
    background-color:#000;
}

.importCampaignMember .header {font-weight:bold;}

/*end infoElement*/

/* Misc */

.bEmailStatus {
    white-space: nowrap;
}

.bRowHilight {
    background-color: #FAEBD7;
}

/* End Misc */


/*start printable View*/

.printableView table.twoCol .fullWidth{
    width:100%;
}

.printableView td {
    vertical-align: top;
}


/*end pritable view*/

.wizBottom {
    border-top: 2px solid #9C0;
    background-color: #036;
    text-align: right;
    font-weight: bold;
    width: 100%;
    height: 23px;
}
.wizBottom a {
    margin-right: 25px;
    color: #FFF;
}

/* Prevent wrapping in the Mass Add Campaign Member wizards */
.massAddCampaignMemberWiz .detailList .labelCol {
    white-space: nowrap;
}




/* --------------------------------------------- */
/*BEGIN Setup Splash*/

.setupSplash {
    border-bottom: 2px solid;
    background: none;
}

.setupSplash .setupSplashBody .bodyDescription {
    text-align: left;
}

.setup .setupSplashBody {
    background-color:#F3F3EC;
    padding:1em;
}

.setup table.setupSplashBody{
    width: 100%;
}

.setup .setupSplash  .splashHeader{
    font-weight:bold;
    color:#fff;
    padding-left:1em;
}

.setupSplash .splashImage {
    text-align: center;
}

.setupSplashBody ul {
    margin-left: 0;
    padding-left: 0;
}

.setup .setupSplashBody div {
    margin-bottom:1em;
}


.setup .customAppSplash { background-image: url(/static/image/customApps.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .orgImportImage { background-image: url(/static/image/import_myorg.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .contactImportImage { background-image: url(/static/image/import_diagram.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .integrateSalesforce { background-image: url(/static/image/integrate_pic.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .offlineBriefcase { background-image: url(/static/image/offline_chart.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .avantGoBriefcase { background-image: url(/static/image/offline_pda_chart.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .outlookSplash { background-image: url(/static/image/integration.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .syncChartButton { background-image: url(/static/image/sync_chart_small.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .wirelessChart { background-image: url(/static/image/wireless_chart.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .wsdlchart { background-image: url(/static/image/wsdl_chart.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .officeSplash { background-image: url(/static/image/office_chart.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .leadImportImage { background-image: url(/static/image/import_leaddata.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.setup .dataExport { background-image: url(/static/image/weekly_report.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}
.home .campaignImportImage { background-image: url(/static/image/import_campaigndata.gif);
        width:400px;
        height:130px; background-repeat: no-repeat;}


.setup .setupSplashBody .alertBox .content {
    padding:5px 10px;
    background-color:#fff;
    font-size: 109%;
}
/*END  Setup Splash */
/* --------------------------------------------- */

/* Price editing */
.addEditPrice,
.addEditPrice table {
    width: 100%;
}
.addEditPrice th {
    border-bottom: 1px solid #000;
}

/* used to prevent the related list from wrapping */
body.choosePriceBook .pbHeader .pbTitle {
    white-space: nowrap;
    width: 75%;
}


.skiplink {
    position: absolute;
}

#validationStatus .validStyle {
        color:#090;
        
}


/* Legacy Styles - DO NOT USE THESE */
/*      These styles are here only so that legacy bold-ness in the label-files */
/* is respected in production.  Please use a <strong> for boldness and <em> for italics */
.bodyBold {
  font-weight: bold;
}
.bodyItalic {
  font-style: italic;
}
.greyBold,
.bodyBoldGrey {
  font-weight: bold;
}
.bodySmall {}
.bodySmallBold {
  font-weight: bold;
}
.bodySuperSmall {}
.bodyBoldWhite {
  font-weight:bold;
}
.redLargeBold {
  color: #900;
  font-weight:bold;
}
/* END Legacy Styles  - DO NOT USE THESE */
/* -------------- */
/* skin: Salesforce */
/* cssSheet: common */
/* postfix: ja */

/* common_ja.css */
body {
    font-size: 82%;
}

.tab a {
    font-size: 12px;
    line-height: 13px;
}

.tab .last a {
    font-size: 13px;
    line-height: 13px;
}

.navLinks a {
    font-size: 95%;
}

.mTreeSelection {
    font-size: 93%;
}


body .btn {
    font-size: 93%;
    font-weight: normal;
}

body,
input,
select,
h1, h2, h3, h4, h5, h6,
textarea,
.tabNavigation,
.miniTab,
.btn, .button,
.btnGo,
.btnImportant,
.btnSharing,
.btnDisabled,
.btnCancel,
.bPageTitle .ptBreadcrumb,
.bSubBlock .lbHeader ,
.mMessage .subheader h3, .mCustomLink .subheader h3,
.criteriaDetail ,
.criteriaDetail .fld,
A.categoryNode,
A.categorySubNode,
.importWizardTitle,
.tabOff,
A:link.tabOn,
.tabOn,
.subscribeNow,
A:link.tabOff,
.formulaButton,
.upgradeNow
{
    font-family:'MS UI Gothic', 'MS PGothic', 'Hiragino Kaku Gothic Pro', 'Osaka', 'Arial', 'Helvetica', sans-serif;
}


.btn, .button,
.btnGo,
.btnImportant,
.btnSharing,
.btnDisabled,
.btnCancel,
.formulaButton,
.subscribeNow,
.upgradeNow

{
    PADDING-TOP: 2px;
}

__change_search_display__
[% TAGS [- -] %]
<!-- Time-stamp: "[- timestamp -] [- user -]" last modified. -->
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

__app_base_class__
package [% app %];

use strict;
use warnings;
use FindBin;

use Catalyst qw/-Debug Dumper Static::Simple StackTrace Session Session::Store::File Session::State::Cookie ClassConfig Redirect ShanonUtil Errorcheck MenuMaker EmailMulti/;

our $VERSION = '0.01';

__PACKAGE__->config( name => '[% app %]',
                     home => "$FindBin::Bin/../",
                     root => "$FindBin::Bin/../root",
                     email => [qw/SMTP mail.shanon.co.jp/],# Qmail localhost / �Ȥ������Ǥ��ꤤ���ޤ�
                     ClassConfig => {
                                     ModelPrefix => ['ShanonDBI'],
                                     ViewPrefix => ['Admin']
                                 },
                     session => {
                                 storage => "/tmp/[% app %]/session",
                                 expires => '3600'
                             },
                     static => {
                                dirs => ['static', qr/^(image|images|css|js|upload)/],
                                ignore_extensions => []
                            },
                );

__PACKAGE__->setup;

sub auto : Private {
    my ( $self, $c ) = @_;

    # btn_new�����ꤵ��Ƥ���add�����Ф�
    if ($c->req->param('btn_new')) {
        $c->redirect('add');
    # btn_edit�����ꤵ��Ƥ���add�����Ф�
    } elsif ($c->req->param('btn_edit')) {
        $c->log->dumper('$c->req->args', \$c->req->args());
        my $param_1 = '';
        my $param_2 = '';
        foreach my $key (%{$c->req->params}) {
            if ($key =~ /(\w+)_D__[P|1]__D_id/) {
                my $path = '/' . $c->req->args->[0] . '/add/' . $c->req->params->{$key};
                $c->log->debug("redirect to : $path");
                $c->redirect($path);
            }
        }
        return 1;
    # btn_csvupload�����ꤵ��Ƥ���csvupload�����Ф�
    } elsif ($c->req->param('btn_csvupload')) {
        $c->redirect(join('/','',$c->action->namespace,'csvupload'));
    # btn_csvdownload�����ꤵ��Ƥ���csvdownload�����Ф�
    } elsif ($c->req->param('btn_csvdownload')) {
        $c->forward(join('/','',$c->action->namespace,'csvdownload'));
    }
    
    return 1;
}

sub default : Private {
    my ( $self, $c ) = @_;

    $c->redirect('/work/list');
}

sub end : Private {
    my ( $self, $c ) = @_;

    # ���顼�����ä��Ȥ���
    if (scalar @{$c->error}) {
        [% app %]::Model::ShanonDBI->dbi_rollback();
    # ���顼���ʤ��ä��Ȥ���commit���Ƥ��
    } else {
        [% app %]::Model::ShanonDBI->dbi_commit();
    }

    # Forward to View unless response body is already defined
    $c->forward( $c->stash->{next_view} ) if defined $c->stash->{next_view};
    $c->forward( 'View::Admin' ) unless $c->response->body;
}

1;

__view_base_class__
package [% base_class %];

use strict;
use base 'Catalyst::View::ShanonHTML';
use CGI qw/:form/;

####################################################################################################
# ���̤�ɽ��ľ���˸ƤФ��
####################################################################################################
__PACKAGE__->add_trigger(publish_before_parse_form_header => \&publish_before_parse_form_header);
sub publish_before_parse_form_header{
    my($self,$c,$opt) = @_;

    # Salesforce �б�
    $c->response->header('P3P' => 'CP="STE TAI SAM"');

    # ɽ����������
    $opt->{'style_main'} = $c->session->{'style_main'} || 'contract';

    # ��˥塼�ե�����μ�����
    #my($menu) = do sprintf("%s/menu/base.menu", $c->config->{'root'});
    #die "$@" if($@);
    
    # ��˥塼�κ���
    #$menu = $c->session->{'menu'} if($c->session->{'menu'});
    #$c->CreateMenu($menu, {
    #        1 => {type => 'ullistyle', options => 'a'},
    #        2 => {type => 'ullistyle', options => 'n,a,na'}
    #    }
    #);

    # �������ܤΥ�˥塼������
    #$opt->{"menu1"} = $c->getMenu(1);
    #$opt->{"menu2"} = $c->getMenu(2);

    # ��˥塼����
    my $hash;
    $hash->{'1'}->{name} = '�е�';
    $hash->{'1'}->{url} = '/work/list';
    $hash->{'2'}->{name} = '����';
    $hash->{'2'}->{url} = '/group/list';
    $hash->{'3'}->{name} = '�Ұ�';
    $hash->{'3'}->{url} = '/user/list';
    
    # ���˥塼
    $opt->{"menu1"} = "<tr>\n";
    my $i = 0;
    my $I = scalar(values %{$hash});
    foreach my $item (values %{$hash}) {
        my $class = "";
        $i++;
        if ($i == $I) {
            $class .= "last ";
        }
        $opt->{"menu1"} .= 
          sprintf(qq!<td class="%s" nowrap="nowrap"><div><a href="%s">%s</a></div></td>\n!, 
            $class,
            $item->{url}, 
            $item->{name}
          );
    }
    $opt->{"menu1"} .= "</tr>\n";
    
    # ���˥塼
    $opt->{"menu2"} = 
      sprintf(qq!<li><a href="/%s/list">����</a></lit>\n!, 
        $c->action()->namespace()
      );
    $opt->{"menu2"} .= 
      sprintf(qq!<li><a href="/%s/add">�����ɲ�</a></lit>\n!, 
        $c->action()->namespace()
      );
}

###########################################################
# �������᥽�åɡ�
# �ǡ�����¤���Ϥ��Ȥ�����˥ơ��֥����
# ��¤Ū�ˤϢ��ΤȤ���
# [[{value => ''}],
#  [{value => ''}]]
###########################################################
sub html_create_table {
    my($self,$c,$table, %FORM) = @_;
    no warnings;
    my($line);
    if(ref $table eq 'ARRAY' and @{$table}){
        for (my($i) = 0; $i < @{$table}; $i++) {
            next unless $table->[$i];
            if ($i == 0) {
                $line .= sprintf(" <tr class=\"headerRow\">\n%s </tr>\n",
                                 join('', map(sprintf(qq[  <th class="">%s</td>\n],
                                                      $self->blank($_->{'value'}) ? '&nbsp;' : $_->{'value'}
                                                  ),
                                              @{$table->[$i]})));
            } else {
                $line .= sprintf(" <tr class=\"even first\" onmouseout=\"if (typeof(hiOff) != 'undefined'){hiOff(this);}\" onfocus=\"if (typeof(hiOn) != 'undefined'){hiOn(this);}\" onblur=\"if (typeof(hiOff) != 'undefined'){hiOff(this);}\" onmouseover=\"if (typeof(hiOn) != 'undefined'){hiOn(this);}\">\n  <!-- ListRow -->\n%s </tr>\n",
                                 join('', map(sprintf(qq[  <td class="">%s</td>\n],
                                                      $self->blank($_->{'value'}) ? '&nbsp;' : $_->{'value'}),
                                              @{$table->[$i]})));
            }
        }
    }
    $FORM{'table'} = $line;
    $FORM{'width'} = sprintf(' width="%s"',$FORM{'width'}) if(defined($FORM{'width'}));
    # �ʥӥ��������
    $FORM{page_num} = $self->get_clc($c)->class_stash->{'page_num'};
    $FORM{page_list} = $self->get_clc($c)->class_stash->{'page_list'};
    $FORM{view_range} = $self->get_clc($c)->class_stash->{navigate};
    $self->call_trigger('html_create_table_before_parse_variable', $c,\%FORM);
    return $self->parse_variable($self->read_file($c, $self->get_table_file($c)), %FORM);
}

####################################################################################################
# ������ paser_form
####################################################################################################
sub search_parse_form {
    my ($self, $c, $data, $opt) = @_;
    foreach my $p (@{$self->get_clc($c)->schema}) {
        ##### ���դξ��ϸ����ե������read-only��
        if ($p->{'form'}->{'type'} eq 'date' || $p->{sql}->{type} =~ /timestamp/) {
            $p->{'form'}->{'readOnly'} = 1;
        } elsif ($p->{'form'}->{'type'} eq 'text' || 
                 $p->{'form'}->{'type'} eq 'textarea' ||
                 $p->{'form'}->{'type'} eq 'html' || 
                 $p->{'form'}->{'type'} eq 'file' || 
                 $p->{'form'}->{'type'} eq 'hidden')
            {
            $p->{'form'}->{'type'} = 'text';
            $p->{'form'}->{'size'} = '25';
        }
    }
    $self->SUPER::parse_form($c, $data, $opt);
}

####################################################################################################
# �������᥽�åɡ�
# �����ե��������
####################################################################################################
sub list_search {
    my($self, $c, @array) = @_;

    # �ǡ�������
    my $data;
    $data = $self->get_clc($c)->req_params();
    $data = {} unless($data);

    my %data;
    # �����ե�����Υ���ब���ꤵ��Ƥ��ʤ��Ȥ�
    unless (@array) {
        foreach my $type (qw!default visible!) {
            # ����������ܤ���ꤹ�� ---------------------
            foreach my $p (@{$self->get_clc($c)->schema}) {
                next if($p->{'findrow'} ne $type || defined $p->{'temporary'});
                push(@array, $p->{name});
            }
            # �ե�������� ---------------------------------
            $c->stash->{list_search_now} = 1;
            $self->search_parse_form($c, $data, {-select_prop => \@array});
            delete $c->stash->{list_search_now};
            my(%FORM) = (ref $c->stash->{parseform_result} eq 'HASH') ? %{$c->stash->{parseform_result}} : ();
            my @list;
            foreach my $p (@{$self->get_clc($c)->schema}) {
                if ($p->{'findrow'}) {
                    if ($p->{'findrow'} eq $type && !defined $p->{'temporary'}) {
                        push(@list, 
                            sprintf(qq!<td class="labelCol">%s</td><td class="dataCol col02">%s</td>!, 
                                $p->{'desc'}, $FORM{$p->{'name'}})
                        );
                    }
                }
            }
            # ����ΤȤ��ν��� ---------------------------
            if ((scalar @list) % 2 == 1) {
                push(@list, qq!<td class="labelCol">&nbsp;</td><td class="dataCol col02">&nbsp;</td>!);
            }
            # �ơ��֥������ -----------------------------
            for (my $i = 0; $i < scalar @list; $i += 2) {
                $data{$type} .= sprintf(qq!<tr>\n\t%s%s</tr>\n!, $list[$i], $list[$i + 1]);
            }
            # $c->stash->{parseform_result} ������ -----
            undef $c->stash->{parseform_result};
            $self->call_trigger('list_search_after_parse_form', $c,\%FORM);
        }
    }
    
    #-----------------------------------------------------
    # �ǥե���Ȥǥܥ����ɽ������
    $data{submit_search} = submit(-name=>"submit_search",-value=>'����');
    $self->call_trigger('list_search_after_makebutton', $c,\%data);
    $self->get_clc($c)->class_stash->{search} = $self->parse_variable($self->read_file($c, $self->get_search_file($c)), %data);
}

####################################################################################################
# �������᥽�åɡ�
# $c->stash()->{'body_subtitle'} ���������Ƥ����餽����֤�
# �������Ƥ��ʤ��ä��� '�ۡ���' ���֤�
# �����ȥ���������
####################################################################################################
sub get_body_subtitle : Private {
    my($self, $c) = @_;
    
    my $action = $c->action()->{'name'};
    
    if ($action eq 'default' || $action eq 'list') {
        return '����';
    } elsif ($action eq 'add') {
        if (scalar @{$c->req->args()} > 0) {
            return '�Խ�';
        } else {
            return '�ɲ�';
        }
    } elsif ($action eq 'view') {
        return '�ܺ�';
    } elsif ($action eq 'disable') {
        return '���';
    } elsif ($action eq 'csvupload') {
        return 'CSV���åץ���';
    } else {
        return '��';
    }
}

1;

__view_class__
package [% class %];

use strict;
use base '[% parent %]';

1;
