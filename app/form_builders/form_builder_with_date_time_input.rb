# Extend the Rails FormBuilder class.
#
# The naming is unfortunate, as this FormBuilder does more than just add a
# custom datetimepicker. In reality, it's goal is to wrap common form builder
# methods in Bootstrap boilerplate code.
class FormBuilderWithDateTimeInput < ActionView::Helpers::FormBuilder
  %w(text_field text_area email_field number_field).each do |method_name|
    # retain access to default textfield, etc. helpers
    alias_method "vanilla_#{method_name}", method_name

    define_method(method_name) do |name, *args|
      options = args.extract_options!

      # DEPRECATED: add form-control class (for Bootstrap styling) and pass on to Rails
      options[:class] = (options[:class]).to_s

      unless options.include?(:placeholder)
        options[:placeholder] = ""
      end

      field = super name, *(args + [options])

      wrap_field name, field, options[:help_text], options[:display_name]
    end
  end

  def score_adjustment_input(name, *args)
    options = args.extract_options!

    fields = fields_for name do |f|
      (f.vanilla_text_field :value, class: "score-box", placeholder: "10") +
        (@template.content_tag :div, class: "" do
          f.select(:kind, { "points" => "points", "%" => "percent" }, {},
                   class: "carrot")
        end)
    end

    wrap_field name, fields, options[:help_text]
  end

  def submit(text, *args)
    options = args.extract_options!

    options[:class] = "btn btn-primary #{options[:class]}"

    super text, *(args + [options])
  end

  def check_box(name, *args)
    options = args.extract_options!

    display_name = options[:display_name].nil? ? name : options[:display_name]

    display_span = "<span>#{display_name.to_s.humanize}</span>"
    # Materalize requires the label to be in a span
    field = super name, *(args + [options])

    if options[:default]
      return field
    end

    @template.content_tag :div do
      if options.include?(:help_text)
        label(name, field + display_span.html_safe,
              class: "control-label") + help_text(name, options[:help_text])
      else
        label(name, field + display_span.html_safe, class: "control-label")
      end
    end
  end

  def file_field(name, *args)
    options = args.extract_options!

    field = super name, *(args + [options])

    wrap_field name, field, options[:help_text], options[:display_name]
  end

  def file_field_nowrap(name, *args)
    options = args.extract_options!

    field = method(:file_field).super_method.call name, *(args + [options])

    field
  end

  def date_select(name, options = {}, _html_options = {})
    strftime = "%F"
    date_format = "F j, Y"
    alt_format = "F j, Y"
    options[:picker_class] = "datepicker"
    date_helper name, options, strftime, date_format, alt_format
  end

  def datetime_select(name, options = {}, _html_options = {})
    strftime = "%F %H:%M %z"
    date_format = "YYYY-MM-DD HH:mm ZZ"
    alt_format = "YYYY-MM-DD HH:mm ZZ"
    options[:picker_class] = "datetimepicker"
    date_helper name, options, strftime, date_format, alt_format
  end

private

  # Pass space-delimited list of IDs of datepickers on the :less_than and
  # :greater_than properties to initialize relationships between datepicker
  # fields.
  def date_helper(name, options, strftime, date_format, alt_format)
    begin
      existing_time = @object.send(name)
    rescue
      existing_time = nil
    end

    formatted_datetime = if existing_time.present?
                           existing_time.strftime(strftime)
                         else
                           ""
                         end
    field = vanilla_text_field(
      name,
      value: formatted_datetime,
      class: (options[:picker_class]).to_s,
      "data-date-format": date_format,
      "data-alt-format": alt_format,
      "data-date-less-than": options[:less_than],
      "data-date-greater-than": options[:greater_than]
    )

    wrap_field name, field, options[:help_text]
  end

  def wrap_field(name, field, help_text = nil, display_name = nil)
    @template.content_tag :div, class: "input-field" do
      label(name, display_name, class: "control-label") +
        field + help_text(name, help_text)
    end
  end

  def help_text(_name, help_text)
    if help_text.nil?
      ""
    else
      @template.content_tag :p, help_text, class: "help-block"
    end
  end

  def objectify_options(options)
    super.except :help_text
  end
end
