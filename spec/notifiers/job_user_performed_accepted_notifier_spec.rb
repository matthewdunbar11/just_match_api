# frozen_string_literal: true
require 'rails_helper'

RSpec.describe JobUserPerformedAcceptedNotifier, type: :mailer do
  let(:mailer) { Struct.new(:deliver_later).new(nil) }
  let(:job) { mock_model Job, owner: nil, accepted_applicant: nil }

  it 'must work' do
    allow(UserMailer).to receive(:job_user_performed_accepted_email).and_return(mailer)
    JobUserPerformedAcceptedNotifier.call(job: job, user: nil)
    mailer_args = { job: job, user: nil, owner: job.owner }
    expect(UserMailer).to have_received(:job_user_performed_accepted_email).
      with(mailer_args)
  end
end