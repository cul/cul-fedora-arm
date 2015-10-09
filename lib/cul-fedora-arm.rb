# coding: utf-8
require "cul/fedora/arm/foxml_builder"
require "cul/fedora/arm/builder"
require "cul/fedora/arm/tasks"
require "cul/fedora/connector"
begin
	require "activesupport"
rescue LoadError
	require "active_support"
end
require "ruby-fedora"