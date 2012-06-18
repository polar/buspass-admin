# Your_app's root/config/initializers/cantango_editor.rb
CantangoEditor.configure do |config|

  # Permission types to be displayed in interface
  # default: [:user_types, :account_types, :roles, :role_groups, :licenses, :users]
  config.permission_types_available = [:user_types, :account_types, :roles, :role_groups, :licenses, :users]

  # If you do not enumerate all permission_types here -
  # those that are unmentioned here will just appear empty, having no permission_groups.
  # default: { :roles => [:admin, :user] }.
  config.permission_groups_available = { :roles => [:busme_masters, :user], :user_types => [:busme_masters, :muni_admin, :muni_user] }

  # default: all Models extracted from ActiveRecord's tables list
  config.models_available = [Municipality]

  # Cancan's actions
  # default: [:create, :read, :update, :delete, :manage]
  config.actions_available = config.actions_default | [:write, :assign_roles]
end
