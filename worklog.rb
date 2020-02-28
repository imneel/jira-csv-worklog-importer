# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

require 'dotenv/load'
require 'time'
require_relative './lib/jira.rb'
require_relative './lib/toggl.rb'
require_relative './lib/sync.rb'

Sync.new((Date.today - 7).to_s, Date.today.to_s).execute
