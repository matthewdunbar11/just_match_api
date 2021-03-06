# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AcceptedApplicantWithdrawnNotifier, type: :mailer do
  let(:mailer) { Struct.new(:deliver_later).new(nil) }
  let(:job) { mock_model Job, owner: owner }
  let(:user) { FactoryGirl.build(:user) }
  let(:owner) { FactoryGirl.build(:user) }
  let(:job_user) { mock_model JobUser, user: user, job: job }

  it 'must work' do
    allow(JobMailer).to receive(:accepted_applicant_withdrawn_email).and_return(mailer)
    mailer_args = { job_user: job_user, owner: job.owner }
    described_class.call(**mailer_args)
    expect(JobMailer).to have_received(:accepted_applicant_withdrawn_email).
      with(mailer_args)
  end
end
