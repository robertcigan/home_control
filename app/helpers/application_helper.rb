module ApplicationHelper
  def page_title(title)
    content_for :title do
      title.to_s
    end
    title.to_s
  end

  def turbo_stream_flash
    streams = []

    if flash[:notice].present?
      streams << turbo_stream.append(
        "toast-container",
        partial: "layouts/common/toast",
        locals: { message: flash[:notice], type: :notice }
      )
    end

    if flash[:alert].present?
      streams << turbo_stream.append(
        "toast-container",
        partial: "layouts/common/toast",
        locals: { message: flash[:alert], type: :alert }
      )
    end

    streams
  end
end
