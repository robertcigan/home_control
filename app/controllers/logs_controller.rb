class LogsController < ApplicationController
  
  def index
    @files = files.collect{|file| [file, File.mtime(File.join(Rails.root, "log", file))]}
  end
  
  def show
    @file = File.join(Rails.root, "log", params[:file])
    @file = nil unless files.include?(params[:file])
    @file_content = `tail -n 1000 #{@file}`
    render
  end
  
  protected
  
  def files
    Dir.entries(File.join(Rails.root, "log")).select{|file| file.ends_with?(".log")}
  end
end
