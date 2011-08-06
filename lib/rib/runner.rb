
require 'rib'

module Rib::Runner
  module_function
  def options
    { # Ruby OPTIONS
     '-e, --eval LINE'       =>
       'Evaluate a LINE of code'                                      ,

     '-d, --debug'           =>
       'Set debugging flags (set $DEBUG to true)'                     ,

     '-w, --warn'            =>
       'Turn warnings on for your script (set $-w to true)'           ,

     '-I, --include PATH'    =>
       'Specify $LOAD_PATH (may be used more than once)'              ,

     '-r, --require LIBRARY' =>
       'Require the library, before executing your script'            ,

      # Rib OPTIONS
     '-c, --config FILE' => 'Load config from FILE'                   ,
     '-n, --no-config'   => 'Suppress loading ~/.config/rib/config.rb',
     '-h, --help'        => 'Print this message'                      ,
     '-v, --version'     => 'Print the version'                       }
  end

  def run argv=ARGV
    (@commands ||= []) << Rib.config[:name]
    unused = parse(argv)
    # if it's running a rib command, the loop would be inside rib itself
    # so here we only parse args for the command
    return if @commands.pop != 'rib'
    # by comming to this line, it means now we're running rib main loop,
    # not any other rib command
    Rib.warn("Unused arguments: #{unused.inspect}") unless unused.empty?
    Rib.shell.loop
  end

  def parse argv
    unused = []
    until argv.empty?
      case arg = argv.shift
      when /-e=?(.*)/, /--eval=?(.*)/
        eval($1 || argv.shift, __FILE__, __LINE__)

      when '-d', '--debug'
        $DEBUG = true

      when '-w', '--warn'
        $-w = true

      when /-I=?(.*)/, /--include=?(.*)/
        paths = ($1 || argv.shift).split(':')
        $LOAD_PATH.unshift(*paths)

      when /-r=?(.*)/, /--require=?(.*)/
        require($1 || argv.shift)

      when /-c=?(.*)/, /--config=?(.*)/
        Rib.config[:config] = $1 || argv.shift

      when '-n', '--no-config'
        Rib.config.delete(:config)

      when '-h', '--help'
        puts(help)
        exit

      when '-v', '--version'
        require 'rib/version'
        puts(Rib::VERSION)
        exit

      when /[^-]+/
        load_command(arg)

      else
        unused << arg
      end
    end
    unused
  end

  def help
    maxn = options.keys  .map(&:size).max
    maxd = options.values.map(&:size).max
    "Usage: #{name} [Ruby OPTIONS] [Rib COMMAND] [Rib OPTIONS]\n" +
    options.map{ |name, desc|
      sprintf("  %-*s  %-*s", maxn, name, maxd, desc) }.join("\n")
  end

  def load_command command
    bin  = "rib-#{command}"
    path = `which #{bin}`.strip
    if path == ''
      Rib.warn(
        "Can't find #{bin} in $PATH. Please make sure it is installed,",
        "or is there any typo? You can try this to install it:\n"         ,
        "    gem install #{bin}")
    else
      Rib.config[:name] = bin
      load(path)
    end
  end
end
