# encoding: utf-8

require 'spec_helper'

describe CarrierWaveDirect::Test::Helpers do
  include CarrierWaveDirect::Test::Helpers

  describe "#sample_key" do
    context "passing an instance of DirectUploader mounted as a video" do
      let(:direct_uploader) { MountedClass.new.video }

      context "with no options (valid key)" do
        it "should return a key matching key_regexp" do
          expect(sample_key(direct_uploader)).to match(direct_uploader.key_regexp)
        end

        it "should use the uploader's auto-generated key" do
          expect(sample_key(direct_uploader)).to eq(direct_uploader.key)
        end
      end

      context "with :valid => false" do
        it "should return a key that does not match key_regexp" do
          expect(sample_key(direct_uploader, :valid => false)).to_not match(direct_uploader.key_regexp)
        end
      end

      context "with :invalid => true" do
        it "should return a key that does not match key_regexp" do
          expect(sample_key(direct_uploader, :invalid => true)).to_not match(direct_uploader.key_regexp)
        end
      end
    end
  end
end
