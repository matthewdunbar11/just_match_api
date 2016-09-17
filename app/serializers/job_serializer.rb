# frozen_string_literal: true
class JobSerializer < ApplicationSerializer
  # Since the #attributes method is overriden and provides a whitelist of attribute_names
  # that can be returned to the user we can return all Job column names here
  attributes Job.column_names.map(&:to_sym)

  link(:self) { api_v1_job_url(object.id, host: scope[:host]) }

  has_many :job_users do
    # Only disclose job users to the job owner
    user = scope[:current_user]
    if user && (user.id == object.owner_id || user.admin)
      object.job_users
    else
      []
    end
  end

  has_many :comments, unless: :collection_serializer? do
    link(:self) { api_v1_job_comments_url(job_id: object.id, host: scope[:host]) }

    object.comments.visible
  end

  has_one :owner do
    link(:self) { api_v1_user_url(object.owner_id, host: scope[:host]) }
  end
  has_one :company do
    link(:self) { api_v1_company_url(object.company, host: scope[:host]) }
  end
  has_one :language do
    link(:self) { api_v1_language_url(object.language_id, host: scope[:host]) }
  end
  has_one :category
  has_one :hourly_pay

  def attributes(_)
    data = super

    data.slice(*policy.present_attributes(collection: collection_serializer?))
  end

  private

  def policy
    @_job_policy ||= JobPolicy.new(scope[:current_user], object)
  end
end

# == Schema Information
#
# Table name: jobs
#
#  id                :integer          not null, primary key
#  description       :text
#  job_date          :datetime
#  hours             :float
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  owner_user_id     :integer
#  latitude          :float
#  longitude         :float
#  language_id       :integer
#  street            :string
#  zip               :string
#  zip_latitude      :float
#  zip_longitude     :float
#  hidden            :boolean          default(FALSE)
#  category_id       :integer
#  hourly_pay_id     :integer
#  verified          :boolean          default(FALSE)
#  job_end_date      :datetime
#  cancelled         :boolean          default(FALSE)
#  filled            :boolean          default(FALSE)
#  short_description :string
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
