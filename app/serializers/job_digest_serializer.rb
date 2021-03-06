# frozen_string_literal: true

class JobDigestSerializer < ApplicationSerializer
  attributes :notification_frequency, :max_distance

  belongs_to :subscriber

  has_many :occupations
  has_many :addresses
end

# == Schema Information
#
# Table name: job_digests
#
#  id                     :integer          not null, primary key
#  notification_frequency :integer
#  max_distance           :float
#  locale                 :string(10)
#  deleted_at             :datetime
#  digest_subscriber_id   :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_job_digests_on_digest_subscriber_id  (digest_subscriber_id)
#
# Foreign Keys
#
#  fk_rails_...  (digest_subscriber_id => digest_subscribers.id)
#
