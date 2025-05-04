class BackupsController < ApplicationController
  def show
    @db_name = ActiveRecord::Base.connection.current_database
    @timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
  end

  def download
    db_name = ActiveRecord::Base.connection.current_database
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    format = params[:format]

    case format
    when 'sql'
      filename = "#{db_name}_#{timestamp}.sql"
      content_type = 'application/sql'
      dump_cmd = "pg_dump --no-acl --no-owner #{db_name}"
    when 'custom'
      filename = "#{db_name}_#{timestamp}.dump"
      content_type = 'application/octet-stream'
      dump_cmd = "pg_dump -Fc --no-acl --no-owner #{db_name}"
    else
      return head :bad_request
    end

    begin
      dump = `#{dump_cmd}`
      send_data dump, filename: filename, type: content_type, disposition: 'attachment'
    rescue => e
      flash[:alert] = "Error creating backup: #{e.message}"
      redirect_to backup_path
    end
  end
end