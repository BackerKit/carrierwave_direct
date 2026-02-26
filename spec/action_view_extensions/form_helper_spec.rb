# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::ActionViewExtensions::FormHelper do
  include FormBuilderHelpers

  describe "#direct_upload_form_for" do
    it "should yield an instance of CarrierWaveDirect::FormBuilder" do
      direct_upload_form_for(direct_uploader) do |f|
        expect(f).to be_instance_of(CarrierWaveDirect::FormBuilder)
      end
    end

    context "the form" do
      before do
        allow(direct_uploader).to receive(:presigned_put_url).and_return("https://bucket.s3.amazonaws.com/key?X-Amz-Signature=abc")
      end

      it "should have a data-presigned-url attribute on the form" do
        html = form
        expect(html).to include('data-presigned-url="https://bucket.s3.amazonaws.com/key?X-Amz-Signature=abc"')
      end

      it "should have a data-upload-key attribute on the form" do
        allow(direct_uploader).to receive(:key).and_return("uploads/uuid1/uuid2")
        html = form
        expect(html).to include('data-upload-key="uploads/uuid1/uuid2"')
      end

      it "should include any html options passed through :html" do
        html = form(:html => { :target => "_blank_iframe" })
        expect(html).to include('target="_blank_iframe"')
      end
    end
  end
end
