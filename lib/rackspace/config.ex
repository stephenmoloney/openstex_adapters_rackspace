defmodule Openstex.Adapters.Rackspace.Config do

  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @moduledoc :false
      alias Openstex.Keystone.V2.Helpers.Identity
      alias Openstex.Adapters.Rackspace.Utils
      alias Openstex.Keystone.V2.Helpers
      @default_headers [{"Content-Type", "application/json; charset=utf-8"}]
      @default_options [timeout: (60 * 1000), recv_timeout: (10 * 60 * 1000)]
      @default_adapter HTTPipe.Adapters.Hackney
      @default_rackspace_region :nil
      use Openstex.Adapter.Config

      # public

      def start_agent(client, opts) do
        otp_app = Keyword.get(opts, :otp_app, :false) || raise("Client has not been configured correctly, missing `:otp_app`")
        identity = Utils.create_identity(client, otp_app)
        Agent.start_link(fn -> config(client, otp_app, identity) end, name: agent_name(client))
      end

      @doc "Gets the rackspace related config variables from a supervised Agent"
      def rackspace_config(client) do
        Agent.get(agent_name(client), fn(config) -> config[:rackspace] end)
      end

      # private

      defp config(client, otp_app, identity) do
        [
         rackspace: rackspace_config(client, otp_app),
         keystone: keystone_config(client, otp_app, identity),
         swift: swift_config(client, otp_app, identity),
         hackney: hackney_config(client, otp_app)
        ]
      end

      defp rackspace_config(client, otp_app) do
        get_config_from_env(client, otp_app) |> Keyword.fetch!(:rackspace)
      end

      defp keystone_config(client, otp_app, identity) do

        keystone_config = get_keystone_config_from_env(client, otp_app)

        tenant_id = keystone_config[:tenant_id] ||
                    identity.token.tenant.id ||
                    raise("cannot retrieve the tenant_id for keystone")

        user_id =   keystone_config[:user_id] ||
                    identity.user.id ||
                    raise("cannot retrieve the user_id for keystone")

        endpoint =  keystone_config[:endpoint] ||
                    "https://identity.api.rackspacecloud.com/v2.0"

        [
        tenant_id: tenant_id,
        user_id: user_id,
        endpoint: endpoint
        ]
      end

      defp swift_config(client, otp_app, identity) do

        swift_config = get_swift_config_from_env(client, otp_app)

        account_temp_url_key1 = get_account_temp_url(client, otp_app, :key1) ||
                                swift_config[:account_temp_url_key1] ||
                                :nil

        if account_temp_url_key1 != :nil && swift_config[:account_temp_url_key1] != account_temp_url_key1 do
          error_msg =
          "Warning, the `account_temp_url_key1` for the elixir `config.exs` for the swift client " <>
          "#{inspect client} does not match the `X-Account-Meta-Temp-Url-Key` on the server. " <>
          "This issue should probably be addressed. See Openstex.Adapter.Config.set_account_temp_url_key1/2."
          IO.puts(:stdio, error_msg)
        end

        account_temp_url_key2 = get_account_temp_url(client, otp_app, :key2) ||
                                swift_config[:account_temp_url_key2] ||
                                :nil

        if account_temp_url_key2 != :nil && swift_config[:account_temp_url_key2] != account_temp_url_key2 do
          error_msg =
          "Warning, the `account_temp_url_key2` for the elixir `config.exs` for the swift client " <>
          "#{inspect client} does not match the `X-Account-Meta-Temp-Url-Key-2` on the server. " <>
          "This issue should probably be addressed. See Openstex.Adapter.Config.set_account_temp_url_key2/2."
          IO.puts(:stdio, error_msg)
        end

        region =   swift_config[:region] ||
                   identity.user.mapail["RAX-AUTH:defaultRegion"] ||
                   raise("cannot retrieve the region for keystone")

        if swift_config[:region] != :nil && identity.user.mapail["RAX-AUTH:defaultRegion"] != swift_config[:region] do
          error_msg =
          "Warning, the `swift_config[:region]` for the elixir `config.exs` for the swift client " <>
          "#{inspect client} does not match the `RAX-AUTH:defaultRegion` on the server. " <>
          "This issue should probably be addressed."
          IO.puts(:stdio, error_msg)
        end

        [
        account_temp_url_key1: account_temp_url_key1,
        account_temp_url_key2: account_temp_url_key2,
        region: region
        ]
      end

      defp hackney_config(client, otp_app) do
        hackney_config = get_hackney_config_from_env(client, otp_app)
        timeout = hackney_config[:timeout] || @default_options[:timeout]
        receive_timeout = hackney_config[:recv_timeout] || @default_options[:recv_timeout]

        [
        timeout: timeout,
        recv_timeout: receive_timeout,
        ]
      end

      defp get_account_temp_url(client, otp_app, key_atom) do
        identity = Utils.create_identity(client, otp_app)
        x_auth_token = Map.get(identity, :token) |> Map.get(:id)
        endpoint = get_public_url(client, otp_app, identity)

        headers =
        @default_headers ++
        [
          {
            "X-Auth-Token", x_auth_token
          }
        ]
        |> Enum.into(%{})

        header =
        case key_atom do
          :key1 -> "X-Account-Meta-Temp-Url-Key"
          :key2 -> "X-Account-Meta-Temp-Url-Key-2"
        end

        request =
        %HTTPipe.Request{
          method: :get,
          url: endpoint,
          body: :nil,
          headers: headers
        }
        {:ok, conn} = %HTTPipe.Conn{request: request, adapter_options: @default_options, adapter: @default_adapter}
        |> Openstex.Request.request(:nil)
        HTTPipe.Conn.get_resp_header(conn, header)
      end

      defp get_public_url(client, otp_app, identity) do
        swift_config = get_swift_config_from_env(client, otp_app)
        region =   swift_config[:region] ||
                   identity.user.mapail["RAX-AUTH:defaultRegion"] ||
                   @default_rackspace_region ||
                   raise("cannot retrieve the region for keystone")

        identity
        |> Map.get(:service_catalog)
        |> Enum.find(fn(%Identity.Service{} = service) ->
          service.name == swift_service_name() &&
          service.type == swift_service_type()
        end)
        |> Map.get(:endpoints)
        |> Enum.find(fn(%Identity.Endpoint{} = endpoint) ->
          endpoint.region ==  region
        end)
        |> Map.get(:public_url)
      end

    end
  end


end