? extends '_base';


? block title => sub {
? #### タイトル オーバライド ここから ####
<?=$var->{TITLE};?>
? #### タイトル オーバライド ここまで ####
? }



? block content => sub {
? #### #content オーバライド ここから ####


hi.



? #### #content オーバライド ここまで ####
? }

