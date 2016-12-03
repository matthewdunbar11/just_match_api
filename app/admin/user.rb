# frozen_string_literal: true
ActiveAdmin.register User do
  menu parent: 'Users', priority: 1

  batch_action :destroy, false

  # Create sections on the index screen
  scope :all, default: true
  scope :admins
  scope :company_users
  scope :regular_users
  scope :needs_frilans_finans_id
  scope :managed_users

  filter :email
  filter :phone
  filter :first_name
  filter :last_name
  filter :ssn
  filter :language
  filter :company
  filter :frilans_finans_id
  filter :job_experience
  filter :education
  filter :competence_text
  filter :admin
  filter :cancelled
  filter :anonymized
  filter :managed

  index do
    selectable_column

    column :id
    column :first_name
    column :last_name
    column :email
    column :company
    column :frilans_finans_id
    column :managed
    column :created_at

    actions
  end

  show do |user|
    h3 I18n.t('admin.user.show.general')
    attributes_table do
      row :id
      row :frilans_finans_id
      row :verified
      row :average_score

      row :name
      row :email
      row :phone
      row :skype_username
      row :street
      row :zip
      row :ssn
      row :company
      row :language
    end

    if !user.company?
      h3 I18n.t('admin.user.show.profile')
      attributes_table do
        row :current_status
        row :at_und
        row :arrived_at
        row :description
        row :job_experience
        row :competence_text
        row :education
        row :country_of_origin
      end

      h3 I18n.t('admin.user.show.payment')
      attributes_table do
        row :frilans_finans_payment_details
        row :account_clearing_number
        row :account_number
      end
    end

    h3 I18n.t('admin.user.show.status_flags')
    attributes_table do
      row :admin
      row :managed
      row :anonymized
      row :banned
    end

    h3 I18n.t('admin.user.show.misc')
    attributes_table do
      row :ignored_notifications do
        user.ignored_notifications.join(', ')
      end

      row :contact_email
      row :primary_role

      row :latitude
      row :longitude
      row :zip_latitude
      row :zip_longitude

      row :created_at
      row :updated_at
    end

    active_admin_comments
  end

  form do |f|
    f.semantic_errors # shows errors on :base
    f.inputs          # builds an input field for every attribute
    f.input :password
    f.actions         # adds the 'Submit' and 'Cancel' buttons
  end

  include AdminHelpers::MachineTranslation::Actions

  sidebar :relations, only: :show do
    user_query = AdminHelpers::Link.query(:user_id, user.id)
    from_user_query = AdminHelpers::Link.query(:from_user_id, user.id)
    to_user_query = AdminHelpers::Link.query(:to_user_id, user.id)
    owner_user_query = AdminHelpers::Link.query(:owner_user_id, user.id)

    ul do
      if user.company?
        li(
          link_to(user.company.display_name, admin_company_path(user.company))
        )
      end
      li(
        link_to(
          I18n.t('admin.user.primary_language', lang: user.language.display_name),
          admin_language_path(user.language)
        )
      )
    end

    ul do
      if user.company?
        li(
          link_to(
            I18n.t('admin.counts.owned_jobs', count: user.owned_jobs.count),
            admin_jobs_path + owner_user_query
          )
        )
      else
        li(
          link_to(
            I18n.t('admin.counts.applications', count: user.job_users.count),
            admin_job_users_path + user_query
          )
        )
      end
      li(
        link_to(
          I18n.t('admin.counts.translations', count: user.translations.count),
          admin_user_translations_path + user_query
        )
      )
      li(
        link_to(
          I18n.t('admin.counts.sessions', count: user.auth_tokens.count),
          admin_tokens_path + user_query
        )
      )
      li(
        link_to(
          I18n.t('admin.counts.chats', count: user.chats.count),
          admin_chats_path + user_query
        )
      )
      li(
        link_to(
          I18n.t('admin.counts.written_messages', count: user.messages.count),
          admin_messages_path + user_query
        )
      )
      li(
        link_to(
          I18n.t('admin.counts.images', count: user.user_images.count),
          admin_user_images_path + user_query
        )
      )
      li(
        link_to(
          I18n.t('admin.counts.received_ratings', count: user.received_ratings.count),
          admin_ratings_path + to_user_query
        )
      )
      li(
        link_to(
          I18n.t('admin.counts.given_ratings', count: user.given_ratings.count),
          admin_ratings_path + from_user_query
        )
      )
      li I18n.t('admin.counts.written_comments', count: user.written_comments.count)
    end
  end

  after_save do |user|
    translation_params = {
      description: permitted_params.dig(:user, :description),
      job_experience: permitted_params.dig(:user, :job_experience),
      education: permitted_params.dig(:user, :education),
      competence_text: permitted_params.dig(:user, :competence_text)
    }
    user.set_translation(translation_params)
  end

  permit_params do
    extras = [
      :password, :language_id, :company_id, :managed, :frilans_finans_payment_details,
      :verified
    ]
    UserPolicy::SELF_ATTRIBUTES + extras
  end

  controller do
    def scoped_collection
      super.with_translations
    end
  end
end
