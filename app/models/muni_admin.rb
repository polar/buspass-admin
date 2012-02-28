##
# This class is merely for the integration of the Muni subsystem
# for Devise and Cantango. I may be doing this wrong, but Devise
# is not handling namespaces.
# This results in the correct routes for:
#   new_muni_admin
#   edit_muni_admin
#   muni_admins
# etc.
#
class MuniAdmin  < Muni::MuniAdmin
end