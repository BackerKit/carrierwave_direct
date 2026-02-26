# encoding: utf-8

module CarrierWaveDirect

  module ActionViewExtensions
    # This module creates direct upload forms to post to cloud services
    #
    # Example:
    #
    #   direct_upload_form_for @video_uploader do |f|
    #     f.file_field :video
    #     f.submit
    #   end
    #
    module FormHelper

      def direct_upload_form_for(record, *args, &block)
        options = args.extract_options!

        # Default the form action to '#' when no URL is supplied.
        # The actual S3 upload is performed by JavaScript using the
        # presigned PUT URL from data-presigned-url; the form then
        # submits the resulting key back to the Rails app.
        options[:url] ||= '#'

        html_options = {
          data: {
            presigned_url: record.presigned_put_url,
            upload_key:    record.key
          }
        }.deep_merge(options.delete(:html) || {})

        form_for(
          record,
          *(args << options.merge(
            builder:    CarrierWaveDirect::FormBuilder,
            html:       html_options,
            include_id: false
          )),
          &block
        )
      end
    end
  end
end

ActionView::Base.send :include, CarrierWaveDirect::ActionViewExtensions::FormHelper
