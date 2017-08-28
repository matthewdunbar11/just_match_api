# frozen_string_literal: true

module Queries
  class Filter
    def self.to_params(filter_types)
      filter_types.map do |name, filter_type|
        filter_type = { type: filter_type } unless filter_type.is_a?(Hash)
        column = name
        column = filter_type[:column] if filter_type[:column]

        [name, { column: column }.merge!(filter_type)]
      end.to_h
    end

    def self.filter(records, filters, filter_types)
      filters.each do |field_name, value|
        # If it includes a '.' it means its a filter on a relation and
        # should therefore be ignored
        next if field_name.to_s.include?('.')

        value = normalize_value(value)

        filter_type = filter_types[field_name]

        filter_type = { type: filter_type } unless filter_type.is_a?(Hash)
        type = filter_type[:type]

        field_name = filter_type[:alias] if filter_type[:alias]

        if type == :fake_attribute
          records # we can't filter on fake attributes
        elsif filter_type[:translated]
          records = filter_translated_records(records, field_name, value, filter_type[:translated]) # rubocop:disable Metrics/LineLength
        elsif type == :in_list
          records = records.where(field_name => value&.split(','))
        elsif type
          records = filter_records(records, field_name, value, type)
        else
          records = records.where(field_name => value)
        end
      end
      records
    end

    def self.normalize_value(value)
      return [nil, ''] if value.nil? || value.empty? # rubocop:disable Rails/Blank

      value
    end

    def self.filter_records(records, field_name, value, filter_type)
      like_query = extract_like_query(filter_type)
      records.where(
        "lower(#{field_name}) LIKE lower(concat(#{like_query}))",
        value
      )
    end

    def self.filter_translated_records(records, field_name, value, filter_type)
      relation_name = "#{records.model_name.singular}_translations"
      like_query = extract_like_query(filter_type)
      records.joins(:translations).where(
        "lower(#{relation_name}.#{field_name}) LIKE lower(concat(#{like_query}))",
        value
      )
    end

    def self.extract_like_query(filter_type)
      case filter_type
      when :contains then "'%', ?, '%'"
      when :starts_with then "?, '%'"
      when :ends_with then "'%', ?"
      else
        raise ArgumentError, "unknown filter_type: '#{filter_type}'"
      end
    end
  end
end
