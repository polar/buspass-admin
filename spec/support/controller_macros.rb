module ControllerMacros
  def login_admin
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:admin]
      sign_in admin # Using factory girl as an example
    end
  end

  def login_muni_admin(admin)
    before(:each) do
      @request.env["devise.mapping"] = Devise.mappings[:muni_admin]
      puts "MAPPING #{Devise.mappings[:muni_admin].inspect}"
      puts "ADMIN #{admin.inspect}"
      sign_in :muni_admin, admin
    end
  end
end