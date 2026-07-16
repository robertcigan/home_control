class ApplicationResponder < ActionController::Responder
  include Responders::CollectionResponder

  self.error_status = :unprocessable_entity
  self.redirect_status = :see_other

  # Turbo form posts negotiate as turbo_stream. Without this, responders falls
  # through to api_behavior and renders the AR resource as the response body
  # (Rack::ETag then calls empty? on it and blows up).
  def initialize(controller, resources, options = {})
    super
    if [:js, :turbo_stream].include?(format)
      options[:formats] ||= request.formats.map(&:symbol)
    end
  end

  alias to_turbo_stream to_html

  def error_rendering_options
    if options[:formats]
      super.merge(formats: options[:formats])
    else
      super
    end
  end
end
