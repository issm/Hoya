<html>
<head>
  <base href="<?= $conf->{URL_BASE}; ?>docs/" />
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <title></title>

  <style type="text/css">
<?= encoded_string $css; ?>
  </style>
</head>
<body>
<div id="body-wrapper">

<div id="head">
  <h1><a href=""><?= $conf->{PROJECT_NAME}; ?> / docs</a></h1>
</div>

<div id="content">

? unless ($notfound) {
?   #
?   # データが存在する場合
?   #
<?= encoded_string $html; ?>

? # <form action="<?= $URL; ?>" method="post">
? #   <textarea name="data"
? #             rows="30"
? #             ><?= $raw_data; ?></textarea>
? # 
? #   <div>
? #     <input type="submit"
? #            name="command:update"
? #            value="更新する"
? #            />
? #   </div>
? # 
? #   <input type="hidden" name="__csrf_token" value="<?= $csrf_token; ?>" />
? # </form>

? } else {
?   #
?   # データが存在しない場合
?   #
<pre><?= $URL_UNESCAPED; ?></pre>
<p>ページがないよ．</p>

<form action="<?= $URL; ?>" method="post">
  <div>
    <input type="submit"
           name="command:create_page"
           value="ページを新しく作成する"
           />
  </div>

  <input type="hidden" name="__csrf_token" value="<?= $csrf_token; ?>" />
</form>
? }

</div>

<div id="foot">
#foot
</div>

</div>
</body>
</html>
