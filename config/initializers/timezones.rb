#
# This is the initialization of available Timezone names from geonames.org
#

puts "TimeZones Start"

require "timezone"

# List for Views selections.

TIMEZONES_LIST = Timezone::Zone.list.map {|z| z[:title] }.sort

puts "TimeZones Done"