MixEunit
========

A mix task to execute eunit tests.

* Works in umbrella projects.
* Tests can be in the module or in the test directory.
* Allows the user to provide a list of patterns for tests to run.

Example
```
mix eunit # run all the tests
mix eunit --verbose "foo*" "*_test" # verbose run foo*.erl and *_test.erl
```

Installation
------------

Add to your `mix.exs` deps:

```elixir
def deps
  [#... existing deps,
   {:mix_eunit, "~> 0.2"}]
end
```

Then

```
mix deps.get
mix deps.compile
mix eunit
```

To make the `eunit` task run in the `:test` environment, add the following
to the `project` section of you mix file:

```elixir
def project
  [#... existing project settings,
   preferred_cli_env: [eunit: :test]
  ]
end
```

Command line options:
---------------------

A list of patterns to match for test files can be supplied:

```
mix eunit foo* bar*
```

The runner automatically adds ".erl" to the patterns.

The following command line switch is also available:

  * `--verbose`, `-v` - run eunit with the :verbose option
  * `--cover`, `-c` - create a coverage report after running the tests
  * `--profile`, `-p` - show a list of the 10 slowest tests
  * `--start` - start applications after compilation
  * `--no-color` - disable color output
  * `--force` - force compilation regardless of compilation times
  * `--no-compile` - do not compile even if files require compilation
  * `--no-archives-check` - do not check archives
  * `--no-deps-check` - do not check dependencies
  * `--no-elixir-version-check` - do not check Elixir version

Project Settings:
-----------------

The following `mix.exs` project settings affect the behavior of `mix eunit`.

```elixir
def project
  [
    # existing project settings

    # run the `eunit` task in the `:test` environment
    preferred_cli_env: [eunit: :test],

    # set the output directory for `mix eunit --cover` reports
    #   the default is `./cover` (same as `mix test --cover`)
    test_coverage: [output: "_build/#{Mix.env}/cover"]

    # set switches that affect every invocation of the eunit task
    eunit: [
      verbose: false,
      cover: true,
      profile: true,
      start: true,
      color: false
    ]
  ]
end
```

Cover:
------

Note that `mix eunit --cover` and `mix test --cover` will not in
general cover the same source code with tests and therefore will
typically generate two independent coverage reports.  There may be
some overlap if your eunit and ExUnit tests cover some of the same
code.

By default, `mix eunit --cover` produces coverage reports in HTML
format in the same `cover` directory that `mix test --cover` does.
You can override the `mix eunit --cover` output directory in your
`mix.exs` file as described above.

Test search path:
-----------------

All ".erl" files in the src and test directories are considered.

