# frozen_string_literal: true

ActiveAdmin.register GuideSectionArticle do
  menu parent: 'Guide', label: 'Articles', priority: 2

  filter :section, collection: -> { GuideSection.with_translations }
  filter :language, collection: -> { Language.system_languages }
  filter :translations_title_cont, as: :string, label: 'Title'
  filter :translations_slug_cont, as: :string, label: 'Slug'
  filter :translations_short_description_cont, as: :string, label: 'Short description'
  filter :translations_body_cont, as: :string, label: 'Body'
  filter :translations_created_at_cont, as: :string, label: 'Created at'
  filter :translations_updated_at_cont, as: :string, label: 'Updated at'

  index do
    selectable_column

    column :id
    column :order
    column :title
    column :section
    column :updated_at

    actions
  end

  show do
    attributes_table do
      row :section
      row :order
      row :language
      row :locale
      row :title
      row :slug
      row :short_description
      row :body { |article| markdown_to_html(article.body) }
      row :missing_translations do |translation|
        system_languages = Language.system_languages
        missing = system_languages.map(&:lang_code) - translation.translations.map(&:locale) # rubocop:disable Metrics/LineLength

        safe_join(missing.map do |locale|
          language = system_languages.detect { |lang| lang.lang_code == locale }
          link_to(
            "Create #{language.name} version",
            new_admin_guide_section_article_translation_path(
              'guide_section_article_translation[locale]': locale,
              'guide_section_article_translation[language_id]': language.id,
              'guide_section_article_translation[guide_section_article_id]': translation.id # rubocop:disable Metrics/LineLength
            )
          )
        end, ', ')
      end
    end

    active_admin_comments
  end

  after_save do |article|
    if article.persisted? && article.valid?
      article.set_translation(
        title: permitted_params.dig(:guide_section_article, :title),
        slug: permitted_params.dig(:guide_section_article, :slug),
        short_description: permitted_params.dig(:guide_section_article, :short_description), # rubocop:disable Metrics/LineLength
        body: permitted_params.dig(:guide_section_article, :body)
      )
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.keys)

    f.inputs('Article') do
      f.input :section, collection: GuideSection.with_translations
      f.input :language, collection: Language.system_languages
      f.input :order
      f.input :title
      f.input :slug
      f.input :short_description
      f.input :body, as: :text, input_html: { markdown: true }
    end

    f.actions
  end

  permit_params do
    %i[
      order
      language_id
      guide_section_id
      locale
      title
      slug
      short_description
      body
    ]
  end

  controller do
    def scoped_collection
      super.with_translations.
        includes(section: %i[language translations])
    end
  end
end
