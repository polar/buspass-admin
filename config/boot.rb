require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

class String
  def is_binary_data?
    ( self.count( "^ -~", "^\r\n" ).fdiv(self.size) > 0.3 || self.index( "\x00" ) ) unless empty?
  end
  end

require File.expand_path('../aa_creds', __FILE__) if File.exists?(File.expand_path('../aa_creds.rb', __FILE__))
require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
