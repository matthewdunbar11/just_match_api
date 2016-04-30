# frozen_string_literal: true
require 'rails_helper'

RSpec.describe CreateFrilansFinansInvoiceService, type: :serializer do
  before(:each) { stub_frilans_finans_auth_request }

  let(:base_uri) { ENV.fetch('FRILANS_FINANS_BASE_URI') }
  let(:company) { FactoryGirl.create(:company, frilans_finans_id: 1) }
  let(:job) do
    owner = FactoryGirl.create(:user, company: company)
    FactoryGirl.create(:passed_job, owner: owner)
  end
  let(:job_user) { FactoryGirl.create(:job_user_passed_job, job: job, user: user) }
  let(:user) { FactoryGirl.create(:user, frilans_finans_id: 1) }
  let(:invoice) do
    FactoryGirl.create(:invoice, frilans_finans_id: nil, job_user: job_user)
  end

  let(:frilans_api_klass) { FrilansFinansApi::Invoice }
  let(:ff_document_mock) { OpenStruct.new(resource: OpenStruct.new(id: 1)) }
  let(:ff_nil_document_mock) { OpenStruct.new(resource: OpenStruct.new(id: nil)) }
  let(:invoice_request_body) { /^\{"invoice":*/ }

  subject do
    isolate_frilans_finans_client(FrilansFinansApi::Client) do
      headers = {
        'Authorization' => 'Bearer xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
        'User-Agent' => 'FrilansFinansAPI - Ruby client',
        'Content-Type' => 'application/json'
      }

      stub_request(:post, "#{base_uri}/invoices").
        with(body: invoice_request_body,
             headers: headers).
        to_return(status: 200, body: '{ "data": { "id": "1" } }', headers: {})

      stub_request(:get, "#{base_uri}/taxes?filter%5Bstandard%5D=1&page=1").
        with(headers: headers).
        to_return(status: 200, body: '{ "data": { "id": "3" } }', headers: {})

      ff_user_body = {
        data: {
          id: '5',
          attributes: {}
        }
      }

      stub_request(:get, "#{base_uri}/users/1").
        with(headers: headers).
        to_return(status: 200, body: JSON.dump(ff_user_body), headers: {})

      described_class.create(invoice: invoice)
    end
  end

  it 'creates an invoice' do
    expect { subject }.to change(Invoice, :count).by(1)
  end

  it 'notifies user' do
    allow(InvoiceCreatedNotifier).to receive(:call).
      with(job: job, user: user)
    subject
    expect(InvoiceCreatedNotifier).to have_received(:call)
  end

  context 'no company frilans finans id' do
    let(:company) { FactoryGirl.create(:company, frilans_finans_id: nil) }

    it 'calls missing company frilans finans id notifier' do
      allow(InvoiceMissingCompanyFrilansFinansIdNotifier).to receive(:call)
      subject
      expect(InvoiceMissingCompanyFrilansFinansIdNotifier).to have_received(:call)
    end
  end

  context 'Frilans Finans' do
    it 'creates with a Frilans Finans id' do
      expect(subject.frilans_finans_id).to eq(1)
    end

    it 'calls Frilans Finans API' do
      allow(frilans_api_klass).to receive(:create).and_return(ff_document_mock)
      subject
      expect(frilans_api_klass).to have_received(:create)
    end
  end

  context 'invalid Frilans Finans API response' do
    let(:job) do
      company = FactoryGirl.create(:company, frilans_finans_id: 1)
      owner = FactoryGirl.create(:user, company: company)
      FactoryGirl.create(:passed_job, owner: owner)
    end

    let(:job_user) { FactoryGirl.build(:job_user_passed_job, job: job, user: user) }
    let(:user) { FactoryGirl.create(:user, frilans_finans_id: 2) }

    subject do
      isolate_frilans_finans_client(FrilansFinansApi::NilClient) do
        described_class.create(invoice: invoice)
      end
    end

    it 'does persist invoice' do
      isolate_frilans_finans_client(FrilansFinansApi::NilClient) do
        expect(subject.persisted?).to eq(true)
      end
    end

    it 'does call Frilans Finans API' do
      isolate_frilans_finans_client(FrilansFinansApi::NilClient) do
        allow(frilans_api_klass).to receive(:create).and_return(ff_nil_document_mock)
        subject
        expect(frilans_api_klass).to have_received(:create)
      end
    end

    it 'notifies admin user' do
      isolate_frilans_finans_client(FrilansFinansApi::NilClient) do
        allow(frilans_api_klass).to receive(:create).and_return(ff_nil_document_mock)
        allow(InvoiceFailedToConnectToFrilansFinansNotifier).to receive(:call)
        subject
        expect(InvoiceFailedToConnectToFrilansFinansNotifier).to have_received(:call)
      end
    end

    it 'notifies user' do
      isolate_frilans_finans_client(FrilansFinansApi::NilClient) do
        allow(frilans_api_klass).to receive(:create).and_return(ff_nil_document_mock)
        allow(InvoiceCreatedNotifier).to receive(:call)
        subject
        expect(InvoiceCreatedNotifier).to have_received(:call)
      end
    end
  end

  describe '#frilans_finans_body' do
    it 'returns the invoice data schema' do
      allow(described_class).to receive(:invoice_users).and_return({})
      allow(described_class).to receive(:invoice_dates).and_return({})
      allow(described_class).to receive(:invoice_data).and_return(a: 1)

      result = described_class.frilans_finans_body(
        job: nil,
        user: nil,
        tax: nil,
        ff_user: nil
      )

      expected = {
        invoice: {
          a: 1,
          invoicedate: {},
          invoiceuser: {}
        }
      }
      expect(result).to eq(expected)
    end
  end

  describe '#invoice_data' do
    it 'returns the main invoice data' do
      ff_company_id = 11
      company = FactoryGirl.create(:company, frilans_finans_id: ff_company_id)
      owner = FactoryGirl.create(:user, company: company)
      job = FactoryGirl.create(:job, owner: owner, hours: 50)
      ff_tax_id = '3'
      tax = Struct.new(:id).new(ff_tax_id)

      ff_user_id = 10
      user = FactoryGirl.build(:user, frilans_finans_id: ff_user_id)

      result = described_class.invoice_data(job: job, user: user, tax: tax)

      expected = {
        currency_id: Currency.default_currency.try!(:frilans_finans_id),
        specification: "#{job.category.name} - #{job.name}",
        amount: job.amount,
        company_id: ff_company_id,
        tax_id: ff_tax_id,
        user_id: ff_user_id
      }

      expect(result).to eq(expected)
    end
  end

  describe '#invoice_users' do
    it 'returns invoice users data' do
      job = FactoryGirl.build(:job, hours: 50)
      user = FactoryGirl.build(:user)

      taxkey_id = 13
      attributes_mock = Struct.new(:attributes).new('default_taxkey_id' => taxkey_id)
      ff_user_mock = Struct.new(:resource).new(attributes_mock)

      result = described_class.invoice_users(job: job, user: user, ff_user: ff_user_mock)

      expected = [{
        user_id: nil,
        total: 5000.0,
        taxkey_id: taxkey_id,
        allowance: 0,
        travel: 0,
        vacation_pay: 0,
        itp: 0,
        express_payment: 0
      }]

      expect(result).to eq(expected)
    end
  end

  describe '#invoice_dates' do
    it 'returns invoice dates data' do
      start = Date.new(2016, 4, 22)
      finish = Date.new(2016, 4, 26)
      job = FactoryGirl.build(:job, job_date: start, job_end_date: finish, hours: 50)

      expected = [
        { date: Date.new(2016, 4, 22), hours: 10.0 },
        { date: Date.new(2016, 4, 23), hours: 10.0 },
        { date: Date.new(2016, 4, 24), hours: 10.0 },
        { date: Date.new(2016, 4, 25), hours: 10.0 },
        { date: Date.new(2016, 4, 26), hours: 10.0 }
      ]
      result = described_class.invoice_dates(job: job)

      expect(result).to eq(expected)
    end
  end
end
