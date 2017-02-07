defmodule MixEunit.Mixfile do
  use Mix.Project

  def project do
    [app: :mix_eunit,
     version: "0.3.0",
     elixir: "~> 1.0",
     description: "A mix task to run eunit tests, works for umbrella projects",
     package: package(),
     deps: deps()]
  end

  defp package do
    [
        files: [
                "LICENSE",
                "mix.exs",
                "README.md",
                "lib"
            ],
        maintainers: ["Dan Swain"],
        links: %{"github" => "https://github.com/dantswain/mix_eunit"},
        licenses: ["MIT"]
    ]
  end

  defp deps do
    [
      {:eunit_formatters, "~> 0.3.1"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
