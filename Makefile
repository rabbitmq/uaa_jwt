PROJECT = uaa_jwt
PROJECT_DESCRIPTION = New project
PROJECT_VERSION = 0.1.0

DEPS = jose

dep_jose = git git://github.com/potatosalad/erlang-jose.git 1.8.4

include erlang.mk
