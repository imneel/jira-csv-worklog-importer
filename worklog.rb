# frozen_string_literal: true

require 'bundler/setup'
Bundler.require(:default)

require 'dotenv/load'
require 'time'
load './lib/jira.rb'
load './lib/toggl.rb'
load './lib/sync.rb'

Sync.new((Date.today - 7).to_s, Date.today.to_s).execute
