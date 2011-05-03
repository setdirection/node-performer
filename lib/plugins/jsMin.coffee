{parser, uglify} = require 'uglify-js'

exports['application/javascript'] = (req, res, content, next) ->
  ast = parser.parse(content)   # parse code and get the initial AST
  ast = uglify.ast_mangle(ast)  # get a new AST with mangled names
  ast = uglify.ast_squeeze(ast) # get an AST with compression optimizations
  next uglify.gen_code(ast)
