##
# This controller is organized around this route scheme.
#
# match "/:version/:call" => "apis#apis_master_host", :as => "apis_master_host_apis",
#       :constraints => { :host => /^apis\.(?<master_id>[\w\-]+)\.#{Rails.application.base_host}$/ }
# match "/apis/:version/:call" => "apis#master_host", :as => "master_host_apis",
#       :constraints => { :host => /^(?<master_id>[\w\-]+)\.#{Rails.application.base_host}$/ }
# match "/:master_id/apis/:version/:call" => "apis#host", :as => "host_apis",
#       :constraints => { :host => Rails.application.base_host }
# match "/:master_id/:version/:call" => "apis#apis_host", :as => "apis_host_apis",
#       :constraints => { :host => "apis.#{Rails.application.base_host}" }
#
# The API must respond to
#

class ApisController < ApplicationController

  attr_accessor :api

  # http://busme.us/apis/1
  def show
    case params[:version]
      when "d1"
        params[:api_url_for] = lambda { |version, verb| api_host_url(version, verb) }
        d = Apis::Discovery1.new(params[:api_url_for])
        d.get(self)
      else
        render :nothing => true, :status => 500
    end
  end

  def discover
    case params[:id]
      when "d1"
        params[:api_url_for] = lambda { |master, version, verb| host_apis_url(master.slug, version, verb) }
        d = Discovery1.new(params[:api_url_for])
        d.login(self)
      else
        render :nothing => true, :status => 500
    end
  end

  #
  # http://busme.us/syracuse/apis/1.0/routes
  #
  def api_host
    get_master_context
    params[:api_url_for] = lambda { |master, version, verb| host_apis_url(master.slug, version, verb) }
    get_api_context
    process_call
  end

  #
  # http://busme.us/syracuse/apis/1.0/routes
  #
  def host
    params[:old_path] = host_apis_path
    params[:new_path] = host_apis_path("master", "2.0", "call")
    get_master_context
    if @master
      params[:api_url_for] = lambda {|verb| host_apis_url(@master.slug, params[:version], verb)}
      get_api_context
      process_call
    else
      # We shouldn't get here, because our route guaranteed the match?
      render :nothing => true, :status => 500
    end
  end

  #
  # http://apis.busme.us/syracuse/1.0/routes
  #
  def apis_host
    params[:old_path] = apis_host_apis_path
    params[:new_path] = apis_host_apis_path("master", "2.0", "call")
    get_master_context
    if @master
      params[:api_url_for] = lambda {|verb| apis_host_apis_url(@master.slug, params[:version], verb)}
      get_api_context
      process_call
    else
      # We shouldn't get here, because our route guaranteed the match?
      render :nothing => true, :status => 500
    end

  end

  #
  # http://syracuse.busme.us/apis/1.0/routes
  #
  def master_host
    match = /^(?<master_id>[\w\-]+)\.#{Rails.application.base_host}$/.match(request.host)
    params[:old_path] = master_host_apis_path
    params[:new_path] = master_host_apis_path("2.0", "call")
    if match
      params[:master_id] ||= match[:master_id]
      get_master_context
      if @master
        params[:api_url_for] = lambda {|verb| master_host_apis_url(params[:version], verb) }
        get_api_context
        process_call
      else
        # We shouldn't get here, because our route guaranteed the match?
        render :nothing => true, :status => 500
      end
    else
      # We shouldn't get here, because our route guaranteed the match?
      render :nothing => true, :status => 500
    end
  end

  #
  # http://apis.syracuse.busme.us/1.0/routes
  #
  def apis_master_host
    match = /^apis\.(?<master_id>[\w\-]+)\.#{Rails.application.base_host}$/.match(request.host)
    params[:old_path] = apis_master_host_apis_path
    params[:new_path] = apis_master_host_apis_path("2.0", "call")
    if match
      params[:master_id] ||= match[:master_id]
      get_master_context
      if @master
        params[:api_url_for] = lambda {|verb| apis_master_host_apis_url(params[:version], verb) }
        get_api_context
        process_call
      else
        # We shouldn't get here, because our route guaranteed the match?
        render :nothing => true, :status => 500
      end
    else
      # We shouldn't get here, because our route guaranteed the match?
      render :nothing => true, :status => 500
    end
  end

  private

  def process_call
    if api && api.allowable_calls.include?(params[:call])
      api.send(params[:call].to_sym, self)
    else
      render :nothing => true, :status => 404
    end
  rescue
    render :nothing => true, :status => 500
  end

  def get_master_context
    @master = Master.find_by_slug(params[:master_id])
    @master ||= Master.find(params[:master_id])
  end

  def get_api_context
    @api = get_api
  end

  def get_api
    case params[:version]
      when "1"
        api = Apis::V1.new(@master, "active", params[:api_url_for])
      when "t1"
        api = Apis::V1.new(@master, "test", params[:api_url_for])
      when "d1"
        api = Apis::Discovery1.new(params[:api_url_for])
      else
        nil
    end
  end
end