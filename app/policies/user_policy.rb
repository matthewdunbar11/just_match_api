# frozen_string_literal: true

class UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.visible
      end
    end
  end

  ATTRIBUTES = %i(
    id first_name description description_html education education_html
    job_experience job_experience_html competence_text competence_text_html
    language_id zip zip_latitude zip_longitude primary_role translated_text
    gender system_language_id linkedin_url facebook_url
  ).freeze

  ACCEPTED_APPLICANT_ATTRIBUTES = ATTRIBUTES + %i(
    phone street city latitude longitude email last_name name
  ).freeze

  SELF_ATTRIBUTES = (ATTRIBUTES + ACCEPTED_APPLICANT_ATTRIBUTES + %i(
    created_at updated_at admin anonymized ignored_notifications
    frilans_finans_payment_details ssn current_status at_und arrived_at
    country_of_origin auth_token account_clearing_number account_number
    skype_username next_of_kin_name next_of_kin_phone full_street_address
    arbetsformedlingen_registered_at just_arrived_staffing support_chat_activated
    bank_account has_welcome_app_account public_profile
  )).freeze

  attr_reader :accepted_applicant

  def index?
    admin?
  end

  def create?
    true
  end

  def show?
    admin_or_self?
  end

  alias_method :update?, :show?
  alias_method :destroy?, :show?
  alias_method :matching_jobs?, :show?
  alias_method :frilans_finans?, :show?
  alias_method :chats?, :show?
  alias_method :support_chat?, :show?
  alias_method :create_document?, :show?
  alias_method :index_document?, :show?
  alias_method :missing_traits?, :show?

  def jobs?
    admin_or_self? || company_user?
  end

  alias_method :ratings?, :jobs?

  def owned_jobs?
    admin_or_self?
  end

  def notifications?
    true
  end

  alias_method :statuses?, :notifications?
  alias_method :genders?, :notifications?
  alias_method :email_suggestion?, :notifications?
  alias_method :categories?, :notifications?

  def present_attributes(collection: false)
    return ATTRIBUTES if no_user?

    if admin_or_self?
      SELF_ATTRIBUTES
    elsif !collection && accepted_applicant_for_owner?
      ACCEPTED_APPLICANT_ATTRIBUTES
    else
      ATTRIBUTES
    end
  end

  private

  def accepted_applicant_for_owner?
    User.accepted_applicant_for_owner?(owner: record, user: user)
  end

  def admin_or_self?
    admin? || user == record
  end
end
