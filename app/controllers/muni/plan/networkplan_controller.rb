require "zip/zip"

class Muni::Plan::NetworkplanController < Muni::Plan::NetworkController

  def show
  end

  def upload
    @network_param_name = :networkplan

  end

  def update
    @network.file = nil
    @network.update_attributes(params[:networkplan])
    @network.save!
    dir = Dir.mktmpdir
    # TODO: Clean up this file path stuff.
    unzip(File.join(Rails.root,File.join("public",@network.file.url)),dir)
    ServiceTable.rebuildRoutes(@network, dir)
    render :upload
  end

  private

  def unzip(zip, unzip_dir, remove_after = false)
    Zip::ZipFile.open(zip) do |zip_file|
      zip_file.each do |f|
        f_path=File.join(unzip_dir, f.name)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) # unless File.exist?(f_path)
      end
    end
    FileUtils.rm(zip) if remove_after
  end
end