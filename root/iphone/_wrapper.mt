? my ($content) = @_;
<html>
  <head>
    <meta name="viewport" content="width=320" />
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
  /* padding: 5px; */
  width: 300px;
  padding: 5px;
}
div.thumbnail {
  text-align: center;
}
img {
    margin: 10px;
}
blockquote {
  /* margin: 5px; */
  margin: 0;
  padding: 10px;
  border-top: 1px solid #999;
  /* -webkit-border-radius: 5px; */
  /* width: 310px; */
  width: 270px;
  overflow: auto;
}
table, tbody, tr, td {
    padding: 0;
    margin: 0;
    width: 100%;
}
    </style>
  </head>
  <body>
?= $content
  </body>
</html>
