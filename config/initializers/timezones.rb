#
# This is the initialization of available Timezone names from geonames.org
#
require "timezone"

# List for Views selections.

TIMEZONES_LIST = Timezone::Zone.list.map {|z| z[:title] }