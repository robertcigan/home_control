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
    return if Rails.env.test?
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

  # Removes the row via Turbo Stream when delete is triggered from an index
  # turbo-frame (keeps filters/pagination). Otherwise redirects (e.g. show page).
  def destroy_with_turbo_stream(resource, location:, notice:, always_stream: false)
    if resource.destroy
      respond_to do |format|
        format.turbo_stream do
          if always_stream || list_frame_destroy_request?
            flash.now[:notice] = notice
            render turbo_stream: [
              turbo_stream.remove(resource),
              *helpers.turbo_stream_flash
            ]
          else
            flash[:notice] = notice
            redirect_to location, status: :see_other
          end
        end
        format.html do
          flash[:notice] = notice
          redirect_to location, status: :see_other
        end
      end
    else
      message = resource.errors.full_messages.to_sentence
      if message.blank?
        message = "Could not remove record."
      end

      respond_to do |format|
        format.turbo_stream do
          flash.now[:alert] = message
          render turbo_stream: helpers.turbo_stream_flash
        end
        format.html do
          flash[:alert] = message
          redirect_to location, status: :see_other
        end
      end
    end
  end

  def list_frame_destroy_request?
    if turbo_frame_request?
      turbo_frame_request_id != "_top"
    else
      false
    end
  end
end
