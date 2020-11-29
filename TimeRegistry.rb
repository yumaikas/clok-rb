require 'fileutils'

class TimeRegistry

  def initialize(time_path)
    @time_path = time_path
  end

  def current_time_file
    File.join(current_time_dir, "current.txt")
  end

  def file_for_day(day)
    File.join(current_time_dir, day, ".txt")
  end

  def current_time_dir
    File.join(@time_path, current_project)
  end

  def current_project
    read_setting("current_proj", "default")
  end

  def set_project(new_project)
    write_setting("current_proj", new_project)
  end

  def ensure_dir
    unless File.directory?(current_time_dir)
      FileUtils.mkdir_p(current_time_dir)
    end
  end

  private

  def read_setting(setting_name, fallback="")
    path = File.join(@time_path, setting_name)
    if File.exist?(path)
      IO.read(path)
    else
      fallback
    end
  end

  def write_setting(setting_name, value)
    path = File.join(@time_path, setting_name)
    IO.write(path, value)
  end
end
