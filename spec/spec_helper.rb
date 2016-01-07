Bundler.setup(:default, :spec)

$spec_dir = File.dirname(__FILE__)
require File.join(File.expand_path($spec_dir), '../lib/lypack')
require 'fileutils'
require 'open3'

$packages_dir = Lypack.packages_dir
$lilyponds_dir = Lypack.lilyponds_dir

module Lypack
  def self.packages_dir
    $packages_dir
  end
  
  def self.lilyponds_dir
    $lilyponds_dir
  end
  
  def self.settings_file
    "/tmp/#{Lypack::SETTINGS_FILENAME}"
  end
  
  module Lilypond
    def self.get_system_lilyponds_paths
      []
    end

    def self.session_settings_filename
      "/tmp/lypack.session.#{Process.pid}.yml"
    end
    
    def self.exec(cmd)
      Open3.popen3(cmd) do |_in, _out, _err, wait_thr|
        exit_value = wait_thr.value
        if exit_value != 0
          raise "Error executing cmd #{cmd}: #{_err.read}"
        end
      end
    end
  end
end

def with_packages(setup)
  begin
    old_packages_dir = $packages_dir
    $packages_dir = File.expand_path("package_setups/#{setup}", $spec_dir)
    
    # remove settings file
    FileUtils.rm_f(Lypack.settings_file)
    FileUtils.rm_f(Lypack::Lilypond.session_settings_filename)
    
    yield
  ensure
    # remove settings file
    FileUtils.rm_f(Lypack.settings_file)
    FileUtils.rm_f(Lypack::Lilypond.session_settings_filename)

    $packages_dir = old_packages_dir
  end
end

def with_lilyponds(setup)
  begin
    old_lilyponds_dir = $lilyponds_dir
    $lilyponds_dir = File.expand_path("lilypond_setups/#{setup}", $spec_dir)

    # remove settings file
    FileUtils.rm_f(Lypack.settings_file)
    FileUtils.rm_f(Lypack::Lilypond.session_settings_filename)
    
    original_files = Dir["#{$lilyponds_dir}/*"]

    yield
  ensure
    # remove settings file
    FileUtils.rm_f(Lypack.settings_file)
    FileUtils.rm_f(Lypack::Lilypond.session_settings_filename)
    
    # remove any created files
    
    Dir["#{$lilyponds_dir}/*"].each do |fn|
      FileUtils.rm_rf(fn) unless original_files.include?(fn)
    end

    $lilyponds_dir = old_lilyponds_dir
  end
end