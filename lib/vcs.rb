module Cerberus
  module VCS
    def self.guess_vcs(path)
      Cerberus::VCS::Subversion #there is only subversion support
    end

    class Subversion
      def initialize(path, url)
        @path = path
        @url = url
      end

      def update
        system "svn update #{@path}"
      end

      def latest_revision
        Subversion::svn_info(/<commit\W+revision="(\d+)">/, @path).to_i
      end

      def checkout
        system "svn checkout #{@url} #{@path}"
      end

      def self.project_url(dir)
        Subversion::svn_info(/<url>(.+)<\/url>/, dir)
      end

      private
      def self.svn_info(regexp, dir)
        info_response = `svn info --xml #{dir}`
        if info_response =~ regexp
          return $1
        else
          puts info_response
          fail "Could not parse 'svn info' for directory #{dir}"
        end
      end
    end
  end
end