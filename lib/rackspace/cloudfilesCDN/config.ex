defmodule Openstex.Adapters.Rackspace.CloudfilesCDN.Config do
  use Openstex.Adapters.Rackspace.Config

  @doc :false
  def swift_service_name(), do: "cloudFilesCDN"

  @doc :false
  def swift_service_type(), do: "rax:object-cdn"

end