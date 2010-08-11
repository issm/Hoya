<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
          "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
  <base href="<?= $conf->{URL_BASE}; ?>" />
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title>
? block title => sub {
? }
<?= $var->{TITLE} || $conf->{WEBSITE_NAME} || $conf->{PROJECT_NAME}; ?>
  </title>

? # css
? for my $css (@{$var->{CSS_IMPORT}}) {
  <link rel="stylesheet" type="text/css" href="<?= $css; ?>" charset="utf-8" />
? }

? # javascript
  <script type="text/javascript" src="js/lib/jquery-1.4.2.min.js" charset="utf-8"></script>
? for my $js (@{$var->{JS_IMPORT}}) {
  <script type="text/javascript" src="<?= $js; ?>" charset="utf-8"></script>
? }

? # for IE
? unless ($conf->{PAGE}{DISABLE_IE_SPECIFIC}) {
?   for my $ie (reverse(6..9, '')) {
  <!--[if IE <?= $ie; ?> ]>
?     # css for IE
?     for my $css (@{$var->{CSS_IMPORT_IE}{"ie$ie"}}) {
  <link rel="stylesheet" type="text/css" href="<?= $css; ?>" charset="utf-8" />
?     }
?     # javascript for IE
?     for my $js (@{$var->{JS_IMPORT_IE}{"ie$ie"}}) {
  <script type="text/javascript" src="<?= $js; ?>" charset="utf-8"></script>
?     }
  <![endif]-->
?   }
? }  # end of: unless ($conf->{PAGE}{DISABLE_IE_SPECIFIC}) {

</head>
<body>
<!-- #body-wrapper -->
<div id="body-wrapper">




<div id="head">
? block head => sub {
? #### #head ここから ####



? #### #head ここまで ####
? }
</div>


<div id="content">
? block content => sub {
? #### #content ここから ####



? #### #content ここまで ####
? }
</div>



<div id="foot">
? block foot => sub {
? #### #foot ここから ####



? #### #foot ここまで ####
? }
</div>



</div>
<!-- /#body-wrapper -->
</body>
</html>
