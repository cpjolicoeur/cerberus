module Cerberus
  module SCM
    TYPES = {
      :svn => 'SVN', #Cerberus::SCM
      :darcs => 'Darcs',
      :perforce => 'Perforce'
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
        end
      else
        #guess SCM type by its url
        case path
        when /^:(pserver|ext|local):/
          'cvs'
        end
      end
    end
  end

  module Publisher
    TYPES = {
      :mail => 'Mail', #Cerberus::Publisher
      :jabber => 'Jabber',
      :irc => 'IRC',
      :rss => 'RSS',
      :campfire => 'Campfire'
    }

    def self.get(type)
       class_name = TYPES[type.to_sym]
       say "Publisher #{type} not supported" unless class_name
       require "cerberus/publisher/#{type}"
       const_get(class_name)
    end
  end

  module Builder
    TYPES = {
      :maven2 => 'Maven2', #Cerberus::Builder
      :rake => 'Rake',
      :rant => 'Rant',
      :bjam => 'Bjam'
    }

    def self.get(type)
       class_name = TYPES[type.to_sym]
       say "Builder #{type} not supported" unless class_name
       require "cerberus/builder/#{type}"
       const_get(class_name)
    end
  end
end
