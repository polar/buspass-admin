class TransportController < ApplicationController
  require "open-uri"
  require "net/http"

  ALLOWED_DOMAINS = ['http://gazetteer.openstreetmap.org/',
                     'http://nominatim.openstreetmap.org/',
                     'http://dev.openstreetmap.nl/',
                     'http://www.yournavigation.org/',
                     'http://yournavigation.org/']

  def transport
    url = params[:url]
    method = "get"
    method = params[:method] if params[:method]

    if !ALLOWED_DOMAINS.select { |d| url.start_with?(d) }
      raise "Disallowed Domain in URL #{url}"
    end

    nurl = URI.parse(url)
    params.delete(:url)
    params.delete(:method)
    params.delete(:controller)
    params.delete(:action)
    if (nurl.query)
      k,v = nurl.query.split("=")
      params[k] = v
    end
    if method.downcase == "get"
      nurl.query = URI.encode_www_form(params)
      logger.info nurl.to_s
      body = nurl.open.read
    else
      body = Net::HTTP.post_form(nurl, params)
    end
    render :inline => body
  end
end