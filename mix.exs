defmodule MixEunit.Mixfile do
  use Mix.Project

  def project do
    [app: :mix_eunit,
     version: "0.1.3",
     elixir: "~> 1.0",
     description: "A mix task to run eunit tests, works for umbrella projects",
     package: package]
  end

  defp package do
    [
        files: [
                "LICENSE",
                "mix.exs",
                "README.md",
                "lib"
            ],
        contributors: ["Dan Swain"],
        links: %{"github" => "https://github.com/dantswain/mix_eunit"},
        licenses: ["MIT"]
    ]
  end
end
