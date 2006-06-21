require 'yaml'
require 'latch'
require 'vcs'
require 'util'

module Cerberus
  class Manager
    CERBERUS_DIR = 'C:\work\ruby\cerberus' #File.dirname(__FILE__) + '..'
    include Util

    def self.project_config_path(project_name)
      File.join(CERBERUS_DIR, 'config', project_name + '.yml')
    end

    def initialize(project_name, options = {})
      @project_name = project_name

      path = project_config_path(project_name)
      raise "Configuration file for project '#{project_name}' not found in configuration directory" unless File.exists?(path)
      @config = load_yaml(path)
      raise "Repository url for project does not specified" if @config['url'].nil?

      @workdir = File.join(CERBERUS_DIR, 'work', project_name)

      #crete dir structure
      %w(src logs).each do |dir| 
        d = File.join(@workdir, dir)
        FileUtils.mkpath(d) unless File.exists?(d)
      end
    end

    def run!
      Latch::fs_lock(File.join(@workdir, '.lock')) do
        infofile = File.join(@workdir, 'build_info')

        repo = Cerberus::VCS.guess_vcs(@workdir).new(@workdir, @config)

        repo.update!
        info = load_yaml(infofile)
        return if repo.latest_revision == info['last_build'] #there is no changes
      end
    end

    def self.run!(project_name)
      w = Cerberus::Runner.new(project_name)
      w.run!
    end

    def self.add!(directory)
      project_name = ask_user('Enter name of the project', File.basename(directory))
      config_file = project_config_path(project_name)
      fail "Project with name '#{project_name}' already exists" if File.exists?(config_file)
      url = Cerberus::VCS.guess_vcs(directory).project_url(directory)
      config = {'url' => url}
      save_yaml(config, config_file)
    end
  end
end