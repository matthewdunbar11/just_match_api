# frozen_string_literal: true

module Api
  module V1
    module PartnerFeeds
      class JobsController < BaseController
        before_action :verify_linkedin_sync_key, only: %i(linkedin)
        before_action :verify_blocketjobb_sync_key, only: %i(blocketjobb)
        before_action :verify_metrojobb_sync_key, only: %i(metrojobb)

        after_action :verify_authorized, except: %i(linkedin blocketjobb metrojobb)

        resource_description do
          resource_id 'PartnerFeeds'
          short 'API for partner job feeds'
          name 'Partner Feeds'
          description 'Job feeds for partners'
          formats [:xml]
          api_versions '1.0'
        end

        api :GET, '/partner-feeds/jobs/linkedin', 'List jobs for LinkedIN feed'
        description 'Returns a list of jobs for LinkedIN to consume.'
        param :auth_token, String, desc: 'Auth token', required: true
        example <<-XML_EXAMPLE
        <?xml version="1.0" encoding="UTF-8"?>
        <source>
          <publisherUrl>https://justarrived.se</publisherUrl>
          <publisher>Just Arrived</publisher>
          <job>
              <company><![CDATA[Macejkovic, Lynch and Considine]]></company>
              <partnerJobId><![CDATA[300]]></partnerJobId>
              <title><![CDATA[Something something, title.]]></title>
              <description><![CDATA[Something, something. #welcometalent]]></description>
              <location>Storta Nygatan 36, 21137, Stockholm, Sverige</location>
              <city><![CDATA[Stockholm]]></city>
              <countryCode><![CDATA[SE]]></countryCode>
              <postalCode><![CDATA[21137]]></postalCode>
              <applyUrl><![CDATA[https://app.justarrived.se/job/300]]></applyUrl>
          </job>
          <job>
            ...
          </job>
        </source>
        XML_EXAMPLE
        def linkedin
          I18n.locale = AppConfig.linkedin_default_locale

          jobs = Job.with_translations.
                 linkedin_jobs.
                 includes(:company).
                 order(created_at: :desc).
                 limit(AppConfig.linkedin_job_records_feed_limit)

          render xml: LinkedinJobsSerializer.to_xml(jobs: jobs, locale: I18n.locale)
        end

        api :GET, '/partner-feeds/jobs/blocketjobb', 'List jobs for Blocketjobb feed'
        description 'Returns a list of jobs for Blocketjobb to consume.'
        param :auth_token, String, desc: 'Auth token', required: true
        def blocketjobb
          I18n.locale = AppConfig.blocketjobb_default_locale

          jobs = Job.with_translations.
                 blocketjobb_jobs.
                 includes(:company).
                 order(created_at: :desc)

          render xml: BlocketjobbJobsSerializer.to_xml(jobs: jobs, locale: I18n.locale)
        end

        api :GET, '/partner-feeds/jobs/metrojobb', 'List jobs for Metrojobb feed'
        description 'Returns a list of jobs for Metrojobb to consume.'
        param :auth_token, String, desc: 'Auth token', required: true
        def metrojobb
          I18n.locale = AppConfig.metrojobb_default_locale

          jobs = Job.with_translations.
                 metrojobb_jobs.
                 includes(:company).
                 order(created_at: :desc)

          render xml: MetrojobbJobsSerializer.to_xml(jobs: jobs, locale: I18n.locale)
        end

        private

        def verify_linkedin_sync_key
          unauthorized! if params[:auth_token].blank?
          return if AppSecrets.linkedin_sync_key == params[:auth_token]

          unauthorized!
        end

        def verify_blocketjobb_sync_key
          unauthorized! if params[:auth_token].blank?
          return if AppSecrets.blocketjobb_sync_key == params[:auth_token]

          unauthorized!
        end

        def verify_metrojobb_sync_key
          unauthorized! if params[:auth_token].blank?
          return if AppSecrets.metrojobb_sync_key == params[:auth_token]

          unauthorized!
        end

        def unauthorized!
          raise Pundit::NotAuthorizedError
        end
      end
    end
  end
end
