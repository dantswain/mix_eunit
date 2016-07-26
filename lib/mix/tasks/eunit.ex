defmodule Mix.Tasks.Eunit do
  use Mix.Task
  @recursive true

  @preferred_cli_env :test

  @shortdoc "Compile and run eunit tests"

  @moduledoc """
  Run eunit tests for a project.

  This task compiles the project and its tests in the test environment,
  then runs eunit tests.  This task works recursively in umbrella
  projects.


  Command line options:
  ---------------------

  A list of patterns to match for test files can be supplied:

  ```
  mix eunit foo* bar*
  ```

  The runner automatically adds \".erl\" to the patterns.

  The following command line switch is also available:

  * --verbose/-v - Run eunit with the :verbose option.
  * `--no-start` - do not start applications after compilation

  Test search path:
  -----------------

  All \".erl\" files in the src and test directories are considered.

  """

  def run(args) do
    options = parse_options(args)

    # add test directory to compile paths and add
    # compiler options for test
    post_config = eunit_post_config(Mix.Project.config)
    modify_project_config(post_config)

    # make sure mix will let us run compile
    ensure_compile
    Mix.Task.run "compile"

    # start the application
    Mix.shell.print_app
    Mix.Task.run "app.start", args

    # run the actual tests
    if(options[:cover], do: cover_start())
    test_modules(post_config[:erlc_paths], options[:patterns])
    |> Enum.map(&module_name_from_path/1)
    |> Enum.drop_while(fn(m) ->
      tests_pass?(m, options[:eunit_opts] ++ post_config[:eunit_opts]) end)
    if(options[:cover], do: cover_analyse())
  end

  defp parse_options(args) do
    {switches,
     argv,
     _errors} = OptionParser.parse(args,
                                  switches: [verbose: :boolean,
                                             cover: :boolean],
                                  aliases: [v: :verbose,
                                            c: :cover])

    patterns = case argv do
                 [] -> ["*"]
                 p -> p
               end

    eunit_opts = case switches[:verbose] do
                   true -> [:verbose]
                   _ -> []
                 end

    %{eunit_opts: eunit_opts, patterns: patterns, cover: switches[:cover]}
  end

  defp eunit_post_config(existing_config) do
    [erlc_paths: existing_config[:erlc_paths] ++ ["test"],
     erlc_options: existing_config[:erlc_options] ++ [{:d, :TEST}],
     eunit_opts: existing_config[:eunit_opts]]
  end

  defp modify_project_config(post_config) do
    # note - we have to grab build_path because
    # Mix.Project.push resets the build path
    build_path = Mix.Project.build_path
    |> Path.split
    |> Enum.map(fn(p) -> filter_replace(p, "dev", "eunit") end)
    |> Path.join

    %{name: name, file: file} = Mix.Project.pop
    Mix.ProjectStack.post_config(Keyword.merge(post_config,
                                               [build_path: build_path]))
    Mix.Project.push name, file
  end

  defp filter_replace(x, x, r) do
    r
  end
  defp filter_replace(x, _y, _r) do
    x
  end

  defp ensure_compile do
    # we have to reenable compile and all of its
    # child tasks (compile.erlang, compile.elixir, etc)
    Mix.Task.reenable("compile")
    Enum.each(compilers, &Mix.Task.reenable/1)
  end

  defp compilers do
    Mix.Task.all_modules
    |> Enum.map(&Mix.Task.task_name/1)
    |> Enum.filter(fn(t) -> match?("compile." <> _, t) end)
  end

  defp test_modules(directories, patterns) do
    all_modules = erlang_source_files(directories, patterns)
    |> Enum.map(&module_name_from_path/1)
    |> Enum.uniq

    remove_test_duplicates(all_modules, all_modules, [])
  end

  defp erlang_source_files(directories, patterns) do
    Enum.map(patterns, fn(p) ->
               Mix.Utils.extract_files(directories, p <> ".erl")
             end)
    |> Enum.concat
    |> Enum.uniq
  end

  defp module_name_from_path(p) do
    Path.basename(p, ".erl") |> String.to_atom
  end

  defp remove_test_duplicates([], _all_module_names, accum) do
    accum
  end
  defp remove_test_duplicates([module | rest], all_module_names, accum) do
    module = Atom.to_string(module)
    if tests_module?(module) &&
      Enum.member?(all_module_names, without_test_suffix(module)) do
      remove_test_duplicates(rest, all_module_names, accum)
    else
      remove_test_duplicates(rest, all_module_names, [module | accum])
    end
  end

  defp tests_module?(module_name) do
    String.match?(module_name, ~r/_tests$/)
  end

  defp without_test_suffix(module_name) do
    module_name
    |> String.replace(~r/_tests$/, "")
    |> String.to_atom
  end

  defp tests_pass?(module, eunit_opts) do
    IO.puts("Running eunit tests in #{module}:")
    :ok == :eunit.test(module, eunit_opts)
  end

  defp cover_start() do
    :cover.compile_beam_directory(String.to_charlist(Mix.Project.compile_path))
  end

  defp cover_analyse() do
    dir = Mix.Project.config[:test_coverage][:output]
    File.mkdir_p(dir)
    :cover.analyse_to_file([:html, outdir: dir])
  end
end
