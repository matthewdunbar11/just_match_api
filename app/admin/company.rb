# frozen_string_literal: true
ActiveAdmin.register Company do
  scope :all, default: true
  scope :needs_frilans_finans_id

  filter :name
  filter :email
  filter :phone
  filter :cin
  filter :street
  filter :city
  filter :created_at

  index do
    column :name
    column :cin
    column :frilans_finans_id
    column :email
    column :phone
    column :created_at
  end

  permit_params do
    [
      :name,
      :cin,
      :created_at,
      :updated_at,
      :frilans_finans_id,
      :website,
      :email,
      :street,
      :zip,
      :city,
      :phone
    ]
  end
end
