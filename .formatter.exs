locals_without_parens = [
  embeds_one_of: 2,
  option: 2,
  option: 3
]

[
  import_deps: [:ecto],
  locals_without_parens: locals_without_parens,
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  export: [locals_without_parens: locals_without_parens]
]
