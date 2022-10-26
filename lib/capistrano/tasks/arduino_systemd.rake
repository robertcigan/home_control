git_plugin = self
namespace :arduino do
  namespace :systemd do
    desc 'Config Arduino systemd service'
    task :config do
      on roles(fetch(:arduino_role)) do |role|
        unit_filename = "#{fetch(:arduino_service_unit_name)}.service"
        git_plugin.template_arduino "arduino.service", "#{fetch(:tmp_dir)}/#{unit_filename}", role
        systemd_path = fetch(:arduino_systemd_conf_dir, git_plugin.fetch_systemd_unit_path)
        if fetch(:arduino_systemctl_user) == :system
          sudo "mv #{fetch(:tmp_dir)}/#{unit_filename} #{systemd_path}"
          sudo "#{fetch(:arduino_systemctl_bin)} daemon-reload"
        else
          execute :mkdir, "-p", systemd_path
          execute :mv, "#{fetch(:tmp_dir)}/#{unit_filename}", "#{systemd_path}"
          execute fetch(:arduino_systemctl_bin), "--user", "daemon-reload"
        end
      end
    end

    desc 'Enable Arduino systemd service'
    task :enable do
      on roles(fetch(:arduino_role)) do
        if fetch(:arduino_systemctl_user) == :system
          sudo "#{fetch(:arduino_systemctl_bin)} enable #{fetch(:arduino_service_unit_name)}"
        else
          execute "#{fetch(:arduino_systemctl_bin)}", "--user", "enable", fetch(:arduino_service_unit_name)
          execute :loginctl, "enable-linger", fetch(:arduino_lingering_user) if fetch(:arduino_enable_lingering)
        end
      end
    end

    desc 'Disable Arduino systemd service'
    task :disable do
      on roles(fetch(:arduino_role)) do
        if fetch(:arduino_systemctl_user) == :system
          sudo "#{fetch(:arduino_systemctl_bin)} disable #{fetch(:arduino_service_unit_name)}"
        else
          execute "#{fetch(:arduino_systemctl_bin)}", "--user", "disable", fetch(:arduino_service_unit_name)
        end
      end
    end
  end

  desc 'Start Arduino service via systemd'
  task :start do
    on roles(fetch(:arduino_role)) do
      if fetch(:arduino_systemctl_user) == :system
        sudo "#{fetch(:arduino_systemctl_bin)} start #{fetch(:arduino_service_unit_name)}"
      else
        execute "#{fetch(:arduino_systemctl_bin)}", "--user", "start", fetch(:arduino_service_unit_name)
      end
    end
  end

  desc 'Stop Arduino service via systemd'
  task :stop do
    on roles(fetch(:arduino_role)) do
      if fetch(:arduino_systemctl_user) == :system
        sudo "#{fetch(:arduino_systemctl_bin)} stop #{fetch(:arduino_service_unit_name)}"
      else
        execute "#{fetch(:arduino_systemctl_bin)}", "--user", "stop", fetch(:arduino_service_unit_name)
      end
    end
  end

  desc 'Restart Arduino service via systemd'
  task :restart do
    on roles(fetch(:arduino_role)) do
      if fetch(:arduino_systemctl_user) == :system
        sudo "#{fetch(:arduino_systemctl_bin)} restart #{fetch(:arduino_service_unit_name)}"
      else
        execute "#{fetch(:arduino_systemctl_bin)}", "--user", "restart", fetch(:arduino_service_unit_name)
      end
    end
  end

  desc 'Get Arduino service status via systemd'
  task :status do
    on roles(fetch(:arduino_role)) do
      if fetch(:arduino_systemctl_user) == :system
        sudo "#{fetch(:arduino_systemctl_bin)} status #{fetch(:arduino_service_unit_name)}"
      else
        execute "#{fetch(:arduino_systemctl_bin)}", "--user", "status", fetch(:arduino_service_unit_name)
      end
    end
  end

  def fetch_systemd_unit_path
    if fetch(:arduino_systemctl_user) == :system
      "/etc/systemd/system/"
    else
      home_dir = backend.capture :pwd
      File.join(home_dir, ".config", "systemd", "user")
    end
  end
end