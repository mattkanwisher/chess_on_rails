irb = RUBY_PLATFORM =~ /(:?mswin|mingw)/ ? 'irb.bat' : 'irb'

require 'optparse'

options = { :sandbox => false, :irb => irb }
OptionParser.new do |opt|
  opt.banner = "Usage: console [environment] [options]"
  opt.on('-s', '--sandbox', 'Rollback database modifications on exit.') { |v| options[:sandbox] = v }
  opt.on('-n', '--nodsl', 'Do not include DSL extensions to make chess match management easier.') { |v| options[:nodsl] = v }
  opt.on("--irb=[#{irb}]", 'Invoke a different irb.') { |v| options[:irb] = v }
  opt.on("--debugger", 'Enable ruby-debugging for the console.') { |v| options[:debugger] = v }
  opt.parse!(ARGV)
end

libs =  " -r irb/completion"
libs << %( -r "#{RAILS_ROOT}/config/environment")
libs << " -r console_app"
libs << " -r console_sandbox" if options[:sandbox]
libs << " -r console_with_helpers"

# HACK - pull in models and my own DSL (which could break the loading of alot of things, since it overrides const_missing)
unless options[:nodsl]
  Dir.glob("#{RAILS_ROOT}/app/models/**/*.rb") do |m|
    libs << " -r #{m}"
  end
  libs << " -r console_dsl"
end

if options[:debugger]
  begin
    require 'ruby-debug'
    libs << " -r ruby-debug"
    puts "=> Debugger enabled"
  rescue Exception
    puts "You need to install ruby-debug to run the console in debugging mode. With gems, use 'gem install ruby-debug'"
    exit
  end
end

ENV['RAILS_ENV'] = case ARGV.first
  when "p"; "production"
  when "d"; "development"
  when "t"; "test"
  else
    ARGV.first || ENV['RAILS_ENV'] || 'development'
end

if options[:sandbox]
  puts "Loading #{ENV['RAILS_ENV']} environment in sandbox (Rails #{Rails.version})"
  puts "Any modifications you make will be rolled back on exit"
else
  puts "Loading #{ENV['RAILS_ENV']} environment (Rails #{Rails.version})"
end
exec "#{options[:irb]} #{libs} --simple-prompt"
