require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder

  before_action :authenticate

  rescue_from ActiveRecord::StaleObjectError do
    flash[:alert] = "Another user has made a change to that record since you accessed the edit form."
    if request.format == :js
      render_exception
    else
      redirect_to root_url
    end
  end

  rescue_from ActionController::InvalidAuthenticityToken do
    if request.format == :js
      render_exception
    else
      redirect_to request.referer, alert: "Please try again"
    end
  end

  def exception_test
    raise "Exception test"
  end

  protected

  def authenticate
    http_basic_authenticate_or_request_with(
      name: Rails.configuration.home_control.authentication[:name],
      password: Rails.configuration.home_control.authentication[:password],
      realm: "Application"
    )
  end
  
  def restore_per_page(default_per_page =  Kaminari.config.default_per_page)
    cookie_key = [controller_name, action_name, "per"].join("_")
    stored_per_page = JSON.load(cookies[cookie_key])
    @per_page = params[:per] || stored_per_page || default_per_page
    cookies[cookie_key] = @per_page.to_json
    @per_page
  end

  def load_reload
    @reload = params[:reload] == "1"
  end

  def current_user
    nil
  end
end
