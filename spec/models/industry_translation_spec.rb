# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndustryTranslation, type: :model do
end

# == Schema Information
#
# Table name: industry_translations
#
#  id          :integer          not null, primary key
#  name        :string
#  industry_id :integer
#  language_id :integer
#  locale      :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_industry_translations_on_industry_id  (industry_id)
#  index_industry_translations_on_language_id  (language_id)
#
# Foreign Keys
#
#  fk_rails_...  (industry_id => industries.id)
#  fk_rails_...  (language_id => languages.id)
#
