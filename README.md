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
   {:mix_eunit, "~> 0.1.1"}]
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

* --verbose/-v - Run eunit with the :verbose option.
* --cover/-c - Run cover during the tests. Cover data will be produced in
your `test_coverage` `output` directory. You can set it in your project section
like this: `test_coverage: [output: "_build/#{Mix.env}/cover"]`

Test search path:
-----------------

All ".erl" files in the src and test directories are considered.

