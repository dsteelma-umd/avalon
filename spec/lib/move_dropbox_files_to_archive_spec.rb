require 'rails_helper'
require 'fileutils'
require 'move_dropbox_files_to_archive'

def create_dropbox_files
  @temp_dir = Dir.mktmpdir

  @temp_archive_dir = "#{@temp_dir}/archive"
  FileUtils.cp_r('spec/fixtures/move_dropbox_files/', @temp_dir)

  @dropbox_file1 = "#{@temp_dir}/move_dropbox_files/dropbox/Sample_Audio_and_Video/assets/ClassicT1948_512kb.mp4"
  @dropbox_file2 = "#{@temp_dir}/move_dropbox_files/dropbox/Sample_Audio_and_Video/assets/edison_washington_post.mp3"
  @missing_file = "#{@temp_dir}/missing.mp4"

  @archived_file = "#{@temp_archive_dir}/foo/bar/test_archived_file.mp4"

  @master_file_file1 = FactoryBot.create(:master_file, file_location: @dropbox_file1)
  @master_file_dup_file1 = FactoryBot.create(:master_file, file_location: @dropbox_file1)
  @master_file_file2 = FactoryBot.create(:master_file, file_location: @dropbox_file2)
  @master_file_missing = FactoryBot.create(:master_file, file_location: @missing_file)

  @master_file_archived = FactoryBot.create(:master_file, file_location: @archived_file)
end

def destroy_dropbox_files
  FileUtils.remove_entry_secure(@temp_dir, force = false)
end

def expected_file_to_copy(master_file, drop_box_file, move_path)
  FileToCopy.new(master_file_id: master_file.id, old_file_location: drop_box_file,
    new_file_location: File.join(move_path, MasterFile.post_processing_move_relative_filepath(drop_box_file, id: master_file.id)))
end

describe 'MoveDropboxFilesToArchive - Unit tests' do
  before(:each) do
    create_dropbox_files
  end

  describe '#create_file_locations_hash' do
    it 'generates a Hash indexed by MasterFile.file_locations, containing an array of MasterFile.ids that have that location' do
      file_locations_hash = MoveDropboxFilesToArchive.create_file_locations_hash()

      expect(file_locations_hash.count).to eq(4)

      expect(file_locations_hash[@dropbox_file1]).to contain_exactly(@master_file_file1.id, @master_file_dup_file1.id)
      expect(file_locations_hash[@dropbox_file2]).to contain_exactly(@master_file_file2.id)
      expect(file_locations_hash[@missing_file]).to contain_exactly(@master_file_missing.id)
      expect(file_locations_hash[@archived_file]).to contain_exactly(@master_file_archived.id)
    end
  end

  describe '#filter_files' do
    it 'generates a list of skipped files that were already in the archive' do
      file_locations_hash = MoveDropboxFilesToArchive.create_file_locations_hash()
      filter_files_result = MoveDropboxFilesToArchive.filter_files(@temp_archive_dir, file_locations_hash)

      skipped_files = filter_files_result.skipped_files

      expect(skipped_files).to contain_exactly(
        SkippedFile.new(file_location: @archived_file, master_file_ids: [@master_file_archived.id])
      )

      skipped_files.each do |skipped_file|
        expect(skipped_file.file_location).to start_with(@temp_archive_dir)
      end
    end

    it 'generates a list of missing files and associated master_file ids' do
      file_locations_hash = MoveDropboxFilesToArchive.create_file_locations_hash()

      filter_files_result = MoveDropboxFilesToArchive.filter_files(@temp_archive_dir, file_locations_hash)

      missing_file_locations = filter_files_result.missing_files
      expect(missing_file_locations).to contain_exactly(
        MissingFile.new(file_location: @missing_file, master_file_ids: [@master_file_missing.id])
      )
    end

    it 'generates a list of files to move, with associated master_file id' do
      file_locations_hash = MoveDropboxFilesToArchive.create_file_locations_hash()
      filter_files_result = MoveDropboxFilesToArchive.filter_files(@temp_archive_dir, file_locations_hash)

      files_to_copy = filter_files_result.files_to_copy

      expect(files_to_copy).to contain_exactly(
        expected_file_to_copy(@master_file_file1, @dropbox_file1, @temp_archive_dir),
        expected_file_to_copy(@master_file_dup_file1, @dropbox_file1, @temp_archive_dir),
        expected_file_to_copy(@master_file_file2, @dropbox_file2, @temp_archive_dir)
      )

      files_to_copy.each do |file_to_copy|
        expect(file_to_copy.new_file_location).to start_with(@temp_archive_dir)
      end
    end
  end

  describe '#copy_files' do
    it 'copies files to the new location, recording failed and successful copies' do
      file_locations_hash = MoveDropboxFilesToArchive.create_file_locations_hash()
      filter_files_result = MoveDropboxFilesToArchive.filter_files(@temp_archive_dir, file_locations_hash)
      files_to_copy = filter_files_result.files_to_copy

      fail_mkdir_for = File.dirname(files_to_copy[1].new_file_location)
      fail_cp_for = files_to_copy[2]

      allow(FileUtils).to receive(:mkdir_p).and_call_original
      allow(FileUtils).to receive(:mkdir_p).with(fail_mkdir_for).and_raise(Exception)

      allow(FileUtils).to receive(:cp).and_call_original
      allow(FileUtils).to receive(:cp).with(fail_cp_for.old_file_location, fail_cp_for.new_file_location, preserve: true).and_raise(Exception)

      copy_files_result = MoveDropboxFilesToArchive.copy_files(files_to_copy)

      successful_copies = copy_files_result.successful_copies
      failed_copies = copy_files_result.failed_copies

      expected_failed_copy1 = FailedCopy.new(files_to_copy[1].to_h)
      expected_failed_copy1.reason = 'Exception'
      expected_failed_copy2 = FailedCopy.new(files_to_copy[2].to_h)
      expected_failed_copy2.reason = 'Exception'
      expect(failed_copies).to contain_exactly(
        expected_failed_copy1,
        expected_failed_copy2
      )

      expect(successful_copies).to contain_exactly(
        SuccessfulCopy.new(files_to_copy[0].to_h)
      )

      expect(File.exist?(files_to_copy[0].new_file_location)).to be(true)
    end
  end

  describe '#update_master_files' do

    it 'updates the master file location for successfully copied files' do
      successful_copies = [
        SuccessfulCopy.new(master_file_id: @master_file_file1.id, old_file_location: @master_file_file1.file_location, new_file_location: '/archive/file1/file1.mp4'),
        SuccessfulCopy.new(master_file_id: @master_file_dup_file1.id, old_file_location: @master_file_file1.file_location, new_file_location: '/archive/dup_file1.mp4'),
        SuccessfulCopy.new(master_file_id: @master_file_file2.id, old_file_location: @master_file_file2.file_location, new_file_location: '/archive/file2.mp4')
      ]

      # Force failure for @master_file_file2
      allow(MasterFile).to receive(:find).and_call_original
      allow(MasterFile).to receive(:find).with(@master_file_file2.id).and_raise(Exception)

      update_master_files_result = MoveDropboxFilesToArchive.update_master_files(successful_copies)

      expect(update_master_files_result.successful_updates).to contain_exactly(
        SuccessfulUpdate.new(successful_copies[0].to_h),
        SuccessfulUpdate.new(successful_copies[1].to_h)
      )

      expected_failed_update = FailedUpdate.new(successful_copies[2].to_h)
      expected_failed_update.reason = 'Exception'
      expect(update_master_files_result.failed_updates).to contain_exactly(
        expected_failed_update
      )

      expect(@master_file_file1.reload.file_location).to eq('/archive/file1/file1.mp4')
      expect(@master_file_dup_file1.reload.file_location).to eq('/archive/dup_file1.mp4')
    end
  end

  describe '#files_for_deletion' do
    it 'returns the list of files that it safe to delete' do
      file_copy_file1 = FileToCopy.new(master_file_id: 'abc123', old_file_location: '/tmp/file1.mp4', new_file_location: '/archive/ab/c1/23/file1.mp4')
      file_copy_dup_file1 = FileToCopy.new(master_file_id: 'def456', old_file_location: '/tmp/file1.mp4', new_file_location: '/tmp/de/f4/56/file1.mp4')
      file_copy_file2 = FileToCopy.new(master_file_id: 'xzy789', old_file_location: '/tmp/file2.mp4', new_file_location: '/archive/xy/z7/89/file2.mp4')
      file_copy_file3 = FileToCopy.new(master_file_id: 'qrs456', old_file_location: '/tmp/file3.mp4', new_file_location: '/archive/qr/s4/56/file3.mp4')
      file_copy_dup_file3 = FileToCopy.new(master_file_id: 'hij234', old_file_location: '/tmp/file3.mp4', new_file_location: '/archive/hi/j2/34/file3.mp4')

      successful_updates = [
        SuccessfulUpdate.new(file_copy_file1.to_h),
        SuccessfulUpdate.new(file_copy_file2.to_h),
        SuccessfulUpdate.new(file_copy_file3.to_h)
      ]

      failed_copies = [
        FailedCopy.new(file_copy_dup_file1.to_h, reason: 'Exception')
      ]

      failed_updates = [
        FailedUpdate.new(file_copy_dup_file3.to_h, reason: 'Exception')
      ]

      files_for_deletion_result = MoveDropboxFilesToArchive.files_for_deletion(successful_updates, failed_updates, failed_copies)
      files_to_delete = files_for_deletion_result.files_to_delete
      files_to_preserve = files_for_deletion_result.files_to_preserve

      expect(files_to_delete).to contain_exactly(
        FileToDelete.new(file_copy_file2.to_h)
      )

      expect(files_to_preserve).to contain_exactly(
        FileToPreserve.new(file_copy_file1.to_h),
        FileToPreserve.new(file_copy_file3.to_h)
      )
    end
  end

  describe '#delete_files' do
    it 'deletes the files, reporting both successes and failures' do
      files_to_delete = [
        FileToDelete.new(FileToCopy.new(master_file_id: 'abc123', old_file_location: @dropbox_file1, new_file_location: '/archive/ab/c1/23/file1.mp4').to_h),
        FileToDelete.new(FileToCopy.new(master_file_id: 'DOES_NOT_EXIST', old_file_location: '/tmp/DOES_NOT_EXIST', new_file_location: '/archive/DOES_NOT_EXIST').to_h)
      ]

      delete_files_result = MoveDropboxFilesToArchive.delete_files(files_to_delete)

      expect(delete_files_result.successes).to contain_exactly(
        DeletedFile.new(files_to_delete[0].to_h)
      )

      expect(delete_files_result.failures).to contain_exactly(
        DeleteFailed.new(files_to_delete[1].to_h,
                         reason: 'No such file or directory @ apply2files - /tmp/DOES_NOT_EXIST')
      )
    end
  end

  after(:each) do
    destroy_dropbox_files
  end
end

describe 'MoveDropboxFilesToArchive - Integration tests' do
  before(:each) do
    @temp_dir = Dir.mktmpdir
    @temp_archive_dir = "#{@temp_dir}/archive"
    FileUtils.cp_r('spec/fixtures/move_dropbox_files/', @temp_dir)

    @assets_dir = "#{@temp_dir}/move_dropbox_files/dropbox/Sample_Collection/assets"
    @dropbox_success1 = "#{@assets_dir}/sample_success1.mp4"
    @dropbox_success2 = "#{@assets_dir}/sample_success2.mp4"
    @dropbox_two_master_files = "#{@assets_dir}/sample_with_two_master_files.mp4"
    @dropbox_copy_fails = "#{@assets_dir}/sample_copy_fails.mp4"
    @dropbox_update_fails = "#{@assets_dir}/sample_master_file_update_fails.mp4"
    @dropbox_delete_fails = "#{@assets_dir}/sample_delete_fails.mp4"

    @dropbox_missing = "#{@assets_dir}/missing.mp4"
    @archived_file = "#{@temp_archive_dir}/sample_archived.mp4"

    @master_file_success1 = FactoryBot.create(:master_file, file_location: @dropbox_success1)
    @master_file_success2 = FactoryBot.create(:master_file, file_location: @dropbox_success2)
    @master_file_two_master_files1 = FactoryBot.create(:master_file, file_location: @dropbox_two_master_files)
    @master_file_two_master_files2 = FactoryBot.create(:master_file, file_location: @dropbox_two_master_files)
    @master_file_copy_fails = FactoryBot.create(:master_file, file_location: @dropbox_copy_fails)
    @master_file_update_fails = FactoryBot.create(:master_file, file_location: @dropbox_update_fails)
    @master_file_delete_fails = FactoryBot.create(:master_file, file_location: @dropbox_delete_fails)

    @master_file_missing = FactoryBot.create(:master_file, file_location: @dropbox_missing)
    @master_file_archived = FactoryBot.create(:master_file, file_location: @archived_file)

    # Force copy_files failure for master_file_copy_fails
    allow(FileUtils).to receive(:cp).and_call_original
    allow(FileUtils).to receive(:cp).with(@master_file_copy_fails.file_location, anything, preserve: true).and_raise(Exception)

    # Force update_master_files failure for master_file_update_fails
    allow(MasterFile).to receive(:find).and_call_original
    allow(MasterFile).to receive(:find).with(@master_file_update_fails.id).and_raise(Exception)

    # Force delete_files failure for master_file_delete_fails
    allow(FileUtils).to receive(:rm).and_call_original
    allow(FileUtils).to receive(:rm).with(@master_file_delete_fails.file_location).and_raise(Exception)

    # Expected location of archived files
    @expected_archived_file_success1 = File.join(@temp_archive_dir, MasterFile.post_processing_move_relative_filepath(@dropbox_success1, id: @master_file_success1.id))
    @expected_archived_file_success2 = File.join(@temp_archive_dir, MasterFile.post_processing_move_relative_filepath(@dropbox_success2, id: @master_file_success2.id))
    @expected_archived_file_two_master_files1 = File.join(@temp_archive_dir, MasterFile.post_processing_move_relative_filepath(@dropbox_two_master_files, id: @master_file_two_master_files1.id))
    @expected_archived_file_two_master_files2 = File.join(@temp_archive_dir, MasterFile.post_processing_move_relative_filepath(@dropbox_two_master_files, id: @master_file_two_master_files2.id))
    @expected_archived_file_copy_fails = File.join(@temp_archive_dir, MasterFile.post_processing_move_relative_filepath(@dropbox_copy_fails, id: @master_file_copy_fails.id))
    @expected_archived_file_update_fails = File.join(@temp_archive_dir, MasterFile.post_processing_move_relative_filepath(@dropbox_update_fails, id: @master_file_update_fails.id))
    @expected_archived_file_delete_fails = File.join(@temp_archive_dir, MasterFile.post_processing_move_relative_filepath(@dropbox_delete_fails, id: @master_file_delete_fails.id))
  end

  describe '#perform' do
    it 'an actual run correctly moves the files and updates the MasterFile records' do
      perform_result = MoveDropboxFilesToArchive.perform(@temp_dir, @temp_archive_dir)

      # file_locations_hash
      file_locations_hash = perform_result.file_locations_hash

      expect(file_locations_hash.length).to eq(8)
      expect(file_locations_hash).to match(
        {
          "#{@dropbox_success1}": [@master_file_success1.id],
          "#{@dropbox_success2}": [@master_file_success2.id],
          "#{@dropbox_two_master_files}": [@master_file_two_master_files1.id, @master_file_two_master_files2.id],
          "#{@dropbox_copy_fails}": [@master_file_copy_fails.id],
          "#{@dropbox_update_fails}": [@master_file_update_fails.id],
          "#{@dropbox_delete_fails}": [@master_file_delete_fails.id],
          "#{@dropbox_missing}": [@master_file_missing.id],
          "#{@archived_file}": [@master_file_archived.id]
        }.with_indifferent_access
      )

      # filter_files_result
      filter_files_result = perform_result.filter_files_result
      files_to_copy = filter_files_result.files_to_copy
      missing_files = filter_files_result.missing_files
      skipped_files = filter_files_result.skipped_files

      expect(files_to_copy.length).to eq (7)
      expect(files_to_copy).to contain_exactly(
        expected_file_to_copy(@master_file_success1, @dropbox_success1, @temp_archive_dir),
        expected_file_to_copy(@master_file_success2, @dropbox_success2, @temp_archive_dir),
        expected_file_to_copy(@master_file_two_master_files1, @dropbox_two_master_files, @temp_archive_dir),
        expected_file_to_copy(@master_file_two_master_files2, @dropbox_two_master_files, @temp_archive_dir),
        expected_file_to_copy(@master_file_copy_fails, @dropbox_copy_fails, @temp_archive_dir),
        expected_file_to_copy(@master_file_update_fails, @dropbox_update_fails, @temp_archive_dir),
        expected_file_to_copy(@master_file_delete_fails, @dropbox_delete_fails, @temp_archive_dir)
      )

      expect(missing_files.length).to eq(1)
      expect(missing_files).to contain_exactly(
        MissingFile.new(file_location: @dropbox_missing, master_file_ids: [@master_file_missing.id])
      )

      expect(skipped_files.length).to eq(1)
      expect(skipped_files).to contain_exactly(
        SkippedFile.new(file_location: @archived_file, master_file_ids: [@master_file_archived.id])
      )

      # copy_files_result
      copy_files_result = perform_result.copy_files_result
      successful_copies = copy_files_result.successful_copies
      failed_copies = copy_files_result.failed_copies

      expect(successful_copies.length). to eq(6)
      expect(successful_copies).to contain_exactly(
        SuccessfulCopy.new(master_file_id: @master_file_success1.id, old_file_location: @master_file_success1.file_location, new_file_location: @expected_archived_file_success1),
        SuccessfulCopy.new(master_file_id: @master_file_success2.id, old_file_location: @master_file_success2.file_location, new_file_location:  @expected_archived_file_success2),
        SuccessfulCopy.new(master_file_id: @master_file_two_master_files1.id, old_file_location: @master_file_two_master_files1.file_location, new_file_location: @expected_archived_file_two_master_files1),
        SuccessfulCopy.new(master_file_id: @master_file_two_master_files2.id, old_file_location: @master_file_two_master_files2.file_location, new_file_location: @expected_archived_file_two_master_files2),
        SuccessfulCopy.new(master_file_id: @master_file_update_fails.id, old_file_location: @master_file_update_fails.file_location, new_file_location: @expected_archived_file_update_fails),
        SuccessfulCopy.new(master_file_id: @master_file_delete_fails.id, old_file_location: @master_file_delete_fails.file_location, new_file_location: @expected_archived_file_delete_fails)
      )

      expect(failed_copies.length). to eq(1)
      expect(failed_copies).to contain_exactly(
        FailedCopy.new(master_file_id: @master_file_copy_fails.id, old_file_location: @master_file_copy_fails.file_location, new_file_location: @expected_archived_file_copy_fails, reason: 'Exception')
      )

      # update_master_files_result
      update_master_files_result = perform_result.update_master_files_result
      successful_updates = update_master_files_result.successful_updates
      failed_updates = update_master_files_result.failed_updates

      expect(successful_updates.length).to eq(5)
      expect(successful_updates).to contain_exactly(
        SuccessfulUpdate.new(master_file_id: @master_file_success1.id, old_file_location: @master_file_success1.file_location, new_file_location: @expected_archived_file_success1),
        SuccessfulUpdate.new(master_file_id: @master_file_success2.id, old_file_location: @master_file_success2.file_location, new_file_location:  @expected_archived_file_success2),
        SuccessfulUpdate.new(master_file_id: @master_file_two_master_files1.id, old_file_location: @master_file_two_master_files1.file_location, new_file_location: @expected_archived_file_two_master_files1),
        SuccessfulUpdate.new(master_file_id: @master_file_two_master_files2.id, old_file_location: @master_file_two_master_files2.file_location, new_file_location: @expected_archived_file_two_master_files2),
        SuccessfulUpdate.new(master_file_id: @master_file_delete_fails.id, old_file_location: @master_file_delete_fails.file_location, new_file_location: @expected_archived_file_delete_fails)
      )

      # "file_location" in successfully updated MasterFiles should be updated
      expect(@master_file_success1.reload.file_location).to eq(@expected_archived_file_success1)
      expect(@master_file_success2.reload.file_location).to eq(@expected_archived_file_success2)
      expect(@master_file_two_master_files1.reload.file_location).to eq(@expected_archived_file_two_master_files1)
      expect(@master_file_two_master_files2.reload.file_location).to eq(@expected_archived_file_two_master_files2)
      expect(@master_file_delete_fails.reload.file_location).to eq(@expected_archived_file_delete_fails)

      expect(failed_updates.length).to eq(1)
      expect(failed_updates).to contain_exactly(
        FailedUpdate.new(master_file_id: @master_file_update_fails.id, old_file_location: @dropbox_update_fails, new_file_location: @expected_archived_file_update_fails, reason: 'Exception')
      )

      # "file_location" of MasterFile for failed update should not be changed
      expect(@master_file_update_fails.reload.file_location).to eq(@dropbox_update_fails)

      # # files_for_deletion
      # files_for_deletion_result = perform_result.files_for_deletion_result
      # files_to_delete = files_for_deletion_result.files_to_delete
      # files_to_preserve = files_for_deletion_result.files_to_preserve

      # expect(files_to_delete.length).to eq(4)
      # except(file_to_delete).to contain_exactly(
      #   FileToDelete.new(master_file_id: master_file_success1, old_file_location: @dropbox_success1, new_file_location: @expected_archived_file_success1)
      #   FileToDelete.new(master_file_id: master_file_success2, old_file_location: @dropbox_success2, new_file_location: @expected_archived_file_success2)
      #   FileToDelete.new(master_file_id: master_file_success2, old_file_location: @dropbox_success2, new_file_location: @expected_archived_file_success2)
    end
  end

  after(:each) do
    FileUtils.remove_entry_secure(@temp_dir, force = false)
  end
end
