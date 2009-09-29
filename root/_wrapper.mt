? my ($content, %params) = @_;
<html>
  <head>
    <title>Modoi<?= $params{title} ? " - $params{title}" : '' ?></title>
    <link rel="stylesheet" type="text/css" href="/css/futaba.css" />
  </head>
  <body>
    <h1>Modoi<?= $params{title} ? " - $params{title}" : '' ?></h1>
?= $content
  </body>
</html>
