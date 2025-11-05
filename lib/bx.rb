module BX
  VERSION = '0.1.0' unless defined?(BX::VERSION)

  def BX.version
    BX::VERSION
  end

  def BX.libdir(*args, &block)
    @libdir ||= File.expand_path(__FILE__).sub(/\.rb$/, '')
    args.empty? ? @libdir : File.join(@libdir, *args)
  ensure
    if block
      begin
        $LOAD_PATH.unshift(@libdir)
        block.call()
      ensure
        $LOAD_PATH.shift()
      end
    end
  end

  def BX.load(*libs)
    libs = libs.join(' ').scan(/[^\s+]+/)
    BX.libdir { libs.each { |lib| Kernel.load(lib) } }
  end
end

# Load dependencies
require 'sqlite3'
require 'map'
require 'fattr'
require 'lockfile'
require 'dotenv'

# Load library components (will be created in foundational phase)
# BX.load %w[
#   bx/version.rb
#   bx/state_manager.rb
#   bx/tmux_wrapper.rb
#   bx/box.rb
#   bx/process.rb
#   bx/environment.rb
#   bx/detector.rb
#   bx/history.rb
#   bx/cli.rb
# ]
