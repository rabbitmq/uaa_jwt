.PHONY: all

MIX = echo y | mix

all:
	$(MIX) do deps.get, deps.compile, compile
