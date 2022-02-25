namespace :umd do
  desc "Move master files from dropbox directory to archive"
  task move_dropbox_files_to_archive: :environment do
  end
end

class MoveDropboxFilesToArchive
  def self.create_dropbox_files_map()
    # Returns a Hash indexed by MasterFile.file_locations, containing an array
    # of MasterFile.ids that have that location
    dropbox_files_hash = {}
    MasterFile.all.each do |master_file|
      file_location = master_file.file_location
      if file_location
        entry = dropbox_files_hash.fetch(file_location, [])
        entry.push(master_file.id)
      end
    end
    dropbox_files_hash
  end
end