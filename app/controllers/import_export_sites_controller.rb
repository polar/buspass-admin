class ImportExportSitesController < ApplicationController
  layout "websites/normal-layout"

  def index
    if @master
      authenticate_muni_admin!
      @sites = Cms::Site.where(:master_id => @master.id).all
      authorize_muni_admin!(:edit, @master)
    else
      authenticate_customer!
      @sites = Cms::Site.where(:master_id => nil).all
      authorize_customer!(:edit, Cms::Site)
    end
    @importer = ZipfileImporter.new
  end

  def show
  end

  def export
    if @master
      authenticate_muni_admin!
      authorize_muni_admin!(:edit, @master)
    else
      authenticate_customer!
      authorize_customer!(:edit, Cms::Site)
    end
    @site = Cms::Site.find(params[:id])
    begin
      if @site
        dir = Dir.mktmpdir()
        export_all(@site, dir)
        file = Tempfile.new(@site.identifier + ".zip")
        zip(file.path, dir)
        send_file(file.path,
                  :type        => 'application/zip',
                  :filename    => "#{@site.identifier}.zip",
                  :disposition => "inline")

        flash[:notice] = "Site #{@site.identifier} - #{@site.label} has been exported"
      else
        raise "Site #{params[:site_id]} does not exist."
      end
    rescue  => boom
      logger.detailed_error(boom)
      flash[:error] = "Site could not be exported due to error. Check logs"
      redirect_to import_export_sites_path
    end
  end

  def import
    if @master
      authenticate_muni_admin!
      authorize_muni_admin!(:edit, @master)
    else
      authenticate_customer!
      authorize_customer!(:edit, Cms::Site)
    end
    @site = Cms::Site.find(params[:id])
    begin
      @site = Cms::Site.find(params[:id])
      if @site
        @importer = ZipfileImporter.new(params[:zipfile_importer])
        @importer.save
        if @importer.zipfile && @importer.zipfile.path && File.exists?(@importer.zipfile.path)
          dir = Dir.mktmpdir()
          @importer.expand(dir)
          import_all(@site, dir)
          @importer.destroy
          FileUtils.rm_r(dir)
        else
          raise "Cannot access file."
        end
        flash[:notice] = "Site #{@site.identifier} - #{@site.label} has been imported"
      else
        raise "Site #{params[:site_id]} does not exist."
      end
    rescue  => boom
      logger.detailed_error(boom)
      flash[:error] = "Site could not be imported due to error. Check logs"
    end
    redirect_to import_export_sites_path
  end

  protected

    def zip(zip, dir)
      Zip::Archive.open(zip, Zip::CREATE | Zip::TRUNC) do |zip_file|
        Dir.glob("#{dir}/**/*").each do |path|
          zpath = path.sub(/^#{dir}/, ".")
          if File.directory?(path)
            zip_file.add_dir(zpath)
          else
            zip_file.add_file(zpath, path)
          end
        end
      end
    end

    def import_all(site, path)
      import_layouts site, File.join(path, "layouts")
      import_pages site, File.join(path, "pages")
      import_snippets site, File.join(path, "snippets")
      import_files site, File.join(path, "files")
    end

    def export_all(site, path)
      export_layouts site, File.join(path, "layouts")
      export_pages site, File.join(path, "pages")
      export_snippets site, File.join(path, "snippets")
      export_files site, File.join(path, "files")
    end

    def import_layouts(site, path, root = true, parent = nil, layout_ids = [])

      Dir.glob("#{path}/*").select { |f| File.directory?(f) }.each do |path|
        identifier = path.split('/').last
        layout = site.layouts.find_by_identifier(identifier) || site.layouts.build(:identifier => identifier)

        # updating attributes
        if File.exists?(file_path = File.join(path, "_#{identifier}.yml"))
          if layout.new_record? || File.mtime(file_path) > layout.updated_at
            attributes = YAML.load_file(file_path).try(:symbolize_keys!) || { }
            layout.label      = attributes[:label] || identifier.titleize
            layout.app_layout = attributes[:app_layout] || parent.try(:app_layout)
            layout.position = attributes[:position] if attributes[:position]
          end
        elsif layout.new_record?
          layout.label      = identifier.titleize
          layout.app_layout = parent.try(:app_layout)
        end

        # updating content
        if File.exists?(file_path = File.join(path, 'content.html'))
          if layout.new_record? || File.mtime(file_path) > layout.updated_at
            layout.content = File.open(file_path).read
          end
        end
        if File.exists?(file_path = File.join(path, 'css.css'))
          if layout.new_record? || File.mtime(file_path) > layout.updated_at
            layout.css = File.open(file_path).read
          end
        end
        if File.exists?(file_path = File.join(path, 'js.js'))
          if layout.new_record? || File.mtime(file_path) > layout.updated_at
            layout.js = File.open(file_path).read
          end
        end

        # saving
        layout.parent = parent
        if layout.changed?
          if layout.save
            ComfortableMexicanSofa.logger.warn("[Fixtures] Saved Layout {#{layout.identifier}}")
          else
            ComfortableMexicanSofa.logger.error("[Fixtures] Failed to save Layout {#{layout.errors.inspect}}")
            next
          end
        end
        layout_ids << layout.id

        # checking for nested fixtures
        layout_ids += import_layouts(site, path, false, layout, layout_ids)
      end

      # removing all db entries that are not in fixtures
      if root
        site.layouts.excluded(layout_ids.uniq).each { |l| l.destroy }
        ComfortableMexicanSofa.logger.warn('Imported Layouts!')
      end


      # returning ids of layouts in fixtures
      layout_ids.uniq
    end

    def import_pages(site, path, root = true, parent = nil, page_ids = [])

      Dir.glob("#{path}/*").select { |f| File.directory?(f) }.each do |path|
        slug = path.split('/').last
        page = if parent
                 # Since children is gotten from a plugin here, and it needs STI we need to set its type.
                 # parent.children.find_by_slug(slug) || parent.children.build(:slug => slug, :site => site, :type => "Cms::Page")
                 parent.children.find_by_slug(slug) || site.pages.build(:parent => parent, :slug => slug)
               else
                 site.pages.root || site.pages.build(:slug => slug)
               end

        # updating attributes
        if File.exists?(file_path = File.join(path, "_#{slug}.yml"))
          if page.new_record? || File.mtime(file_path) > page.updated_at
            attributes           = YAML.load_file(file_path).try(:symbolize_keys!) || { }
            page.label           = attributes[:label] || slug.titleize
            page.layout          = site.layouts.find_by_identifier(attributes[:layout]) || parent.try(:layout)
            page.target_page     = site.pages.find_by_full_path(attributes[:target_page])
            page.is_published    = attributes[:is_published].present? ? attributes[:is_published] : true
            page.is_protected    = attributes[:is_protected].present? ? attributes[:is_protected] : false
            page.controller_path = attributes[:controller_path].present? ? attributes[:controller_path] : nil
            page.position = attributes[:position] if attributes[:position]
          end
        elsif page.new_record?
          page.label = slug.titleize
          page.layout = parent.try(:layout)
        end

        # updating content
        blocks_to_clear   = page.blocks.collect(&:identifier)
        blocks_attributes = []
        Dir.glob("#{path}/*.html").each do |file_path|
          identifier = file_path.split('/').last.split('.').first
          blocks_to_clear.delete(identifier)
          if page.new_record? || File.mtime(file_path) > page.updated_at
            blocks_attributes << {
                :identifier => identifier,
                :content    => File.open(file_path).read
            }
          end
        end

        # clearing removed blocks
        blocks_to_clear.each do |identifier|
          blocks_attributes << {
              :identifier => identifier,
              :content    => nil
          }
        end

        # saving
        page.blocks_attributes = blocks_attributes if blocks_attributes.present?
        if page.changed? || blocks_attributes.present?
          if page.save
            ComfortableMexicanSofa.logger.warn("[Fixtures] Saved Page {#{page.full_path}}")
          else
            ComfortableMexicanSofa.logger.warn("[Fixtures] Failed to save Page {#{page.errors.inspect}}")
            next
          end
        end
        page_ids << page.id

        # checking for nested fixtures
        page_ids += import_pages(site, path, false, page, page_ids)
      end

      # removing all db entries that are not in fixtures
      if root
        site.pages.excluded(page_ids.uniq).each { |p| p.destroy }
        ComfortableMexicanSofa.logger.warn('Imported Pages!')
      end

      # returning ids of layouts in fixtures
      page_ids.uniq
    end

    def import_snippets(site, path)

      snippet_ids = []
      Dir.glob("#{path}/*").select { |f| File.directory?(f) }.each do |path|
        identifier = path.split('/').last
        snippet = site.snippets.find_by_identifier(identifier) || site.snippets.build(:identifier => identifier)

        # updating attributes
        if File.exists?(file_path = File.join(path, "_#{identifier}.yml"))
          if snippet.new_record? || File.mtime(file_path) > snippet.updated_at
            attributes = YAML.load_file(file_path).try(:symbolize_keys!) || { }
            snippet.label = attributes[:label] || identifier.titleize
          end
        elsif snippet.new_record?
          snippet.label = identifier.titleize
        end

        # updating content
        if File.exists?(file_path = File.join(path, 'content.html'))
          if snippet.new_record? || File.mtime(file_path) > snippet.updated_at
            snippet.content = File.open(file_path).read
          end
        end

        # saving
        if snippet.changed?
          if snippet.save
            ComfortableMexicanSofa.logger.warn("[Fixtures] Saved Snippet {#{snippet.identifier}}")
          else
            ComfortableMexicanSofa.logger.warn("[Fixtures] Failed to save Snippet {#{snippet.errors.inspect}}")
            next
          end
        end
        snippet_ids << snippet.id
      end

      # removing all db entries that are not in fixtures
      site.snippets.excluded(snippet_ids).each { |s| s.destroy }
      ComfortableMexicanSofa.logger.warn('Imported Snippets!')
    end

    def import_files(site, path)
      file_ids = []
      Dir.glob("#{path}/*").select { |f| File.directory?(f) }.each do |filedir|
        pid = File.basename(filedir)
        file = site.files.find_by_persistentid(pid) || site.files.create(:persistent_id => pid)

        # updating attributes
        if File.exists?(file_path = File.join(filedir, "_.yml"))
          attributes = YAML.load_file(file_path).try(:symbolize_keys!) || { }
          file.update_attributes(attributes)
        end

        if site.master
          dest = File.join(Rails.root, "public", "system", "#{site.master.id}", pid)
        else
          dest = File.join(Rails.root, "public", "system", "main", pid)
        end
        FileUtils.rm_r(dest)
        FileUtils.cp_r(filedir, dest)
        FileUtils.rm(File.join(dest, "_.yml"))
        ComfortableMexicanSofa.logger.warn("[Fixtures] Saved File {#{file.label}}")
        file_ids << file.id
      end

      # removing all db entries that are not in fixtures
      site.files.where(:id.nin => file_ids).each { |s| s.destroy }
      ComfortableMexicanSofa.logger.warn('Imported Files!')
    end

    def export_layouts(site, path)
      FileUtils.rm_rf(path)
      FileUtils.mkdir_p(path)

      site.layouts.each do |layout|
        layout_path = File.join(path, layout.ancestors.reverse.collect { |l| l.identifier }, layout.identifier)
        FileUtils.mkdir_p(layout_path)

        open(File.join(layout_path, "_#{layout.identifier}.yml"), 'w') do |f|
          f.write({
                      'label'      => layout.label,
                      'app_layout' => layout.app_layout,
                      'parent'     => layout.parent.try(:identifier),
                      'position'   => layout.position
                  }.to_yaml)
        end
        open(File.join(layout_path, 'content.html'), 'w') do |f|
          f.write(layout.content)
        end
        open(File.join(layout_path, 'css.css'), 'w') do |f|
          f.write(layout.css)
        end
        open(File.join(layout_path, 'js.js'), 'w') do |f|
          f.write(layout.js)
        end
      end
    end

    def export_pages(site, path)
      FileUtils.rm_rf(path)
      FileUtils.mkdir_p(path)

      site.pages.each do |page|
        page.slug = 'index' if page.slug.blank?
        page_path = File.join(path, page.ancestors.reverse.collect { |p| p.slug.blank? ? 'index' : p.slug }, page.slug)
        FileUtils.mkdir_p(page_path)

        open(File.join(page_path, "_#{page.slug}.yml"), 'w') do |f|
          f.write({
                      'label'        => page.label,
                      'layout'       => page.layout.try(:identifier),
                      'parent'       => page.parent && (page.parent.slug.present? ? page.parent.slug : 'index'),
                      'target_page'  => page.target_page.try(:slug),
                      'is_published' => page.is_published,
                      'is_protected' => page.is_protected,
                      'controller_path' => page.controller_path,
                      'position'        => page.position
                  }.to_yaml)
        end
        page.blocks_attributes.each do |block|
          open(File.join(page_path, "#{block[:identifier]}.html"), 'w') do |f|
            f.write(block[:content])
          end
        end
      end
    end

    def export_snippets(site, path)
      FileUtils.rm_rf(path)
      FileUtils.mkdir_p(path)

      site.snippets.each do |snippet|
        FileUtils.mkdir_p(snippet_path = File.join(path, snippet.identifier))
        open(File.join(snippet_path, "_#{snippet.identifier}.yml"), 'w') do |f|
          f.write({ 'label' => snippet.label }.merge(snippet.export_attributes).to_yaml)
        end
        open(File.join(snippet_path, 'content.html'), 'w') do |f|
          f.write(snippet.content)
        end
      end
    end

    def export_files(site, path)
      FileUtils.rm_rf(path)
      FileUtils.mkdir_p(path)

      site.files.each do |file|
        filedir = File.dirname(file.file.path)
        filedir = File.dirname(filedir)
        dest = File.join(path, file.persistentid)
        FileUtils.cp_r(filedir, dest)
        open(File.join(dest, "_.yml"), 'w') do |f|
          f.write({
                      'label' => file.label,
                      "persistentid" => file.persistentid,
                      "file_file_name" => file.file_file_name,
                      "file_content_type" => file.file_content_type,
                      "file_file_size" => file.file_file_name,
                      "description" => file.description,
                      "position" => file.position
                  }.to_yaml)
        end
        puts "Eat shit"
      end
    end

end