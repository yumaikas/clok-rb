require 'optimist'
require_relative 'TimeEntry'
require_relative 'TimeRegistry'
require_relative 'TimeClok'

def switch()
  opts = Optimist::options do
    opt :project, "The project to use switch to", :required => true, :type => :string
  end

  clok.load(false)
  # If we are clocked in, clok out before we switch projects
  if clok.state == :IN
    clok.out("")
  end

  SETTINGS.set_project(opts[:project])
end

def _in(clok)
  opts = Optimist::options do
    opt :note, "A note to add to the project", :required => false, :type => :string
  end

  clok.load(true)
  clok.in(opts[:note])
end

def out(clok)
  opts = Optimist::options do
    opt :note, "A note to add to the project", :required => false, :type => :string
  end

  clok.load(true)
  clok.out(opts[:note])

end

def total(clok)
  opts = Optimist::options do
    opt :value, "A note to add to the project", :required => false, :type => :bool
  end

  clok.load(false)
  total_minutes = clok.total()
  if not opts[:value] then
    puts "Total time: #{total_minutes / 60}hr #{total_minutes % 60}min"
  else
    puts "#{total_minutes.to_f / 60}"
  end
end

def worked(clok)
  clok.load(false)
  clok.worked
end

def help(cmd)
  puts "Unrecognized command #{cmd}"
  puts """
  Examples: 
    clok in
    clok out
    clok switch $project
    clok in -n \"These are some notes\"
  """
end

TIME_DIR = 'C:/Users/yumai/Dev/Ruby/clok/time_dir'
SETTINGS = TimeRegistry.new(TIME_DIR)
SETTINGS.ensure_dir

clok = TimeClok.new(SETTINGS)

SUB_COMMANDS = %w(i in o out s switch t total w worked)

global_opts = Optimist::options do
  banner "Clok helps track time across various projects"
  stop_on SUB_COMMANDS
end

cmd = ARGV.shift

case cmd
  when "s", "switch" then switch()
  when "i", "in" then _in(clok)
  when "o", "out" then out(clok)
  when "t", "total" then total(clok)
  when "w", "worked" then worked(clok)
  else help(cmd)
end

