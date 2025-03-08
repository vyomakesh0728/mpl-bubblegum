defmodule MplBubblegum.MixProject do
  use Mix.Project

  def project do
    [
      app: :mpl_bubblegum,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:rustler] ++ Mix.compilers(),
      rustler_crates: rustler_crates()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:rustler, "~> 0.29.1"},
      {:ex_doc, "~> 0.29.0", only: :dev, runtime: false},
      {:b58, "~> 1.0.2"},
      {:jason, "~> 1.4"},
      {:tesla, "~> 1.4.0"},
      {:base58, "~> 0.1.0"}
    ]
  end

  defp rustler_crates do
    [
      mpl_bubblegum: [
        path: "native/mpl_bubblegum",
        mode: if(Mix.env() == :prod, do: :release, else: :debug)
      ]
    ]
  end
end
