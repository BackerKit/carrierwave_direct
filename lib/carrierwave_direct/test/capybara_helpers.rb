# encoding: utf-8

module CarrierWaveDirect
  module Test
    module CapybaraHelpers

      include CarrierWaveDirect::Test::Helpers

      def attach_file_for_direct_upload(path)
        attach_file("file", path)
      end

      # Finds the hidden S3 key input value set by the form builder.
      def find_key
        page.find("input[name='key']", visible: false).value
      end

      # Finds the presigned PUT URL from the form's data-presigned-url attribute.
      def find_presigned_url
        page.find("form[data-presigned-url]", visible: false)["data-presigned-url"]
      end

    end
  end
end
