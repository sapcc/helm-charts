SHELL := /bin/sh

# Commands
RUBY := ruby

.PHONY: all clean

GENERATED_JSON_FILES = $(patsubst %.json.erb, %.json, $(wildcard *.json.erb))


all: $(GENERATED_JSON_FILES)

clean:
	rm -f $(GENERATED_JSON_FILES)

%.yaml: %.yaml.erb vars.rb Makefile
	@echo "# Generated from $<. Do not modify manually!" > $@
	@echo "# Edit $< and run 'make' instead." >> $@
	@echo >> $@
	erb -T - -r ./vars.rb $< >> $@
