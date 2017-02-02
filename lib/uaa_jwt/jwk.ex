defmodule UaaJWT.JWK do

  @spec make_jwk(String.t | Map.t) :: {:ok, %{required(String.t) => String.t}} | {:error, term()}
  def make_jwk(json) when is_binary(json) or is_list(json) do
    json_map = JOSE.decode(to_string(json))
    make_jwk(json_map)
  end
  def make_jwk(json_map) when is_map(json_map) do
    case json_map do
      %{"kty" => "MAC", "value" => _value} ->
        {:ok, mac_to_oct(json_map)};
      %{"kty" => "RSA", "n" => _n, "e" => _e} ->
        {:ok, fix_alg(json_map)};
      %{"kty" => "oct", "k" => _k} ->
        {:ok, fix_alg(json_map)};
      %{"kty" => "OKP", "crv" => _crv, "x" => _x} ->
        {:ok, fix_alg(json_map)};
      %{"kty" => "EC"} ->
        {:ok, fix_alg(json_map)};
      %{"kty" => kty} when kty == "oct" or
                           kty == "MAC" or
                           kty == "RSA" or
                           kty == "OKP" or
                           kty == "EC" ->
        {:error, {:fields_missing_for_kty, kty}};
      %{"kty" => _kty} ->
        {:error, :unknown_kty};
      %{} ->
        {:error, :no_kty}
    end
  end

  def from_pem_file(file_name) do
    case File.exists?(file_name) do
      false ->
        {:error, :enoent};
      true  ->
        case JOSE.JWK.from_pem_file(file_name) do
          %JOSE.JWK{} = jwk -> {:ok, jwk};
          _other            -> {:error, :invalid_pem_file}
        end
    end
  end

  defp mac_to_oct(%{"kty" => "MAC", "value" => value} = key) do
    okt_key = Map.merge(key, %{"kty" => "oct", "k" => :base64url.encode(value)})
    fix_alg(okt_key)
  end

  defp fix_alg(%{"alg" => alg} = key) do
    case uaa_algs()[alg] do
      nil -> key;
      val -> %{key | "alg" => val}
    end
  end
  defp fix_alg(%{} = key), do: key

  defp uaa_algs do
    Application.get_env(:uaa_jwt_decoder, :uaa_algs,
                        %{
                          "HMACSHA256" => "HS256",
                          "HMACSHA384" => "HS384",
                          "HMACSHA512" => "HS512",
                          "SHA256withRSA" => "RS256",
                          "SHA512withRSA" => "RS512"
                        })
  end
end