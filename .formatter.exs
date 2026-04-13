[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:ecto],
  line_length: 150,
  export: [
    locals_without_parens: [
      ecto_context: 2
    ]
  ]
]
