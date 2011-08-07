
require 'rib'

module Rib::Runner
  module_function
  def options
    @options ||=
    [['ruby options:'    , ''                                        ],
     ['-e, --eval LINE'                                               ,
      'Evaluate a LINE of code'                                      ],

     ['-d, --debug'                                                   ,
      'Set debugging flags (set $DEBUG to true)'                     ],

     ['-w, --warn'                                                    ,
       'Turn warnings on for your script (set $-w to true)'          ],

     ['-I, --include PATH'                                            ,
       'Specify $LOAD_PATH (may be used more than once)'             ],

     ['-r, --require LIBRARY'                                         ,
       'Require the library, before executing your script'           ],

     ['rib options:'     , ''                                        ],
     ['-c, --config FILE', 'Load config from FILE'                   ],
     ['-n, --no-config'  , 'Suppress loading ~/.config/rib/config.rb'],
     ['-h, --help'       , 'Print this message'                      ],
     ['-v, --version'    , 'Print the version'                       ]] +

    [['rib commands:'    , '']] + commands
  end

  def commands
     @commands ||=
      command_names.map{ |n| [n, command_descriptions[n] || ' '] }
  end

  def command_names
    @command_names ||=
    Gem.path.map{ |path|
      Dir["#{path}/bin/*"].map{ |f|
        (File.executable?(f) && File.basename(f) =~ /^rib\-(\w+)$/ && $1) ||
         nil    # a trick to make false to be nil and then
      }.compact # this compact could eliminate them
    }.flatten
  end

  def command_descriptions
    @command_descriptions ||=
    {'all'    => 'Load all recommended plugins'                ,
     'auto'   => 'Run as Rails or Ramaze console (auto-detect)',
     'rails'  => 'Run as Rails console'                        ,
     'ramaze' => 'Run as Ramaze console'                       }
  end

  def run argv=ARGV
    (@running_commands ||= []) << Rib.config[:name]
    unused = parse(argv)
    # if it's running a Rib command, the loop would be inside Rib itself
    # so here we only parse args for the command
    return if @running_commands.pop != 'rib'
    # by comming to this line, it means now we're running Rib main loop,
    # not any other Rib command
    Rib.warn("Unused arguments: #{unused.inspect}") unless unused.empty?
    Rib.shell.loop
  end

  def parse argv
    unused = []
    until argv.empty?
      case arg = argv.shift
      when /-e=?(.+)?/, /--eval=?(.+)?/
        eval($1 || argv.shift, binding, __FILE__, __LINE__)

      when '-d', '--debug'
        $DEBUG = true

      when '-w', '--warn'
        $-w, $VERBOSE = true, true

      when /-I=?(.+)?/, /--include=?(.+)?/
        paths = ($1 || argv.shift).split(':')
        $LOAD_PATH.unshift(*paths)

      when /-r=?(.+)?/, /--require=?(.+)?/
        require($1 || argv.shift)

      when /-c=?(.+)?/, /--config=?(.+)?/
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

      when /^[^-]/
        load_command(arg)

      else
        unused << arg
      end
    end
    unused
  end

  def help
    maxn = options.transpose.first.map(&:size).max
    maxd = options.transpose.last .map(&:size).max
    "Usage: #{Rib.config[:name]}"                    \
    " [ruby OPTIONS] [rib OPTIONS] [rib COMMANDS]\n" +
    options.map{ |(name, desc)|
      if desc.empty?
        name
      else
        sprintf("  %-*s  %-*s", maxn, name, maxd, desc)
      end
    }.join("\n")
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
