class MoveDropboxFilesToArchive
  def self.create_file_locations_hash()
    # Returns a Hash indexed by MasterFile.file_locations, containing an array
    # of MasterFile.ids that have that location
    file_locations_hash = {}
    MasterFile.all.each do |master_file|
      file_location = master_file.file_location
      if file_location
        entry = file_locations_hash.fetch(file_location, [])
        entry.push(master_file.id)
        file_locations_hash[file_location] = entry
      end
    end
    file_locations_hash
  end

  def self.filter_files(archive_dir, file_locations_hash)
    skipped_files = []
    missing_files = []
    files_to_copy = []
    file_locations_hash.each do |file_location, master_file_ids|
      if file_location.start_with?(archive_dir)
        skipped_files.push(SkippedFile.new(file_location: file_location, master_file_ids: master_file_ids))
        next
      end

      unless File.exist?(file_location)
        missing_files.push(MissingFile.new(file_location: file_location, master_file_ids: master_file_ids))
        next
      end

      master_file_ids.each do |master_file_id|
        new_file_location = File.join(archive_dir, MasterFile.post_processing_move_relative_filepath(file_location, { id: master_file_id }))

        files_to_copy.push(FileToCopy.new(
          master_file_id: master_file_id,
          old_file_location: file_location,
          new_file_location: new_file_location
        ))
      end
    end
    FilterFilesResult.new(files_to_copy: files_to_copy, missing_files: missing_files, skipped_files: skipped_files)
  end

  def self.copy_files(files_to_copy)
    successful_copies = []
    failed_copies = []
    files_to_copy.each do |file_to_copy|
      old_file_location = file_to_copy.old_file_location
      new_file_location = file_to_copy.new_file_location

      begin
        FileUtils.mkdir_p(File.dirname(new_file_location))
        FileUtils.cp(old_file_location, new_file_location, preserve: true)

        successful_copies.push(SuccessfulCopy.new(file_to_copy.to_h))
      rescue Exception => e
        failed_copy = FailedCopy.new(file_to_copy.to_h)
        failed_copy.reason = e.message
        failed_copies.push(failed_copy)
      end
    end
    CopyFilesResult.new(successful_copies: successful_copies, failed_copies: failed_copies)
  end

  def self.update_master_files(successful_copies)
    successful_updates = []
    failed_updates = []

    successful_copies.each do |successful_copy|
      master_file_id = successful_copy.master_file_id
      new_file_location = successful_copy.new_file_location

      begin
        master_file = MasterFile.find(master_file_id)
        master_file.file_location = new_file_location
        master_file.save!
        successful_updates.push(SuccessfulUpdate.new(successful_copy.to_h))
      rescue Exception => e
        failed_update = FailedUpdate.new(successful_copy.to_h)
        failed_update.reason = e.message
        failed_updates.push(failed_update)
      end
    end
    UpdateMasterFilesResult.new(successful_updates: successful_updates, failed_updates: failed_updates)
  end

  def self.files_for_deletion(successful_updates, failed_updates, failed_copies)
    # Returns a list of files for deletion
    # A file can be safely deleted if:
    #   * It is referenced by a successful MasterFile update,
    #   * It is not referenced by a failed copy, or failed MasterFile update
    successful_file_locations = successful_updates.map { |s| s.old_file_location }
    failed_file_locations = failed_copies.map { |f| f.old_file_location } + failed_updates.map { |f| f.old_file_location }
    file_locations_to_delete = successful_file_locations - failed_file_locations

    files_to_delete = []
    files_to_preserve = []

    successful_updates.each do |s|
      if file_locations_to_delete.include?(s.old_file_location)
        files_to_delete.push(FileToDelete.new(s.to_h))
      else
        files_to_preserve.push(FileToPreserve.new(s.to_h))
      end
    end
    return FilesForDeletionResult.new(files_to_delete: files_to_delete, files_to_preserve: files_to_preserve)
  end

  def self.delete_files(files_to_delete)
    deleted_files = []
    failed_deletes = []
    files_to_delete.each do |file_to_delete|
      old_file_location = file_to_delete.old_file_location
      begin
        FileUtils.rm(old_file_location)
        deleted_files.push(DeletedFile.new(file_to_delete.to_h))
      rescue Exception => e
        failed_delete = DeleteFailed.new(file_to_delete.to_h, reason: e.message)
        failed_deletes.push(failed_delete)
      end
    end
    return DeleteFilesResult.new(successes: deleted_files, failures: failed_deletes)
  end

  def self.perform(dropbox_dir, archive_dir)
    file_locations_hash = self.create_file_locations_hash()
    filter_files_result = self.filter_files(archive_dir, file_locations_hash)
    copy_files_result = self.copy_files(filter_files_result.files_to_copy)
    update_master_files_result = self.update_master_files(copy_files_result.successful_copies)
    PerformResult.new(file_locations_hash: file_locations_hash, filter_files_result: filter_files_result,
                      copy_files_result: copy_files_result, update_master_files_result: update_master_files_result)
  end
end

FileToCopy = Struct.new(:master_file_id, :old_file_location, :new_file_location, keyword_init: true)
SkippedFile = Struct.new(:file_location, :master_file_ids, keyword_init: true)
MissingFile = Struct.new(:file_location, :master_file_ids, keyword_init: true)
FilterFilesResult = Struct.new(:files_to_copy, :missing_files, :skipped_files, keyword_init: true)

SuccessfulCopy = Struct.new(:master_file_id, :old_file_location, :new_file_location, keyword_init: true)
FailedCopy = Struct.new(:master_file_id, :old_file_location, :new_file_location, :reason, keyword_init: true)
CopyFilesResult = Struct.new(:successful_copies, :failed_copies, keyword_init: true)

SuccessfulUpdate = Struct.new(:master_file_id, :old_file_location, :new_file_location, keyword_init: true)
FailedUpdate = Struct.new(:master_file_id, :old_file_location, :new_file_location, :reason, keyword_init: true)
UpdateMasterFilesResult= Struct.new(:successful_updates, :failed_updates, keyword_init: true)

FileToDelete = Struct.new(:master_file_id, :old_file_location, :new_file_location, keyword_init: true)
FileToPreserve = Struct.new(:master_file_id, :old_file_location, :new_file_location, :reason, keyword_init: true)
FilesForDeletionResult = Struct.new(:files_to_delete, :files_to_preserve, keyword_init: true)

DeletedFile = Struct.new(:master_file_id, :old_file_location, :new_file_location, keyword_init: true)
DeleteFailed = Struct.new(:master_file_id, :old_file_location, :new_file_location, :reason, keyword_init: true)
DeleteFilesResult = Struct.new(:successes, :failures, keyword_init: true)

PerformResult = Struct.new(:file_locations_hash, :filter_files_result,
                           :copy_files_result, :update_master_files_result,
                           :files_for_deletion_result, :delete_files_result,
                           keyword_init: true)
