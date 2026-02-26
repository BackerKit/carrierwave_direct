# encoding: utf-8

module CarrierWaveDirect
  module Test
    module Helpers
      # Example usage:

      # Returns a presigned-PUT style key for the uploader (store_dir/uuid/uuid).
      # options:
      #   :valid  => false  – returns a malformed key that fails key_regexp
      #   :invalid => true  – alias for :valid => false

      def sample_key(uploader, options = {})
        options[:valid] = true unless options[:valid] == false
        options[:valid] &&= !options[:invalid]
        if options[:valid]
          uploader.key
        else
          # A key that lacks the required uuid/uuid structure
          [uploader.store_dir, "invalid-key-not-uuid"].join("/")
        end
      end
    end
  end
end
