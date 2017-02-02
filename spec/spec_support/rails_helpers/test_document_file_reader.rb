# frozen_string_literal: true
require 'rack/test'

module TestDocumentFileReader
  def self.document
    'data:application/vnd.openxmlformats-officedocument.wordprocessingml.document;base64,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' # rubocop:disable Metrics/LineLength
  end
end