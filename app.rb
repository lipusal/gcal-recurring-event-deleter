#!/usr/bin/env ruby
require 'thor'
require 'dotenv'

# App entry point. Adapted from cli entry point in samples directory of google-api-client. Also available at
# https://github.com/googleapis/google-api-ruby-client/blob/master/samples/cli/google-api-samples
class App < Thor

  # Load all command files and register them as subcommands
  Dir.glob('./lib/commands/*.rb').each do |file|
    require file
  end

  Commands.constants.each do |const|
    desc const.downcase, const.to_s
    subcommand const.downcase, Commands.const_get(const)
  end

end

Dotenv.load
App.start(ARGV)
