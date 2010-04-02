module Cerberus
  module SCM
    TYPES = {
      :svn => 'SVN', #Cerberus::SCM
      :darcs => 'Darcs',
      :perforce => 'Perforce',
      :cvs => 'CVS',
      :bzr => 'Bazaar',
      :git => 'Git',
      :hg => 'Mercurial'
    }

    def self.get(type)
      class_name = TYPES[type.to_sym]
      say "SCM #{type} not supported" unless class_name
      require "cerberus/scm/#{type}"
      const_get(class_name)
    end


    def self.guess_type(path)
      if test(?d, path)
        case
        when test(?d, path+'/.svn')
          'svn'
        when test(?d, path+'/_darcs')
          'darcs'
        when test(?d, path+'/.cvs')
          'cvs'
        when test(?d, path+'/.bzr')
          'bzr'          
        when test(?d, path+'/.git')
          'git'          
        when test(?d, path+'/.hg')
          'hg'          
        end
      else
        #guess SCM type by its url
        case path
        when /^:(pserver|ext|local):/
          'cvs'
        when /^(bzr+ssh|bzr)/
          'bzr'
        end
      end
    end
  end

  module Publisher
    TYPES = {
      :mail => 'Mail',
      :jabber => 'Jabber',
      :irc => 'IRC',
      :rss => 'RSS',
      :campfire => 'Campfire',
      :twitter => 'Twitter'
    }

    def self.get(type, config)
      class_name = TYPES[type.to_sym]
      if not class_name
        class_name = config[:class_name]
        say "Publisher #{type} not supported" unless class_name
        require config[:require]
      else
        require "cerberus/publisher/#{type}"
      end
      const_get(class_name)
    end
  end

  module Builder
    TYPES = {
      :maven2 => 'Maven2', #Cerberus::Builder
      :rake => 'Rake',
      :rspec => 'RSpec',
      :rant => 'Rant',
      :bjam => 'Bjam',
      :ruby => 'Ruby'
    }

    def self.get(type)
      class_name = TYPES[type.to_sym]
      say "Builder #{type} not supported" unless class_name
      require "cerberus/builder/#{type}"
      const_get(class_name)
    end
  end
end
