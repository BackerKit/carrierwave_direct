# encoding: utf-8

module CarrierWaveDirect
  class FormBuilder < ActionView::Helpers::FormBuilder
    def file_field(method, options = {})
      key_id = "#{@template.dom_class(@object)}_key"
      fields = @template.hidden_field_tag(:key, @object.key, id: key_id, required: false)
      options.merge!(name: "file")
      fields << super
    end

    def fields_except_file_field(options = {})
      key_id = "#{@template.dom_class(@object)}_key"
      @template.hidden_field_tag(:key, @object.key, id: key_id, required: false)
    end

    def content_type_label(content = nil)
      content ||= 'Content Type'
      @template.label_tag('Content-Type', content)
    end

    def content_type_select(choices = [], selected = nil, options = {})
      @template.select_tag('Content-Type', content_choices_options(choices, selected), options)
    end

    private

    def content_choices_options(choices, selected = nil)
      choices = @object.content_types if choices.blank?
      selected ||= @object.content_type
      @template.options_for_select(choices, selected)
    end
  end
end
