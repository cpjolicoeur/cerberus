require 'yaml'
require 'latch'
require 'vcs'
require 'util'

module Cerberus
  class Manager
    CERBERUS_HOME = '~/.cerberus'

    def self.project_config_path(project_name, cerberus_home = CERBERUS_HOME)
      File.join(cerberus_home, 'config', project_name + '.yml')
    end

    def initialize(project_name, options = {})
      @project_name = project_name
      @cerberus_home = options[:cerberus_home] || CERBERUS_HOME

      path = Manager::project_config_path(project_name, @cerberus_home)
      raise "Configuration file '#{path}' for running project not found" unless File.exists?(path)
      @config = load_yaml(path)
      raise "Repository url for project does not specified" if @config['url'].nil?

      @workdir = File.join(@cerberus_home, 'work', project_name)

      #crete dir structure
      %w(src logs sources).each do |dir| 
        d = File.join(@workdir, dir)
        FileUtils.mkpath(d) unless File.exists?(d)
      end
    end

    def run!
#      Latch::fs_lock(File.join(@workdir, '.lock')) do
        infofile = File.join(@workdir, 'build_info')

        info = load_yaml(infofile)
        repo = Cerberus::VCS.guess_vcs(@workdir).new(@workdir + '/sources', @config['url'])

        repo.update!
        return if repo.latest_revision == info['last_build'] #there is no changes
#      end
    end

    def self.run!(project_name, options)
      w = Cerberus::Manager.new(project_name, options)
      w.run!
    end

    def self.add!(directory, options)
      project_name = ask_user('Enter name of the project', File.basename(File.expand_path(directory)), options[:quiet])
      config_file = project_config_path(project_name, options[:cerberus_home])
      fail "Project with name '#{project_name}' already exists" if File.exists?(config_file)
      url = Cerberus::VCS.guess_vcs(directory).project_url(directory)
      config = {'url' => url}

      FileUtils.mkdir_p(File.dirname(config_file))
      save_yaml(config, config_file)
    end
  end
end