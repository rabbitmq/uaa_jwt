# UAA JWT decoder

This project is used to decode Json Web Tokens ([rfc7519](https://tools.ietf.org/html/rfc7519))
returned by [Cloud foundry UAA OAuth2 server](https://github.com/cloudfoundry/uaa)

The tokens are issued by UAA to OAuth2 resource server
[rfc6749](https://tools.ietf.org/html/rfc6749#section-1.1) and the resource server
can decode and verify the tokens to authorize access to it's resources.

## Limitations and dependencies

This project can be used to decode and verify JWT tokens issued by UAA or other provider.
It cannot be used to encode or sign the tokens.

The project doesn't make any requests to UAA server and should be configured using
information about UAA keys. See [Usage][Usage]

The project is based on [erlang-jose][erlang-jose]
JWT management library and inherits all the algorithm limitations.
Supported algorithms and [JWK][jwk-rfc]
types can be configured through `erlang-jose` configuration.

The project uses [jsx](https://github.com/talentdeficit/jsx) to decode JSON

## UAA key management

UAA uses [JWK][jwk-rfc] keys to sign it's tokens.

Signing key can be retrieved from UAA server using [/token_key](https://docs.cloudfoundry.org/api/uaa/#token-key)
API request.

There can be two types of keys:
- `RSA` - standard RSA key type described in [JWA RFC](https://tools.ietf.org/html/rfc7518#section-6.3)
- `MAC` - UAA specific symmetric key

UAA prior to version `3.10.0` returns invalid `alg` valuse for a signing key.
[UAA issue #132796973](https://www.pivotaltracker.com/n/projects/997278/stories/132796973)
This project has a workaround to replace it with correct values.

To handle `MAC` key type, the project transform JWK with this type to standard `oct` type by
replacing `kty` field and adding `k` field with `base64url` encoded key value.

## Installation

The package can be installed as:

  1. Add `uaa_jwt` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:uaa_jwt, git: "git://github.com/rabbitmq/uaa_jwt"}]
    end
    ```

  2. Ensure `uaa_jwt` is started before your application:

    ```elixir
    def application do
      [applications: [:uaa_jwt]]
    end
    ```

## Usage

To verify tokens, you should configure one or many signing keys (JWK).
You can do that using the application environment or the `UaaJWT.add_signing_key`
function.

To configure keys using the application environment:

in `config.exs`:
```
config :uaa_jwt, signing_keys: %{
        "key1" => {:map, %{"kty" => "oct", "k" => "dG9rZW5rZXk"}},
        "key2" => {:pem, "/path/to/public_key.pem"},
        "legacy-token-key" => {:json, '{"kid":"legacy-token-key","alg":"HMACSHA256","value":"tokenkey","kty":"MAC","use":"sig"}'}
    }

```

or using erlang-style `.config`:
```
[{uaa_jwt, [{signing_keys, #{
    <<"key1">> => {map, #{<<"kty">> => <<"oct">>, <<"k">> => <<"dG9rZW5rZXk">>}},
    <<"key2">> => {pem, <<"/path/to/public_key.pem">>},
    <<"legacy-token-key">> =>
    {json, "{\"kid\":\"legacy-token-key\",\"alg\":\"HMACSHA256\",\"value\":\"tokenkey\",\"kty\":\"MAC\",\"use\":\"sig\"}"}
}}]}]
```

This config defines three signing keys.

The first one is a standard `JWK` octet sequence key with `base64url` encoded value for `k`.

The second one is a filename for RSA public key.

The third one is a JSON result from `/token_key` request to UAA API.
It can be a char_list or a string.


To add a key using the `UaaJWT.add_signing_key` function:

```
add_signing_key("key1", :map, %{"kty" => "oct", "k" => "bXlfa2V5"})
```

This function will try to validate a key and add it to `signing_key`
application environemnt.

After configuring the keys, you can decode a token using the `UaaJWT.decode_and_verify` function:

```
UaaJWT.decode_and_verify(String.t) :: {true | false, Map.t} | {:error, term()}
```

The signing key will be selected from configuration by `kid` field in
`JWS` part of token.

Following functions can be used for debug purposes:

To get the `kid` field only from a token:

```
UaaJWT.JWT.get_key_id(token)
```

To decode a token without signature verification:

```
UaaJWT.JWT.decode(token)
```

To validate a `JWK` key (map or json):

```
UaaJWT.JWK.make_jwk(jwk)
```

Read [erlang-jose][erlang-jose] dosumentation for more functions and options.


[erlang-jose]:https://github.com/potatosalad/erlang-jose
[jwk-rfc]:https://tools.ietf.org/html/rfc7517