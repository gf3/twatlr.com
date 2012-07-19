CWD := $(shell pwd)

sass:
	compass watch webpage.sass -c config/compass.rb

server:
	-rm $(CWD)/app.pid
	racket $(CWD)/app.rkt

.PHONY: server sass

