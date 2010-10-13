? extends '_base';


? block title => sub {
? #### タイトル オーバライド ここから ####
<?= $ACTION_NAME; ?> -
? #### タイトル オーバライド ここまで ####
? }



? block content => sub {
? #### #content オーバライド ここから ####
<h1><?= $conf->{PROJECT_NAME}; ?></h1>

<p>Hello, world.</p>

? #### #content オーバライド ここまで ####
? }

