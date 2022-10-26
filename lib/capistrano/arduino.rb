require 'capistrano/bundler'
require "capistrano/plugin"
class Capistrano::Arduino < Capistrano::Plugin
end

require_relative 'arduino/systemd'