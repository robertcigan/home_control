module Capistrano
  class Arduino::Systemd < Capistrano::Plugin
    def arduino_user(role)
      properties = role.properties
      properties.fetch(:arduino_user) || # local property for arduino only
          fetch(:arduino_user) ||
          properties.fetch(:run_as) || # global property across multiple capistrano gems
          role.user
    end
  
    def template_arduino(from, to, role)
      @role = role
      file = [
          "lib/capistrano/templates/#{from}-#{role.hostname}-#{fetch(:stage)}.rb",
          "lib/capistrano/templates/#{from}-#{role.hostname}.rb",
          "lib/capistrano/templates/#{from}-#{fetch(:stage)}.rb",
          "lib/capistrano/templates/#{from}.rb.erb",
          "lib/capistrano/templates/#{from}.rb",
          "lib/capistrano/templates/#{from}.erb",
          "config/deploy/templates/#{from}.rb.erb",
          "config/deploy/templates/#{from}.rb",
          "config/deploy/templates/#{from}.erb",
          File.expand_path("../templates/#{from}.erb", __FILE__),
          File.expand_path("../templates/#{from}.rb.erb", __FILE__)
      ].detect { |path| File.file?(path) }
      erb = File.read(file)
      backend.upload! StringIO.new(ERB.new(erb, nil, '-').result(binding)), to
    end

    def register_hooks
      after 'deploy:finished', 'arduino:restart'
    end

    def define_tasks
      eval_rakefile File.expand_path('../../tasks/arduino_systemd.rake', __FILE__)
    end

    def set_defaults
      set_if_empty :arduino_role, :app
      
      set_if_empty :arduino_access_log, -> { File.join(shared_path, 'log', 'arduino_access.log') }
      set_if_empty :arduino_error_log, -> { File.join(shared_path, 'log', 'arduino_error.log') }

      set_if_empty :arduino_systemctl_bin, '/bin/systemctl'
      set_if_empty :arduino_service_unit_name, -> { "arduino_#{fetch(:application)}_#{fetch(:stage)}" }
      set_if_empty :arduino_systemctl_user, :system
      set_if_empty :arduino_enable_lingering, -> { fetch(:arduino_systemctl_user) != :system }
      set_if_empty :arduino_lingering_user, -> { fetch(:user) }
    end
  end
end