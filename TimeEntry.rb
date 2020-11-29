class TimeEntry 
  attr_accessor :time, :type, :note
  def self.from_line(l)
    m = /(in:|out:) 0{0,2}(\d{2,4})[ ]?(.+)?/.match(l)
    raise "Line isn't a match: #{l}" if m.nil?
    type = m[1]
    time = Integer(m[2])
    note = m[3]
    TimeEntry.new(type, time, note)
  end

  def self.clock_in_now(note)
    note = note || ""
    t = Time.now
    TimeEntry.new("in:", Integer(t.strftime("%K%M")), note)
  end

  def self.clok_out_now(note)
    note = note || ""
    t = Time.now
    TimeEntry.new("out:", Integer(t.strftime("%K%M")), note)
  end

  NOTE_TYPES = %w(in: out:)
  def initialize(type, time, note = "") 
    note ||= ""
    raise "Type must be in: or out:" unless NOTE_TYPES.include?(type)
    raise "Time should be an integer between 0 and 2399" unless (
      time.is_a? Integer and
      time >= 0 and
      time < 2400)

    raise "Note should be a string!" unless note.is_a? String
    @type = type
    @time = time
    @note = note
  end

  def to_s
    "#{@type} #{@time.to_s.rjust(4, '0')} #{@note}"
  end
end
