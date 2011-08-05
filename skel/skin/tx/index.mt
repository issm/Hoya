: cascade _base


: around title -> {
: #### タイトル オーバライド ここから ####
<: $ACTION_NAME :> -
: #### タイトル オーバライド ここまで ####
: }



: around content -> {
: #### #content オーバライド ここから ####
<h1><: $conf.PROJECT_NAME :></h1>

<p>Hello, world.</p>

: #### #content オーバライド ここまで ####
: }

