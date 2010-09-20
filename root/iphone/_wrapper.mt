? my ($content) = @_;
<html>
  <head>
    <meta name="viewport" content="width=320, user-scalable=no" />
    <style type="text/css">
body {
    font-family: sans-serif;
    margin: 0;
    padding: 0;
}
div.thread {
  border: 1px solid #666;
  -webkit-border-radius: 5px;
  margin: 10px auto;
  width: 300px;
  padding: 5px;
  overflow: hidden;
}
div.thumbnail {
  text-align: center;
  overflow: hidden;
}
img {
    margin: 10px;
    max-width: 280px;
}
blockquote {
  /* margin: 5px; */
  margin: 0;
  padding: 10px;
  border-top: 1px solid #999;
  /* -webkit-border-radius: 5px; */
  /* width: 260px; */
  overflow: hidden;
}
table, tbody, tr, td {
    padding: 0;
    margin: 0;
}
td {
    color: #AAA;
}
td blockquote {
    color: #000;
}
    </style>
  </head>
  <body>
?= $content
  </body>
</html>
