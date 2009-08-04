module Cerberus
  module SCM
    class Base

      def initialize(path, config = {})
        raise "Path can't be nil" unless path

        @path, @config = path.strip, config
        @encoded_path = (@path.include?(' ') ? "\"#{@path}\"" : @path)
      end

      def url
        @path
      end

    end
  end
end

