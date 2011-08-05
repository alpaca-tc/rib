
require 'rib/test'
require 'rib/more/squeeze_history'

describe Rib::SqueezeHistory do
  before do
    @history = '/tmp/test_rib_history'
    @shell   = Rib::Shell.new(:history => @history).before_loop
    @input   = %w[foo bar bar foo bar]
    @shell.history.clear
  end

  after do; FileUtils.rm_f(@history); Rib.enable_squeeze_history; end

  should 'after_loop saves squeezed history' do
    @shell.history.push(*@input)
    @shell.instance_variable_set('@input', '')
    @shell.after_loop
    File.read(@history).should == %w[foo bar foo bar].join("\n") + "\n"
  end

  should 'loop_once squeeze history' do
    times = @input.size
    stub(@shell).get_input{ (@shell.history << "'#{@input.shift}'")[-1] }
    stub(@shell).print_result(anything)
    times.times{ @shell.loop_once }
    @shell.history.to_a.should == %w[foo bar foo bar].map{ |i| "'#{i}'" }
  end

  should 'be disabled if disabled' do
    Rib.disable_squeeze_history
    times = @input.size
    input = @input.dup
    stub(@shell).get_input{ (@shell.history << "'#{@input.shift}'")[-1] }
    stub(@shell).print_result(anything)
    times.times{ @shell.loop_once }
    @shell.history.to_a.should == input.map{ |i| "'#{i}'" }
  end
end