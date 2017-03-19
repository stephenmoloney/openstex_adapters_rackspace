defmodule Openstex.Adapters.Rackspace.Utils do
  alias Openstex.Keystone.V2.Helpers
  @default_headers [{"Content-Type", "application/json; charset=utf-8"}]
  @default_options [timeout: (30 * 1000), recv_timeout: (30 * 1000)]
  @default_adapter HTTPipe.Adapters.Hackney

  @doc :false
  @spec create_identity(atom, atom) :: Identity.t | no_return
  def create_identity(openstex_client) do
    rackpace_config = openstex_client.config().rackspace_config(openstex_client)
    keystone_config = openstex_client.config().keystone_config(openstex_client)
    api_key =  rackpace_config[:api_key]
    password = rackpace_config[:password]
    username = rackpace_config[:username]
    endpoint = keystone_config[:endpoint]
    create_identity(api_key, password, username, endpoint)
  end
  def create_identity(openstex_client, otp_app) do
    rackpace_config = openstex_client.config().get_config_from_env(openstex_client, otp_app) |> Keyword.fetch!(:rackspace)
    keystone_config = openstex_client.config().get_keystone_config_from_env(openstex_client, otp_app)
    api_key =  rackpace_config[:api_key]
    password = rackpace_config[:password]
    username = rackpace_config[:username]
    endpoint = keystone_config[:endpoint]
    create_identity(api_key, password, username, endpoint)
  end
  defp create_identity(api_key, password, username, endpoint) do
    {:ok, conn} =
    case api_key do
      :nil ->
        Openstex.Keystone.V2.get_token(endpoint, username, password)
        |> Openstex.Request.request(:nil)
      api_key ->
        body =
        %{
          "auth" =>
                  %{
                    "RAX-KSKEY:apiKeyCredentials" => %{
                                                      "apiKey" => api_key,
                                                      "username" => username
                                                      }
                  }
        }
        |> Poison.encode!()
        request =
        %HTTPipe.Request{
          method: :post,
          url: endpoint <> "/tokens",
          body: body,
          headers: @default_headers |> Enum.into(%{})
        }
        %HTTPipe.Conn{request: request, adapter_options: @default_options, adapter: @default_adapter}
        |> Openstex.Request.request(:nil)
    end
      Helpers.parse_nested_map_into_identity_struct(conn.response.body)
  end

end