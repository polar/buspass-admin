class ZipfileImporter
    extend ActiveModel::Callbacks
    include ActiveModel::Validations

    include Paperclip::Glue

    define_model_callbacks :save
    define_model_callbacks :destroy

    validate :no_attachement_errors

    attr_accessor :id, :zipfile_file_name, :zipfile_file_size, :zipfile_content_type, :zipfile_updated_at

    has_attached_file :zipfile,
                      :path => ":rails_root/public/system/:attachment/:id/:style/:filename",
                      :url  => "/system/:attachment/:id/:style/:filename"

    def initialize(args = { })
      args.each_pair do |k, v|
        self.send("#{k}=", v)
      end
      @id = self.class.next_id
    end

    def persisted?
      false
    end

    def update_attributes(args = { })
      args.each_pair do |k, v|
        self.send("#{k}=", v)
      end
    end

    def save
      run_callbacks :save do
      end
    end

    def destroy
      run_callbacks :destroy do
      end
    end

    # Needed for using form_for Importer::new(), :url => ..... do
    def to_key
      [:zipfile_importer]
    end

    # Need a differentiating id for each new Importer.
    def self.next_id
      @@id_counter += 1
    end

    # Initialize beginning id to something mildly unique.
    @@id_counter = Time.now.to_i

    def expand(path)
      unzip(zipfile.path, path, false)
    end

    def unzip(zip, unzip_dir, remove_after = false)
      Zip::Archive.open(zip) do |zip_file|
        zip_file.each do |f|
          f_path = File.join(unzip_dir, f.name)
          if f.directory?
            FileUtils.mkdir_p(File.dirname(f_path))
          else
            FileUtils.mkdir_p(File.dirname(f_path))
            File.open(f_path, "wb") do |w|
              w << f.read
            end
          end
        end
      end
      FileUtils.rm(zip) if remove_after
    end
end