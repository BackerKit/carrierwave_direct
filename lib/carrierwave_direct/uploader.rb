# encoding: utf-8

require "securerandom"
require "carrierwave_direct/uploader/content_type"

module CarrierWaveDirect
  module Uploader
    extend ActiveSupport::Concern

    included do
      storage :fog

      fog_credentials.keys.each do |key|
        define_method(key) do
          fog_credentials[key]
        end
      end
    end

    include CarrierWaveDirect::Uploader::ContentType

    # Ensure that region returns something; required for SigV4 presigned URLs
    def region
      defined?(super) ? super : "us-east-1"
    end

    def acl
      fog_public ? 'public-read' : 'private'
    end

    def presigned_put_url
      credentials = fog_credentials.merge(region: region)
      connection  = Fog::Storage.new(credentials)
      expires_at  = (Time.now + upload_expiration).utc
      headers     = {}
      headers['Content-Type'] = content_type if will_include_content_type
      connection.put_object_url(fog_directory, key, expires_at, headers)
    end

    def url_scheme_white_list
      nil
    end

    def persisted?
      false
    end

    def key
      return @key if @key.present?
      if present?
        identifier = model.send("#{mounted_as}_identifier")
        self.key = [store_dir, identifier].join("/")
      else
        @key = [store_dir, SecureRandom.uuid, SecureRandom.uuid].join("/")
      end
      @key
    end

    def key=(k)
      @key = k
      @key_explicitly_set = k.present?
      update_version_keys(:with => @key)
    end

    def has_key?
      @key_explicitly_set || false
    end

    def key_regexp
      /\A(#{store_dir}|#{cache_dir})\/[a-f\d\-]+\/[a-f\d\-]+\z/
    end

    def extension_regexp
      allowed_file_types = extension_allowlist
      allowed_file_types.present? && allowed_file_types.any? ? "(#{allowed_file_types.join("|")})" : "\\w+"
    end

    def filename
      unless has_key?
        remote_url = model.send("remote_#{mounted_as}_url")
        if remote_url
          key_from_file(CarrierWave::SanitizedFile.new(remote_url).filename)
        else
          return
        end
      end

      key_parts = key.split("/")
      filename  = key_parts.pop
      guid      = key_parts.pop

      filename_parts = []
      filename_parts << guid if guid
      filename_parts << filename
      filename_parts.join("/")
    end

    def direct_fog_url
      CarrierWave::Storage::Fog::File.new(self, CarrierWave::Storage::Fog.new(self), nil).public_url
    end

    private

    def key_from_file(filename)
      new_key_parts = key.split("/")
      new_key_parts.pop
      new_key_parts << filename
      self.key = new_key_parts.join("/")
    end

    # Update the versions to use this key
    def update_version_keys(options)
      versions.each do |name, uploader|
        uploader.key = options[:with]
      end
    end

    # Put the version name at the end of the filename since the guid is also stored
    # e.g. guid/filename_thumb.jpg instead of CarrierWave's default: thumb_guid/filename.jpg
    def full_filename(for_file)
      # When the key is set but identifier is nil (no stored file), use key-derived filename
      for_file ||= filename if has_key?
      return if for_file.nil?
      extname = File.extname(for_file)
      [for_file.chomp(extname), version_name].compact.join('_') << extname
    end
  end
end
