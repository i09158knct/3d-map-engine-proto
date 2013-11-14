fs   = require 'fs'

dir = process.argv[2]
files = fs.readdirSync(dir).filter (file) ->
  [
    /^\.DS_Store/
    /^_/
    /^css$/
    /^data$/
    /^img$/
    /^js$/
    /^index\.html$/
  ].every (pattern) ->
    !file.match(pattern)

console.log([
  """
  <!DOCTYPE html>
  <html>
  <head><meta charset="utf-8">
    <title>Programs</title>
  </head>
  <body>
  <h1>Programs</h1>
  <ul>
  """

  files.map((filename) ->
    "<li><a href=\"#{filename}\">#{filename}</li>"
  ).join('\n')

  """
  </ul>
  </body>
  </html>
  """
].join('\n'))
