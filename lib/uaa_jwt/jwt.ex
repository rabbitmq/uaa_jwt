defmodule UaaJWT.JWT do

  def decode(token) do
    try do
      %JOSE.JWT{fields: fields} = JOSE.JWT.peek_payload(token)
      fields
    rescue
      ArgumentError -> {:error, :invalid_token}
    end
  end

  def decode_and_verify(token, jwk) do
    case JOSE.JWT.verify(jwk, token) do
      {true, %JOSE.JWT{fields: fields}, _}  -> {true, fields};
      {false, %JOSE.JWT{fields: fields}, _} -> {false, fields};
      {:error, :badarg}                     -> {:error, :invalid_token};
      other                                 -> other
    end
  end

  def get_key_id(token) do
    try do
      case JOSE.JWT.peek_protected(token) do
        %JOSE.JWS{fields: %{"kid" => kid}} -> {:ok, kid};
        _                                  -> {:error, :no_key}
      end
    rescue
      ArgumentError -> {:error, :invalid_token}
    end
  end
end
