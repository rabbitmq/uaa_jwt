-module(uaa_jwt_jwt).

-export([decode/1, decode_and_verify/2, get_key_id/1]).

-include_lib("jose/include/jose_jwt.hrl").
-include_lib("jose/include/jose_jws.hrl").

decode(Token) ->
    try
      #jose_jwt{fields = Fields} = jose_jwt:peek_payload(Token),
      Fields
    catch Type:Err ->
        {error, {invalid_token, Type, Err, erlang:get_stacktrace()}}
    end.

decode_and_verify(Jwk, Token) ->
    case jose_jwt:verify(Jwk, Token) of
      {true, #jose_jwt{fields = Fields}, _}  -> {true, Fields};
      {false, #jose_jwt{fields = Fields}, _} -> {false, Fields};
      {error, badarg}                         -> {error, invalid_token};
      Other                                   ->
        io:format("Wrong return ~p~n", [Other]),
        Other
    end.

get_key_id(Token) ->
    try
      case jose_jwt:peek_protected(Token) of
        #jose_jws{fields = #{<<"kid">> := Kid}} -> {ok, Kid};
        _                                       ->
            case application:get_env(uaa_jwt, default_key, undefined) of
              undefined -> {error, no_key};
              Val       -> {ok, Val}
            end
      end
    catch Type:Err ->
      {error, {invalid_token, Type, Err, erlang:get_stacktrace()}}
    end.
