defmodule ExProxmox do
  @moduledoc """
  A client for interacting with Proxmox PVE APIv2.
  """

  defstruct [:connection, :auth_ticket]

  @type options :: %{
          required(:username) => String.t(),
          required(:password) => String.t(),
          required(:realm) => String.t(),
          optional(:token) => String.t(),
          optional(:secret) => String.t(),
          optional(:otp) => String.t()
        }

  @doc """
  Creates a new ExProxmox client.

  ## Parameters

    - base_url: The base URL of the Proxmox API.
    - options: A map containing the following keys:
      - :username (required) - The username@realm for authentication.
      - :password (required) - The password for authentication.
      - :token (optional) - The API token.
      - :secret (optional) - The secret associated with the API token.
      - :otp (optional) - The one-time password for two-factor authentication.

  ## Examples

      iex> ExProxmox.new("https://proxmox-ve:8006/api2/json/", %{"username" => "root@pam", "password" => "secret"})
      %ExProxmox{connection: %{base_url: "https://proxmox-ve:8006/api2/json/", headers: []}, auth_ticket: %{...}}

  """
  @spec new(String.t(), options) :: struct()
  def new(base_url, options) do
    headers = build_headers(options)
    connection = %{base_url: base_url, headers: headers}
    auth_ticket = if options[:token], do: %{}, else: create_auth_ticket(connection, options)

    %ExProxmox{connection: connection, auth_ticket: auth_ticket}
  end

  @doc """
  Submits a request to the Proxmox API.

  ## Parameters

    - client: The ExProxmox client.
    - method: The HTTP method (:get, :post, :put, :delete).
    - url: The endpoint URL (relative to the base URL).
    - data: (optional) The data to be sent with the request (default is an empty map).

  ## Examples

      iex> client = ExProxmox.new("https://proxmox-ve:8006/api2/json/", %{"username" => "root@pam", "password" => "secret"})
      iex> ExProxmox.submit(client, :get, "nodes")
      %{"data" => [...]}

  """
  @spec submit(struct(), :get | :post | :put | :delete, String.t(), map) :: map
  def submit(client, method, url, data \\ %{}) do
    options = prepare_options(method, data, client.auth_ticket)
    full_url = "#{client.connection.base_url}#{url}"

    response =
      case method do
        :get -> HTTPoison.get!(full_url, options[:headers], params: options[:params])
        :post -> HTTPoison.post!(full_url, options[:body] || "", options[:headers])
        :put -> HTTPoison.put!(full_url, options[:body] || "", options[:headers])
        :delete -> HTTPoison.delete!(full_url, options[:headers])
      end

    raise_on_failure(response)
    Jason.decode!(response.body)["data"]
  end

  defp build_headers(%{token: token, secret: secret})
       when not is_nil(token) and not is_nil(secret) do
    [{"Authorization", "PVEAPIToken=#{token}=#{secret}"}]
  end

  defp build_headers(_), do: []

  defp create_auth_ticket(connection, options) do
    response =
      HTTPoison.post!("#{connection.base_url}access/ticket", Jason.encode!(options), [
        {"Content-Type", "application/json"}
      ])

    raise_on_failure(response, "Proxmox authentication failure")

    data = Jason.decode!(response.body)["data"]

    %{
      cookies: %{"PVEAuthCookie" => data["ticket"]},
      CSRFPreventionToken: data["CSRFPreventionToken"]
    }
  end

  defp raise_on_failure(response, message \\ "Proxmox API request failed") do
    if response.status_code >= 400 do
      raise {:error, message: message, response: response}
    end
  end

  defp prepare_options(:post, data, auth_ticket),
    do: %{body: Jason.encode!(data), headers: base_headers(auth_ticket)}

  defp prepare_options(:put, data, auth_ticket),
    do: %{body: Jason.encode!(data), headers: base_headers(auth_ticket)}

  defp prepare_options(:get, data, auth_ticket),
    do: %{params: data, headers: base_headers(auth_ticket)}

  defp prepare_options(:delete, _data, auth_ticket), do: %{headers: base_headers(auth_ticket)}

  defp base_headers(auth_ticket) do
    [{"Content-Type", "application/json"}] ++ auth_headers(auth_ticket)
  end

  defp auth_headers(%{cookies: %{"PVEAuthCookie" => ticket}, CSRFPreventionToken: csrf_token}) do
    [
      {"Cookie", "PVEAuthCookie=#{ticket}"},
      {"CSRFPreventionToken", csrf_token}
    ]
  end

  defp auth_headers(_), do: []
end
