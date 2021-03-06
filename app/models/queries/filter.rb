# frozen_string_literal: true

module Queries
  class Filter
    def self.filter(records, filters, filter_types)
      param_types = to_param_types(filter_types)

      filters.each do |field_name, value|
        # If it includes a '.' it means its a filter on a relation and
        # should therefore be ignored
        next if field_name.to_s.include?('.')

        value = normalize_value(value)

        filter_type = param_types.fetch(field_name, column: field_name)
        type = filter_type[:type]
        field_name = filter_type[:column]

        if type == :fake_attribute
          records # we can't filter on fake attributes
        elsif filter_type[:translated]
          records = filter_translated_records(records, field_name, value, type)
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
      return [nil, ''] if value.nil?
      return [nil, ''] if value.respond_to?(:empty?) && value.empty?

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

    def self.to_param_types(filter_types)
      filter_types.map do |name, filter_type|
        filter_type = { type: filter_type } unless filter_type.is_a?(Hash)
        if type = filter_type[:translated]
          filter_type[:type] = type
          filter_type[:translated] = true
        end

        column = if filter_type[:column]
                   filter_type[:column]
                 elsif filter_type[:type] == :fake_attribute
                   nil
                 else
                   name
                 end

        [name, { column: column }.merge!(filter_type)]
      end.to_h
    end
  end
end
