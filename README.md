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
   {:mix_eunit, "~> 0.1.0"}]
end
```

Then

```
mix deps.get
mix deps.compile
mix eunit
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

Test search path:
-----------------

All ".erl" files in the src and test directories are considered.

