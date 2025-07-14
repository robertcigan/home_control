class BackupsController < ApplicationController
  def show
    @db_name = ActiveRecord::Base.connection.current_database
    @timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
  end

  def download
    db_config = ActiveRecord::Base.connection_db_config
    db_name = db_config.database
    db_user = db_config.configuration_hash[:username]
    db_host = db_config.configuration_hash[:host] || 'localhost'
    db_port = db_config.configuration_hash[:port] || 5432
    db_password = db_config.configuration_hash[:password]

    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    format = params[:format]

    case format
    when 'sql'
      filename = "#{db_name}_#{timestamp}.sql"
      content_type = 'application/sql'
      format_flag = ''
    when 'custom'
      filename = "#{db_name}_#{timestamp}.dump"
      content_type = 'application/octet-stream'
      format_flag = '-Fc'
    else
      return head :bad_request
    end

    dump_cmd = [
      "PGPASSWORD='#{db_password}'",
      "pg_dump",
      format_flag,
      "--no-acl --no-owner",
      "-h #{db_host}",
      "-p #{db_port}",
      "-U #{db_user}",
      db_name
    ].join(' ')

    begin
      dump = `#{dump_cmd}`
      if $?.success?
        send_data dump, filename: filename, type: content_type, disposition: 'attachment'
      else
        Rails.logger.error "pg_dump failed: #{dump}"
        flash[:alert] = "Error creating backup."
        redirect_to backup_path
      end
    rescue => e
      Rails.logger.error "Backup failed: #{e.message}"
      flash[:alert] = "Error creating backup: #{e.message}"
      redirect_to backup_path
    end
  end
end