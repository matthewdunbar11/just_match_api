# frozen_string_literal: true
class Invoice < ApplicationRecord
  belongs_to :job_user

  validates :job_user, uniqueness: true, presence: true
  validates :frilans_finans_id, uniqueness: true

  validate :validate_job_started
  validate :validate_job_user_accepted

  def validate_job_started
    job = job_user.try!(:job)
    return if job.nil? || job.started?

    message = I18n.t('errors.invoice.job_started')
    errors.add(:job, message)
  end

  def validate_job_user_accepted
    return if job_user.accepted

    message = I18n.t('errors.invoice.job_user_accepted')
    errors.add(:job_user, message)
  end
end

# == Schema Information
#
# Table name: invoices
#
#  id                :integer          not null, primary key
#  frilans_finans_id :integer
#  job_user_id       :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_invoices_on_frilans_finans_id  (frilans_finans_id) UNIQUE
#  index_invoices_on_job_user_id        (job_user_id)
#
# Foreign Keys
#
#  fk_rails_c894e05ce5  (job_user_id => job_users.id)
#