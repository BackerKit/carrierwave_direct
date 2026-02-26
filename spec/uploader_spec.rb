# encoding: utf-8
require 'spec_helper'
require 'data/sample_data'

describe CarrierWaveDirect::Uploader do
  include UploaderHelpers
  include ModelHelpers

  let(:subject) { DirectUploader.new }
  let(:mounted_model) { MountedClass.new }
  let(:mounted_subject) { DirectUploader.new(mounted_model, sample(:mounted_as)) }

  DirectUploader.fog_credentials.keys.each do |key|
    describe "##{key}" do
      it "should return the #{key.to_s.capitalize}" do
        expect(subject.send(key)).to eq subject.class.fog_credentials[key]
      end

      it "should not be nil" do
        expect(subject.send(key)).to_not be_nil
      end
    end
  end

  describe "#key=" do
    before { subject.key = sample(:key) }

    it "should set the key" do
      expect(subject.key).to eq sample(:key)
    end

    context "the versions keys" do
      it "should == this subject's key" do
        subject.versions.each do |name, version_subject|
          expect(version_subject.key).to eq subject.key
        end
      end
    end
  end

  describe "#key" do
    context "where the key is not set" do
      before do
        mounted_subject.key = nil
      end

      it "should return '*/guid/guid'" do
        expect(mounted_subject.key).to match /#{GUID_REGEXP}\/#{GUID_REGEXP}$/
      end

      context "and #store_dir returns '#{sample(:store_dir)}'" do
        before do
          allow(mounted_subject).to receive(:store_dir).and_return(sample(:store_dir))
        end

        it "should return '#{sample(:store_dir)}/guid/guid'" do
          expect(mounted_subject.key).to match /^#{sample(:store_dir)}\/#{GUID_REGEXP}\/#{GUID_REGEXP}$/
        end
      end

      context "and the uploaders url is #default_url" do
        it "should return '*/guid/guid'" do
          allow(mounted_subject).to receive(:url).and_return(sample(:s3_file_url))
          allow(mounted_subject).to receive(:present?).and_return(false)
          expect(mounted_subject.key).to match /#{GUID_REGEXP}\/#{GUID_REGEXP}$/
        end
      end

      context "but the uploaders url is '#{sample(:s3_file_url)}'" do
        before do
          allow(mounted_subject).to receive(:store_dir).and_return(sample(:store_dir))
          allow(mounted_subject).to receive(:present?).and_return(true)
          allow(mounted_model).to   receive(:video_identifier).and_return(sample(:stored_filename))
          mounted_model.remote_video_url = sample(:s3_file_url)
        end

        it "should return '#{sample(:s3_key)}'" do
          expect(mounted_subject.key).to eq sample(:s3_key)
        end

        it "should set the key explicitly in order to update the version keys" do
          expect(mounted_subject).to receive("key=").with(sample(:s3_key))
          mounted_subject.key
        end
      end
    end

    context "where the key is set to '#{sample(:key)}'" do
      before { subject.key = sample(:key) }

      it "should return '#{sample(:key)}'" do
        expect(subject.key).to eq sample(:key)
      end
    end
  end

  describe "#url_scheme_white_list" do
    it "should return nil" do
      expect(subject.url_scheme_white_list).to be_nil
    end
  end

  describe "#direct_fog_url" do
    it "should return the result from CarrierWave::Storage::Fog::File#public_url" do
      expected_url = "https://AWS_FOG_DIRECTORY.s3.amazonaws.com/"
      allow_any_instance_of(CarrierWave::Storage::Fog::File).to receive(:public_url).and_return(expected_url)
      expect(subject.direct_fog_url).to eq expected_url
    end
  end

  describe "#presigned_put_url" do
    it "should return a presigned S3 PUT URL string" do
      fake_connection = double("FogConnection")
      allow(fake_connection).to receive(:put_object_url).and_return(
        "https://AWS_FOG_DIRECTORY.s3.amazonaws.com/path/to/key?X-Amz-Signature=abc"
      )
      allow(Fog::Storage).to receive(:new).and_return(fake_connection)
      url = subject.presigned_put_url
      expect(url).to be_a(String)
      expect(url).to start_with("https://")
    end

    it "should use the upload_expiration for the URL expiry" do
      received_expires = nil
      fake_connection = double("FogConnection")
      allow(fake_connection).to receive(:put_object_url) do |_bucket, _key, expires, _headers|
        received_expires = expires
        "https://example.com/presigned"
      end
      allow(Fog::Storage).to receive(:new).and_return(fake_connection)
      Timecop.freeze(Time.now) do
        subject.presigned_put_url
        expect(received_expires).to be_within(1.second).of(Time.now.utc + DirectUploader.upload_expiration)
      end
    end
  end

  describe "#key_regexp" do
    it "should return a regexp" do
      expect(subject.key_regexp).to be_a(Regexp)
    end

    context "where #store_dir returns '#{sample(:store_dir)}'" do
      before do
        allow(subject).to receive(:store_dir).and_return(sample(:store_dir))
        allow(subject).to receive(:cache_dir).and_return(sample(:cache_dir))
      end

      it "should match keys of the form store_dir/guid/guid" do
        expect(subject.key_regexp).to eq /\A(#{sample(:store_dir)}|#{sample(:cache_dir)})\/#{GUID_REGEXP}\/#{GUID_REGEXP}\z/
      end
    end
  end

  describe "#extension_regexp" do
    shared_examples_for "a globally allowed file extension" do
      it "should return '\\w+'" do
        expect(subject.extension_regexp).to eq "\\w+"
      end
    end

    it "should return a string" do
      expect(subject.extension_regexp).to be_a(String)
    end

    context "where #extension_allowlist returns nil" do
      before do
        allow(subject).to receive(:extension_allowlist).and_return(nil)
      end

      it_should_behave_like "a globally allowed file extension"
    end

    context "where #extension_allowlist returns []" do
      before do
        allow(subject).to receive(:extension_allowlist).and_return([])
      end

      it_should_behave_like "a globally allowed file extension"
    end

    context "where #extension_allowlist returns ['exe', 'bmp']" do

      before do
        allow(subject).to receive(:extension_allowlist).and_return(%w{exe bmp})
      end

      it "should return '(exe|bmp)'" do
        expect(subject.extension_regexp).to eq "(exe|bmp)"
      end
    end
  end

  describe "#has_key?" do
    context "a key has not been set" do

      it "should return false" do
        expect(subject).to_not have_key
      end
    end

    context "the key has been autogenerated" do
      before { subject.key }

      it "should return false" do
        expect(subject).to_not have_key
      end
    end

    context "the key has been set" do
      before { subject.key = sample_key }

      it "should return true" do
        expect(subject).to have_key
      end
    end
  end

  describe "#persisted?" do
    it "should return false" do
      expect(subject).to_not be_persisted
    end
  end

  describe "#filename" do
    context "key is set to '#{sample(:s3_key)}'" do
      before { mounted_subject.key = sample(:s3_key) }

      it "should return '#{sample(:stored_filename)}'" do
        expect(mounted_subject.filename).to eq sample(:stored_filename)
      end
    end

    context "key is set to '#{sample(:key)}'" do
      before { subject.key = sample(:key) }

      it "should return '#{sample(:key)}'" do
        expect(subject.filename).to eq sample(:key)
      end
    end

    context "key is not set" do
      context "but the model's remote #{sample(:mounted_as)} url is: '#{sample(:file_url)}'" do

        before do
          allow(mounted_subject.model).to receive(
            "remote_#{mounted_subject.mounted_as}_url"
          ).and_return(sample(:file_url))
        end

        it "should set the key to contain '#{File.basename(sample(:file_url))}'" do
          mounted_subject.filename
          expect(mounted_subject.key).to match /#{Regexp.escape(File.basename(sample(:file_url)))}$/
        end

        it "should return a filename based off the key and remote url" do
          filename = mounted_subject.filename
          expect(mounted_subject.key).to match /#{Regexp.escape(filename)}$/
        end

        # this ensures that the version subject keys are updated
        # see spec for key= for more details
        it "should set the key explicitly" do
          expect(mounted_subject).to receive(:key=)
          mounted_subject.filename
        end
      end

      context "and the model's remote #{sample(:mounted_as)} url has special characters in it" do
        before do
          allow(mounted_model).to receive(
            "remote_#{mounted_subject.mounted_as}_url"
          ).and_return("http://anyurl.com/any_path/video_dir/filename ()+[]2.avi")
        end

        it "should be sanitized (special characters replaced with _)" do
          mounted_subject.filename
          expect(mounted_subject.key).to match /filename___\+__2.avi$/
        end
      end

      context "and the model's remote #{sample(:mounted_as)} url is blank" do
        before do
          allow(mounted_model).to receive(
            "remote_#{mounted_subject.mounted_as}_url"
          ).and_return nil
        end

        it "should return nil" do
          expect(mounted_subject.filename).to be_nil
        end
      end
    end
  end

  describe "#acl" do
    it "should return the correct s3 access policy" do
      expect(subject.acl).to eq (subject.fog_public ? 'public-read' : 'private')
    end
  end

  # note that 'video' is hardcoded into the MountedClass support file
  # so changing the sample will cause the tests to fail
  context "a class has a '#{sample(:mounted_as)}' mounted" do
    describe "#{sample(:mounted_as).to_s.capitalize}Uploader" do
      describe "##{sample(:mounted_as)}" do
        it "should be defined" do
          expect(subject).to be_respond_to(sample(:mounted_as))
        end

        it "should return itself" do
          expect(subject.send(sample(:mounted_as))).to eq subject
        end
      end

      context "has a '#{sample(:version)}' version" do
        let(:video_subject) { MountedClass.new.video }

        before do
          DirectUploader.version(sample(:version))
        end

        context "and the key is '#{sample(:s3_key)}'" do
          before do
            video_subject.key = sample(:s3_key)
          end

          context "the store path" do
            let(:store_path) { video_subject.send(sample(:version)).store_path }

            it "should be like '#{sample(:stored_version_filename)}'" do
              expect(store_path).to match /#{sample(:stored_version_filename)}$/
            end

            it "should not be like '#{sample(:version)}_#{sample(:stored_filename_base)}'" do
              expect(store_path).to_not match /#{sample(:version)}_#{sample(:stored_filename_base)}/
            end
          end
        end
      end
    end
  end
end
