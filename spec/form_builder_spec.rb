# encoding: utf-8

require 'spec_helper'
require 'erb'

class CarrierWaveDirect::FormBuilder
  attr_accessor :template, :object

  public :content_choices_options
end

describe CarrierWaveDirect::FormBuilder do
  include FormBuilderHelpers

  describe "#file_field" do
    def form_with_default_file_field
      form {|f| f.file_field :video }
    end

    context "form" do
      subject { form_with_default_file_field }

      it "should have a hidden field for 'key'" do
        allow(direct_uploader).to receive(:key).and_return("some/key/value")
        expect(subject).to have_input(
          :direct_uploader,
          :key,
          :type     => :hidden,
          :name     => "key",
          :value    => "some/key/value",
          :required => false
        )
      end

      it "should have an input for a file to upload" do
        expect(subject).to have_input(
          :direct_uploader,
          :video,
          :type     => :file,
          :name     => :file,
          :required => false
        )
      end

      it "should NOT have policy hidden fields (no acl, policy, signature, etc.)" do
        %w[acl policy signature credential algorithm].each do |field|
          expect(subject).not_to have_input(:direct_uploader, field.to_sym, :type => :hidden)
        end
      end
    end
  end

  describe "#fields_except_file_field" do
    it "should render the hidden key field" do
      allow(direct_uploader).to receive(:key).and_return("some/key/value")
      form_dom = form {|f| f.fields_except_file_field }
      expect(form_dom).to have_input(
        :direct_uploader,
        :key,
        :type     => :hidden,
        :name     => "key",
        :value    => "some/key/value",
        :required => false
      )
    end

    it "should not render extra policy fields" do
      dom = form {|f| f.fields_except_file_field }
      %w[acl policy signature credential algorithm].each do |field|
        expect(dom).not_to have_input(:direct_uploader, field.to_sym, :type => :hidden)
      end
    end
  end

  describe "#content_type_select" do
    context "form" do
      subject do
        form do |f|
          f.content_type_select
        end
      end

      before do
        allow(direct_uploader.class).to receive(:will_include_content_type).and_return(true)
      end

      it 'should select the default content type' do
        allow(direct_uploader).to receive(:content_type).and_return('video/mp4')
        expect(subject).to have_content_type 'video/mp4', true
      end

      it 'should include the default content types' do
        allow(direct_uploader).to receive(:content_types).and_return(['text/foo','text/bar'])
        expect(subject).to have_content_type 'text/foo', false
        expect(subject).to have_content_type 'text/bar', false
      end

      it 'should select the passed in content type' do
        dom = form {|f| f.content_type_select nil, 'video/mp4'}
        expect(dom).to have_content_type 'video/mp4', true
      end

      it 'should include most content types' do
        %w(application/atom+xml application/ecmascript application/json
           application/javascript application/octet-stream application/ogg
           application/pdf application/postscript application/rss+xml
           application/font-woff application/xhtml+xml application/xml
           application/xml-dtd application/zip application/gzip audio/basic
           audio/mp4 audio/mpeg audio/ogg audio/vorbis audio/vnd.rn-realaudio
           audio/vnd.wave audio/webm image/gif image/jpeg image/pjpeg
           image/png image/svg+xml image/tiff text/cmd text/css text/csv
           text/html text/javascript text/plain text/vcard text/xml video/mpeg
           video/mp4 video/ogg video/quicktime video/webm video/x-matroska
           video/x-ms-wmv video/x-flv).each do |type|
          expect(subject).to have_content_type type
        end
      end
    end
  end

  describe "#content_type_label" do
    context "form" do
      subject do
        form {|f| f.content_type_label }
      end

      it 'should render a label for content_type' do
        expect(subject).to include('Content-Type')
      end
    end
  end

  describe 'full form' do
    it 'should only have the key hidden field once (no duplicate or policy fields)' do
      allow(direct_uploader).to receive(:key).and_return("some/key/value")
      full = form {|f| f.file_field :video }
      key_inputs = Nokogiri::HTML(full).css('input[name="key"]')
      expect(key_inputs.count).to eq 1
    end
  end
end
