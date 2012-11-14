module Paperclip
  module Interpolations
    def master attachment, style_name
      if (attachment.instance.master)
        attachment.master.id.to_s
      else
        "main"
      end
    end

    def fileid attachment, style_name
      attachment.instance.persistentid
    end
  end
end