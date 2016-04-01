# frozen_string_literal: true
class Job < ApplicationRecord
  include Geocodable
  include SkillMatchable

  LOCATE_BY = {
    address: { lat: :latitude, long: :longitude },
    zip: { lat: :zip_latitude, long: :zip_longitude }
  }.freeze

  belongs_to :language
  belongs_to :category
  belongs_to :hourly_pay

  has_one :company, through: :owner

  has_many :job_skills
  has_many :skills, through: :job_skills

  has_many :job_users
  has_many :users, through: :job_users

  has_many :comments, as: :commentable

  validates :language, presence: true
  validates :hourly_pay, presence: true
  validates :category, presence: true
  validates :name, length: { minimum: 2 }, allow_blank: false
  validates :description, length: { minimum: 10 }, allow_blank: false
  validates :street, length: { minimum: 5 }, allow_blank: false
  validates :zip, length: { minimum: 5 }, allow_blank: false
  validates :job_date, presence: true
  validates :owner, presence: true
  validates :hours, numericality: { greater_than_or_equal_to: 1 }, allow_blank: false

  validate :validate_job_date_in_future
  validate :validate_hourly_pay_active
  validate :validate_job_without_confirmed_user

  belongs_to :owner, class_name: 'User', foreign_key: 'owner_user_id'

  scope :visible, -> { where(hidden: false) }

  def self.matches_user(user, distance: 20, strict_match: false)
    lat = user.latitude
    long = user.longitude

    within(lat: lat, long: long, distance: distance).
      order_by_matching_skills(user, strict_match: strict_match)
  end

  def self.associated_jobs(user)
    joins('LEFT JOIN job_users ON job_users.job_id = jobs.id').
      where('jobs.owner_user_id = :user OR job_users.user_id = :user', user: user)
  end

  def locked_for_changes?
    applicant = applicants.find_by(accepted: true)
    return false unless applicant

    applicant.will_perform
  end

  # Needed for administrate
  # see https://github.com/thoughtbot/administrate/issues/354
  def owner_id
    owner.try!(:id)
  end

  # Needed for administrate
  # see https://github.com/thoughtbot/administrate/issues/354
  def owner_id=(id)
    self.owner = User.find_by(id: id)
  end

  def owner?(user)
    !owner.nil? && owner == user
  end

  def find_applicant(user)
    job_users.find_by(user: user)
  end

  def accepted_applicant?(user)
    !accepted_applicant.nil? && accepted_applicant == user
  end

  def accepted_job_user
    applicants.find_by(accepted: true)
  end

  def accepted_applicant
    accepted_job_user.try!(:user)
  end

  def accept_applicant!(user)
    applicants.find_by(user: user).tap do |applicant|
      applicant.accept
      applicant.save!
    end.reload
  end

  def create_applicant!(user)
    users << user
    user
  end

  def applicants
    job_users
  end

  def started?
    job_date < Time.zone.now
  end

  def validate_job_date_in_future
    return if job_date.nil? || job_date > Time.zone.now

    errors.add(:job_date, I18n.t('errors.job.job_date_in_the_past'))
  end

  def validate_hourly_pay_active
    return if hourly_pay.nil? || hourly_pay.active

    errors.add(:hourly_pay, I18n.t('errors.job.hourly_pay_active'))
  end

  def validate_job_without_confirmed_user
    return if accepted_job_user.nil?

    if accepted_job_user.will_perform
      message = I18n.t('errors.job.update_not_allowed_when_accepted')
      errors.add(:update_not_allowed, message)
    end
  end
end

# == Schema Information
#
# Table name: jobs
#
#  id            :integer          not null, primary key
#  description   :text
#  job_date      :datetime
#  hours         :float
#  name          :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  owner_user_id :integer
#  latitude      :float
#  longitude     :float
#  language_id   :integer
#  street        :string
#  zip           :string
#  zip_latitude  :float
#  zip_longitude :float
#  hidden        :boolean          default(FALSE)
#  category_id   :integer
#  hourly_pay_id :integer
#
# Indexes
#
#  index_jobs_on_category_id    (category_id)
#  index_jobs_on_hourly_pay_id  (hourly_pay_id)
#  index_jobs_on_language_id    (language_id)
#
# Foreign Keys
#
#  fk_rails_1cf0b3b406    (category_id => categories.id)
#  fk_rails_70cb33aa57    (language_id => languages.id)
#  fk_rails_b144fc917d    (hourly_pay_id => hourly_pays.id)
#  jobs_owner_user_id_fk  (owner_user_id => users.id)
#
