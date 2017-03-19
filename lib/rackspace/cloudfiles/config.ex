defmodule Openstex.Adapters.Rackspace.Cloudfiles.Config do
  use Openstex.Adapters.Rackspace.Config

  @doc :false
  def swift_service_name(), do: "cloudFiles"

  @doc :false
  def swift_service_type(), do: "object-store"

end