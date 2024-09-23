defmodule ExProxmoxTest do
  use ExUnit.Case
  alias ExProxmox

  setup :verify_on_exit!

  @base_url "https://proxmox-ve:8006/api2/json/"
  @valid_options %{"username" => "root@pam", "password" => "secret"}

  describe "new/2" do
    test "creates a new ExProxmox client with valid options" do
      client = ExProxmox.new(@base_url, @valid_options)
      assert %ExProxmox{connection: %{base_url: @base_url, headers: _}, auth_ticket: _} = client
    end

    test "creates a new ExProxmox client with token and secret" do
      options = Map.put(@valid_options, "token", "api_token")
      options = Map.put(options, "secret", "api_secret")
      client = ExProxmox.new(@base_url, options)
      assert %ExProxmox{connection: %{base_url: @base_url, headers: _}, auth_ticket: %{}} = client
    end
  end
end
