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

  The following command line switches are also available:

  * `--verbose`, `-v`   - Run eunit with the :verbose option.
  * `--cover`, `-c`     - Create a coverage report after running the tests.
  * `--profile`, `-p`   - Show a list of the 10 slowest tests.
  * `--no-color`        - Disable color output.

  Test search path:
  -----------------

  All \".erl\" files in the src and test directories are considered.

  """

  @cover [output: "cover", tool: Mix.Tasks.Test.Cover]

  def run(args) do
    options = parse_options(args)
    project = Mix.Project.config

    # add test directory to compile paths and add
    # compiler options for test
    post_config = eunit_post_config(project)
    modify_project_config(post_config)

    # make sure mix will let us run compile
    ensure_compile
    Mix.Task.run "compile"

    # start cover
    cover =
      if options[:cover] do
        compile_path = Mix.Project.compile_path(project)
        cover = Keyword.merge(@cover, project[:test_coverage] || [])
        cover[:tool].start(compile_path, cover)
      end

    # run the actual tests
    modules =
      test_modules(post_config[:erlc_paths], options[:patterns])
      |> Enum.map(&module_name_from_path/1)
      |> Enum.map(fn m -> {:module, m} end)

    eunit_opts = get_eunit_opts(options, post_config)
    case :eunit.test(modules, eunit_opts) do
      :error -> Mix.raise "mix eunit failed"
      :ok -> :ok
    end

    cover && cover.()
  end

  defp parse_options(args) do
    {switches,
     argv,
     _errors} = OptionParser.parse(args,
                                  switches: [verbose: :boolean,
                                             profile: :boolean,
                                             no_color: :boolean,
                                             cover: :boolean],
                                  aliases: [v: :verbose,
                                            p: :profile,
                                            c: :cover])

    patterns = case argv do
                 [] -> ["*"]
                 p -> p
               end

    eunit_opts = case switches[:verbose] do
                   true -> [:verbose]
                   _ -> []
                 end

    %{eunit_opts: eunit_opts,
      patterns: patterns,
      profile: switches[:profile],
      nocolor: switches[:no_color],
      cover: switches[:cover]}
  end

  defp eunit_post_config(existing_config) do
    [erlc_paths: existing_config[:erlc_paths] ++ ["test"],
     erlc_options: existing_config[:erlc_options] ++ [{:d, :TEST}],
     eunit_opts: existing_config[:eunit_opts] || []]
  end

  defp get_eunit_opts(options, post_config) do
    eunit_opts = options[:eunit_opts] ++ post_config[:eunit_opts]
    maybe_add_formatter(eunit_opts, options[:profile], options[:nocolor])
  end

  defp maybe_add_formatter(opts, profile, nocolor) do
    if Keyword.has_key?(opts, :report) do
      opts
    else
      format_opts = nocolor_opt(nocolor) ++ profile_opt(profile)
      [:no_tty, {:report, {:eunit_progress, format_opts}} | opts]
    end
  end

  defp nocolor_opt(true), do: []
  defp nocolor_opt(_), do: [:colored]

  defp profile_opt(true), do: [:profile]
  defp profile_opt(_), do: []

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
end
