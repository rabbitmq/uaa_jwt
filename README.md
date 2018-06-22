# UAA JWT decoder

This library can decode [JSON Web Tokens](https://tools.ietf.org/html/rfc7519)
returned by [Cloud Foundry UAA](https://github.com/cloudfoundry/uaa).

The tokens are issued by UAA to [OAuth 2 resource servers](https://tools.ietf.org/html/rfc6749#section-1.1)
and a resource server can decode and verify the tokens to authorize access to its resources.

## Dependencies

The project is based on a number of dependencies:

 * [erlang-jose][erlang-jose], a JWT management library and inherits all of its algorithm limitations.
   Supported algorithms and [JWK][jwk-rfc] types can be configured by configuring `erlang-jose`.

 * [jsx](https://github.com/talentdeficit/jsx) as JSON decoder

## (Current) Limitations

This project can be used to decode and verify JWT tokens issued by UAA or other providers.
Encoding or signing of JWTs is currently out of scope for this library.

The project doesn't make any requests to UAA server and requires UAA keys to be
pre-configured. This is by design. See [Usage][Usage] for more info.

## UAA Key Management

UAA uses [JWK][jwk-rfc] keys to sign JWTs.

Signing key can be retrieved from UAA using a [/token_key](https://docs.cloudfoundry.org/api/uaa/#token-key)
API request.

There can be two types of keys:

 * `RSA`: standard RSA key type described in [JWA RFC](https://tools.ietf.org/html/rfc7518#section-6.3)
 * `MAC`: UAA specific symmetric key

To handle `MAC` key type, the project transform JWK with this type to standard `oct` type by
replacing `kty` field and adding `k` field with `base64url` encoded key value.

### Known UAA Bugs

UAA prior to version `3.10.0` returns an invalid `alg` values for a signing key.
[UAA issue #132796973](https://www.pivotaltracker.com/n/projects/997278/stories/132796973)
This project provides a workaround to correct (normalize) such values.

## Installation

The package can be installed as:

  1. Add `uaa_jwt` to your list of dependencies in the `Makefile` for `erlang.mk`:

```erlang
DEPS = uaa_jwt
dep_uaa_jwt = git git://github.com/rabbitmq/uaa_jwt erlang
```

## Usage

To verify tokens, you should configure one or many signing keys (JWK).
You can do that using the application environment or the `uaa_jwt.add_signing_key`
function.

### Configuration

To configure keys using the application environment:

or erlang `.config`:
```
[{uaa_jwt, [{signing_keys, #{
    <<"key1">> => {map, #{<<"kty">> => <<"oct">>, <<"k">> => <<"dG9rZW5rZXk">>}},
    <<"key2">> => {pem, <<"/path/to/public_key.pem">>},
    <<"legacy-token-key">> =>
    {json, "{\"kid\":\"legacy-token-key\",\"alg\":\"HMACSHA256\",\"value\":\"tokenKey\",\"kty\":\"MAC\",\"use\":\"sig\"}"}
}}]}]
```

This config defines three signing keys.

The first one is a standard `JWK` octet sequence key with `base64url` encoded value for `k`.
The second one is a filename for RSA public key.
The third one is a JSON result from a `/token_key` request to UAA. It should be a binary or a string

To add a key using the `uaa_jwt:add_signing_key` function:

```
add_signing_key(<<"key1">>, map, #{<<"kty">> => <<"oct">>, <<"k">> => <<"bXlfa2V5">>}).
```

This function will try to validate a key and add it to `signing_key`
application environemnt.

If a JWK token doesn't contain a `kid` field, "default" key will be used.
Default key can be selected by using `defeult_key` environment variable.

For example, if we want to make `key1` a default key:

```
[{uaa_jwt, [{default_key, <<"key1">>}, ...]}].
```

By default, default key value is `<<"default">>`


### Decoding

After configuring the keys, you can decode a token using the `uaa_jwt:decode_and_verify` function:

```
uaa_jwt:decode_and_verify(binary()) -> {true | false, map()} | {error, term()}.
```

The signing key will be selected according to the `kid` field in
the `JWS` part of the token.

Following functions can be used for debug purposes:

To get the `kid` field only from a token:

```
uaa_jwt_jwt:get_key_id(Token).
```

To decode a token without signature verification:

```
uaa_jwt_jwt:decode(Token).
```

To validate a `JWK` key (provided as a map or JSON document):

```
uaa_jwt_jwk.make_jwk(Jwk).
```

Please consult [erlang-jose][erlang-jose] dosumentation for more functions and options.

## License and Copyright

2016 (c) Pivotal Software, Inc.

Distributed under the same [license as RabbitMQ server](https://github.com/rabbitmq/rabbitmq-server/blob/master/LICENSE).

[erlang-jose]:https://github.com/potatosalad/erlang-jose
[jwk-rfc]:https://tools.ietf.org/html/rfc7517
