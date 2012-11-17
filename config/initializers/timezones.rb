#
# This is the initialization of available Timezone names from geonames.org
#

puts "TimeZones Start"

require "timezone"

puts "Done loading Timezone."

# List for Views selections.

TIMEZONES_LIST = Timezone::Zone.names

puts "Got TZ names #{TIMEZONES_LIST.count}"

TIMEZONES_LIST = Timezone::Zone.list.map { |z| z[:title] }.sort

puts "Got TZ list #{TIMEZONES_LIST.count}"

puts "TimeZones Done"