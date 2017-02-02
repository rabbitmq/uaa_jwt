defmodule UaaJWT do
  @type key_type() :: :json | :pem | :map

  @spec add_signing_key(binary(), key_type(), String.t | Map.t) :: {:ok, Map.t} | {:error, term()}
  def add_signing_key(key_id, type, value) do
    case verify_signing_key(type, value) do
      :ok ->
        new_signing_keys = Map.put(signing_keys(), key_id, {type, value})
        {:ok, Application.put_env(:uaa_jwt, :signing_keys, new_signing_keys)};
      {:error, _} = err ->
        err
    end
  end

  @spec decode_and_verify(String.t) :: {true, Map.t} | {false, Map.t} | {:error, term()}
  def decode_and_verify(token) do
    with {:ok, key_id} <- UaaJWT.JWT.get_key_id(token),
         {:ok, jwk}    <- get_jwk(key_id)
    do
         UaaJWT.JWT.decode_and_verify(token, jwk)
    end
  end

  @spec get_jwk(binary()) :: {:ok, map()} | {:error, term()}
  def get_jwk(key_id) do
    keys = signing_keys()
    case keys[key_id] do
      nil ->
        {:error, :key_not_found};
      {type, value} ->
        case type do
          :json -> UaaJWT.JWK.make_jwk(value)
          :pem  -> UaaJWT.JWK.from_pem_file(value)
          :map  -> {:ok, value}
          _     -> {:error, :unknown_signing_key_type}
        end
    end
  end

  def verify_signing_key(type, value) do
    verified = case type do
      :json -> UaaJWT.JWK.make_jwk(value)
      :pem  -> UaaJWT.JWK.from_pem_file(value)
      :map  -> UaaJWT.JWK.make_jwk(value)
      _     -> {:error, :unknown_signing_key_type}
    end
    case verified do
      {:ok, key} ->
        case JOSE.JWK.from(key) do
          %JOSE.JWK{}      -> :ok
          {:error, reason} -> {:error, reason}
        end;
      error      -> error
    end
  end

  def signing_keys() do
    Application.get_env(:uaa_jwt, :signing_keys, %{})
  end

end