# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImageContentTypeHelper do
  valid_content_types = %w(image/jpeg image/png)
  invalid_content_types = %w(
    image/gif video/mp4 test exe application/json application/octet-stream
    application/x-newton-compatible-pkg application/pdf application/msword
  )

  describe '::valid?' do
    valid_content_types.each do |mime_type|
      it "returns true for valid and accepted content type #{mime_type}" do
        expect(described_class.valid?(mime_type)).to eq(true)
      end
    end

    invalid_content_types.each do |extension|
      it "returns true for valid extension #{extension}" do
        expect(described_class.valid?(extension)).to eq(false)
      end
    end
  end

  describe '::original_filename' do
    it 'returns correct filename for valid a valid content type' do
      extension = described_class.original_filename('image/png').split('.').last
      expect(extension).to eq('png')
    end

    it 'returns nil for invalid extension' do
      expect(described_class.original_filename('watman')).to be_nil
    end
  end

  describe '::file_extension' do
    it 'returns correct file extension for valid content type' do
      expect(described_class.file_extension('image/png')).to eq('.png')
    end

    invalid_content_types.each do |content_type|
      it 'returns bil for invalid content types' do
        expect(described_class.file_extension(content_type)).to be_nil
      end
    end
  end
end
