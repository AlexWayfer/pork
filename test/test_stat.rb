
require 'pork/test'
require 'stringio'

describe Pork::Stat do
  before do
    @executor = Class.new(Pork::Executor){init}
  end

  def skip_if_backtrace_is_wrong
    0.should == {
    }
  rescue Pork::Failure => e
    skip unless e.respond_to?(:backtrace_locations)
    File.open(__FILE__) do |f|
      line = e.backtrace_locations.find{ |l|
               l.label.include?('skip_if_backtrace_is_wrong')
             }.lineno.times.inject(''){ f.readline }
      skip if line.include?('}')
    end
  end

  def run check=:expect_one_error
    stat = Pork::Stat.new(Pork.report_class.new(StringIO.new))
    stat.protected_exceptions = pork_stat.protected_exceptions
    @stat = @executor.execute(Pork.execute_mode, stat)
    send(check)
  end

  def expect_one_error
    expect(@stat.reporter.io.string).eq "\e[31mE\e[0m"
    expect(@stat.tests)     .eq 1
    expect(@stat.assertions).eq 0
    expect(@stat.errors)    .eq 1
  end

  def expect_one_failure
    expect(@stat.reporter.io.string).eq "\e[35mF\e[0m"
    expect(@stat.tests)     .eq 1
    expect(@stat.assertions).eq 0
    expect(@stat.failures)  .eq 1
  end

  would 'rescue custom errors' do
    @executor.would{ raise WebMockError }
    run
  end

  would 'always have backtrace' do
    @executor.would{}
    run

    err, _, test = @stat.exceptions.first
    err.set_backtrace([])

    expect(err).kind_of?(Pork::Error)
    expect(err.message).eq 'Missing assertions'
    expect(@stat.reporter.send(:show_backtrace, test, err)).not.empty?
  end

  describe 'Pork::Stat#show_source' do
    def verify source, check=:expect_one_error
      run(check)
      err, _, test = @stat.exceptions.first
      yield(err) if block_given?
      expect(@stat.reporter.send(:show_source, test, err)).include?(source)
    end

    would 'one line' do
      @executor.would{ flunk }
      verify('=> @executor.would{ flunk }')
    end

    would 'more lines' do
      @executor.would do
        flunk
      end
      verify(<<-SOURCE.chomp)
     @executor.would do
\e[41m  =>   flunk\e[0m
     end
      SOURCE
    end

    would 'multiple lines' do
      @executor.would do
        raise \
          'error'
      end
      verify(<<-SOURCE.chomp)
     @executor.would do
\e[41m  =>   raise \\\e[0m
\e[41m  =>     'error'\e[0m
     end
      SOURCE
    end

    would 'multiple lines with == {}' do
      skip_if_backtrace_is_wrong
      @executor.would do
        0.should == {


        }
      end
      verify(<<-SOURCE.chomp, :expect_one_failure)
     @executor.would do
\e[41m  =>   0.should == {\e[0m
\e[41m  => \e[0m
\e[41m  => \e[0m
\e[41m  =>   }\e[0m
     end
      SOURCE
    end

    would 'show the line in the test, not other methods' do
      @executor.send(:define_method, :f){ flunk }
      @executor.would do
        f
      end
      verify(<<-SOURCE.chomp)
     @executor.would do
\e[41m  =>   f\e[0m
     end
      SOURCE
    end

    would 'show the line in the test, even if it is from 3rd party' do
      @executor.would{ flunk }
      verify("=> @executor.would{ flunk }") do |err|
        err.set_backtrace(err.backtrace.unshift("bad.rb:#{__LINE__}"))
      end
    end
  end
end
