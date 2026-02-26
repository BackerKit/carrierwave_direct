# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::Test::CapybaraHelpers do
  class ExampleSpec
    include CarrierWaveDirect::Test::CapybaraHelpers
  end

  let(:subject) { ExampleSpec.new }
  let(:page) { double("Page").as_null_object }
  let(:selector) { double("Selector") }

  def stub_page
    allow(subject).to receive(:page).and_return(page)
  end

  def find_element_value(css, value, **options)
    if options.keys.any?
      allow(page).to receive(:find).with(css, options).and_return(selector)
    else
      allow(page).to receive(:find).with(css).and_return(selector)
    end
    allow(selector).to receive(:value).and_return(value)
  end

  describe "#attach_file_for_direct_upload" do
    context "'path/to/file.ext'" do
      it "should attach a file with the locator => 'file'" do
        expect(subject).to receive(:attach_file).with("file", "path/to/file.ext")
        subject.attach_file_for_direct_upload "path/to/file.ext"
      end
    end
  end

  describe "#find_key" do
    before do
      stub_page
      find_element_value("input[name='key']", "key", visible: false)
    end

    it "should try to find the key on the page" do
      expect(subject.find_key).to eq "key"
    end
  end

  describe "#find_presigned_url" do
    let(:form_element) { double("FormElement") }

    before do
      stub_page
      allow(page).to receive(:find).with("form[data-presigned-url]", visible: false).and_return(form_element)
      allow(form_element).to receive(:[]).with("data-presigned-url").and_return("https://bucket.s3.amazonaws.com/key?X-Amz-Signature=abc")
    end

    it "should return the presigned PUT URL from the form's data attribute" do
      expect(subject.find_presigned_url).to eq "https://bucket.s3.amazonaws.com/key?X-Amz-Signature=abc"
    end
  end
end
