class Mydevise::SessionsController < Devise::SessionsController
    def after_sign_in_path_for(resource)
        # Resource should be a Admin
        municipalities_path
    end
    def after_sign_out_path_for(resource)
        # Resource should be a Admin
        municipalities_path
    end
end