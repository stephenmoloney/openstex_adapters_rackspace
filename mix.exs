defmodule OpenstexAdaptersRackspace.Mixfile do
  use Mix.Project
  @version "0.3.0"
  @elixir_versions "~> 1.4 or ~> 1.5"

  def project do
    [app: :openstex_adapters_rackspace,
     version: @version,
     elixir: @elixir_versions,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     source_url: "https://github.com/stephenmoloney/openstex_adapters_rackspace",
     description: description(),
     package: package(),
     docs: docs(),
     deps: deps()
    ]
  end


  def application do
    [
      applications: [:logger, :hackney]
    ]
  end


  defp deps do
    [
      {:httpipe_adapters_hackney, ">= 0.10.0"},
      {:openstex, "~> 0.3"},

      # dev deps
      {:markdown, github: "devinus/markdown", only: [:dev]},
      {:ex_doc,  "~> 0.14", only: [:dev]}
    ]
  end


  defp description() do
    ~s"""
    An adapter for the openstex library for making calls to Openstack compliant Rackspace services.
    """
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Stephen Moloney"],
      links: %{ "GitHub" => "https://github.com/stephenmoloney/openstex_adapters_rackspace"},
      files: ~w(lib mix.exs CHANGELOG* README* LICENCE*)
     }
  end

  defp docs() do
    [
    main: "Openstex.Adapters.Rackspace",
    extras: []
    ]
  end

end