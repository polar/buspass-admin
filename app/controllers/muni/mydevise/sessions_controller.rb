class Muni::Mydevise::SessionsController < Devise::SessionsController
    #noinspection RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable
    def after_sign_in_path_for(resource)
        # Resource should be a Admin
        if @muni.nil?
            raise "No Municipality Specified"
        end
        plan_home_path(:muni => @muni.slug)
    end
    def after_sign_out_path_for(resource)
        # Resource should be a Admin
        if @muni.nil?
            raise "No Municipality Specified"
        end
        plan_home_path(:muni => @muni.slug)
    end
end