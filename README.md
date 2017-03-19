# Openstex.Adapters.Rackspace

An adapter for [Openstex](https://github.com/stephenmoloney/openstex)
for the Rackspace Openstack compliant API.


## Steps to getting started

### (1) Installation

- Add `:openstex_adapters_rackspace` to your project list of dependencies.

```elixir
defp deps() do
  [
    {:openstex_adapters_rackspace, "~> 0.3"}
  ]
end
```

- Ensure `openstex_adapters_rackspace` is started before your application:

```elixir
def application do
  [applications: [:openstex_adapters_rackspace]]
end
```

### (2) Configure the Adapter Clients

#### Generating the rackspace `api key`, `username` and `password`.

- Adding the variables to the environment (to a `/env` file for example).

```shell
export RACKSPACE_API_KEY="api_key"
export RACKSPACE_USERNAME="username"
export RACKSPACE_PASSWORD="password"
```

- The final configuruation file in `config.exs` should look similar to:

```elixir
config :my_app, MyApp.Cloudfiles,
  adapter: Openstex.Adapters.Rackspace.Cloudfiles.Adapter,
  rackspace: [
    api_key: System.get_env("RACKSPACE_API_KEY"),
    username: System.get_env("RACKSPACE_USERNAME"),
    password: System.get_env("RACKSPACE_PASSWORD")
  ],
  keystone: [
    tenant_id: :nil,
    user_id: :nil,
    endpoint: "https://identity.api.rackspacecloud.com/v2.0"
  ],
  swift: [
    account_temp_url_key1: System.get_env("RACKSPACE_CLOUDFILES_TEMP_URL_KEY1"), # defaults to :nil if absent
    account_temp_url_key2: System.get_env("RACKSPACE_CLOUDFILES_TEMP_URL_KEY2"), # defaults to :nil if absent
    region: :nil
  ],
  hackney: [
    timeout: 20000,
    recv_timeout: 180000
  ]

config :my_app, CloudfilesCDN,
  adapter: Openstex.Adapters.Rackspace.CloudfilesCDN.Adapter,
  rackspace: [
    api_key: System.get_env("RACKSPACE_API_KEY"),
    username: System.get_env("RACKSPACE_USERNAME"),
    password: System.get_env("RACKSPACE_PASSWORD")
  ],
  keystone: [
    tenant_id: :nil,
    user_id: :nil,
    endpoint: "https://identity.api.rackspacecloud.com/v2.0"
  ],
  swift: [
    account_temp_url_key1: System.get_env("RACKSPACE_CLOUDFILESCDN_TEMP_URL_KEY1"), # defaults to :nil if absent
    account_temp_url_key2: System.get_env("RACKSPACE_CLOUDFILESCDN_TEMP_URL_KEY2"), # defaults to :nil if absent
    region: :nil
  ],
  hackney: [
    timeout: 20000,
    recv_timeout: 180000
  ]

config :httpipe,
  adapter: HTTPipe.Adapters.Hackney
```

- The options for the region are as follows:

```shell
# "IAD" - North Virginia, "DFW" - Dallas, "HKG" - Hong Kong or "SYD" - Sydney, "LON" - London
```


### (3) Creating the client module

- The client module is used for making requests.

- Create the client module similar as follows:

```elixir
defmodule MyApp.Cloudfiles do
  @moduledoc :false
  use Openstex.Client, otp_app: :my_app, client: __MODULE__

  defmodule Swift do
    @moduledoc :false
    use Openstex.Swift.V1.Helpers, otp_app: :my_app, client: MyApp.Cloudfiles
  end
end


defmodule MyApp.CloudfilesCDN do
  @moduledoc :false
  use Openstex.Client, otp_app: :my_app, client: __MODULE__

  defmodule Swift do
    @moduledoc :false
    use Openstex.Swift.V1.Helpers, otp_app: :my_app, client: MyApp.CloudfilesCDN
  end
end

```

### (4) Adding the client to the supervision tree

```elixir
def start(_type, _args) do
  import Supervisor.Spec, warn: false
  spec1 = [supervisor(MyApp.Endpoint, [])]
  spec2 = [supervisor(MyApp.Cloudfiles, [])]
  spec2 = [supervisor(MyApp.CloudfilesCDN, [])]
  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(spec1 ++ spec2, opts)
end
```

### (5) Using the client module

#### To use the client for the `Openstex` API:

- Creating a container using the `Openstex.Swift.V1` request generator and then sending the request.
```elixir
  MyApp.Cloudfiles.start_link()
  Openstex.Swift.V1.create_container("new_container", "my_swift_account") |> MyApp.Cloudfiles.request()
```

- Uploading a file using the the `Openstex` Swift Helper:
```elixir
  file_path = Path.join(Path.expand(__DIR__), "priv/test.txt")
  MyApp.Cloudfiles.Swift.upload_file!(file_path, "nested_folder/server_object.txt", "new_container")
```

- Listing the objects using the `Openstex` Swift Helper:
```elixir
  MyApp.Cloudfiles.Swift.list_objects!("new_container")
```