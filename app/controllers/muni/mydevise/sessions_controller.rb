class Muni::Mydevise::SessionsController < Devise::SessionsController
  #noinspection RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable,RubyUnusedLocalVariable

  def after_sign_in_path_for(resource)
    # Resource should be a Admin
    if @master.nil?
      raise "No Municipality Specified"
    end
    #plan_home_path(:master_id => @master)
    master_municipalities_path(:master_id => @master)
  end

  def after_sign_out_path_for(resource)
    # Resource should be a Admin
    if @master.nil?
      raise "No Municipality Specified"
    end
    master_municipalities_path(:master_id => @master)
  end
end