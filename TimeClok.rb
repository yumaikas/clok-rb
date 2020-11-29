require 'fileutils'
require_relative 'TimeEntry'

class ClokError < StandardError

  attr_reader :line, :lines

  def initialize(msg, line, lines)
    @line = line
    @lines = lines
    super(msg)
  end
end

class TimeClok

  def initialize(settings)
    @settings = settings
    @lines = []
    @loaded = false
    @day = Time.now.strftime("%Y-%m-%d")
  end

  def worked
    puts "Current file: #{@settings.current_time_file}"
    puts IO.read(@settings.current_time_file)
  end

  def load(touch_files = false)
    readonly = not(touch_files)
    return if @loaded 
    unless File.exists?(@settings.current_time_file)
      @lines = []
      IO.write(@settings.current_time_file, "day: #{@day}\n")
      @loaded = true
      return
    end

    lines = File.readlines(@settings.current_time_file)

    if lines.length == 0 then
      @lines = []
      IO.write(@settings.current_time_file, "day: #{@day}\n")
      @loaded = true
      return 
    end

    # Remove the first elements of the time entries
    day_line = lines.shift
    m = /day: (\d{4}-\d{2}-\d{2})/.match(day_line)
    day = m[1] unless m.nil?
    if m.nil? 
      raise "Time file is missing day: declaration!"
    end

    time_lines = []

    lines.each do |l|
      time_lines << TimeEntry.from_line(l)
    end

    # If we have an old day file, go ahead and save it back
    if day != @day and not readonly then
      if time_lines[-1].type == "in:" then
        time_lines << TimeEntry.new("out:", 2359, "Automatically clocked out at end of day")
      end

      save(time_lines, @settings.file_for_day(day), day)
      IO.write(@settings.current_time_file, "day: #{@day}\n")
      time_lines = []
    end

    @lines = time_lines
    @loaded = true
  end

  def state
    if @lines.length == 0 then
      :EMPTY
    elsif @lines.length > 0 && @lines[-1].type == "in:" 
      :IN
    elsif @lines.length > 0 && @lines[-1].type == "out:" 
      :OUT
    end
  end

  def in(note)
    raise "Cannot clock in if you're already clocked in!" if state() == :IN

    note = note || ""
    t = Time.now
    entry = TimeEntry.new("in:", Integer(t.strftime("%H%M")), note)
    @lines << entry
    if @lines.length > 0 && entry.time < @lines[-1].time then
      # If we hit this point, we need to cross over into a new day, methinks.
      entry.time += 2400
      prev_day = Time.now - 24*60*60
      save(@lines, @settings.current_time_file, @day)
      FileUtils.cp(@settings.current_time_file, @settings.file_for_day(@day))
      @lines = []
      @day = Time.now.strftime("%Y-%m-%d")
      return
    end

    save(@lines, @settings.current_time_file, @day)
  end

  def out(note)
    raise "Cannot clock out if file is empty" if state() == :EMPTY
    raise "Cannot clock out if you're already clocked out!" if state() == :OUT

    note = note || ""
    t = Time.now
    entry = TimeEntry.new("out:", Integer(t.strftime("%H%M")), note)
    @lines << entry
    if @lines.length > 0 && entry.time < @lines[-1].time then
      # If we hit this point, we need to cross over into a new day, methinks.
      entry.time += 2400
      prev_day = Time.now - 24*60*60
      save(@lines, @settings.current_time_file, prev_day)
      FileUtils.cp(@settings.current_time_file, @settings.file_for_day(@day))
      @lines = []
      @day = Time.now.strftime("%Y-%m-%d")
      return
    end

    save(@lines, @settings.current_time_file, @day)
  end


  def total()
    if @lines.length == 0 then
      return 0
    end

    total_minutes = 0
    in_time = nil

    @lines.each do |l|
      if in_time.nil? and l.type == "in:" then
        in_time = l.time
      elsif not in_time.nil? and l.type == "out:" then
        total_minutes += minutes_between(in_time, l.time)
        in_time = nil
      elsif in_time.nil? and l.type == "out:" then
        raise ClokError.new("out: given, when in: was expected!", l, @lines)
      elsif not in_time.nil? and l.type == "in:" then
        raise ClokError.new("in: given, when out: was expected!", l, @lines)
      else
        raise ClokError.new("Unexpected line!", l, @lines)
      end
    end

    unless in_time.nil? then
      out_time = TimeEntry.from_line("out: #{Time.now.strftime("%H%M")}")
      total_minutes += minutes_between(in_time, out_time.time)
    else
      return total_minutes
    end
  end


  private

  def minutes_between(in_time, out_time)
    in_hr = in_time / 100
    in_min = in_time % 100
    out_hr = out_time / 100
    out_min = out_time % 100

    (out_hr - in_hr)*60 + (out_min - in_min)
  end

  def save(lines, path, day)
    return unless @loaded
    File.open(path, "w") do |f|
      f.write("day: #{day}\n")
      lines.each do |l|
        f.write("#{l.to_s}\n")
      end
    end
  end

end
