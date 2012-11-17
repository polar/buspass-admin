class S3ImagesController < ApplicationController


  # This controller is an effort to give images in the WYSWIG editor
  # master independent urls that will redirect to the proper S3 bucket
  # for the particular master. However, getting the master from the
  # current session is problematic as the user may not be good, because
  # you could be a customer looking at a master sight and in the same
  # session look at the main site or another master. We don't know
  # which master to look at this this case. This is currently not used.
  # TODO:  Currently NOT used.

  def s3_bucket
    s3 = AWS::S3.new(
        :access_key_id => ENV['AWS_ACCESS_KEY_ID'],
        :secret_access_key => ENV['AWS_SECRET_ACCESS_KEY'])
    s3.buckets[ENV['S3_BUCKET_NAME']]
  end

  def show
    path = request.fullpath.gsub("/s3image/", "");

    master_id = session[:master_id] || "main"
    bucket = s3_bucket

    redirect_to "#{bucket.url}#{master_id}/#{path}"
  end
end