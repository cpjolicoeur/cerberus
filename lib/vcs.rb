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
        svn_info(/<commit\W+revision="(\d+)">/, @path).to_i
      end

      def checkout
        system "svn checkout #{@url} #{@path}"
      end

      def self.project_url(dir)
        svn_info(/<url>(\w)+<\/url>/, dir)
      end

      private
      def self.svn_info(regexp, dir)
        info = `svn info --xml #{dir}`
        if svn_info =~ regexp
          return $1
        else
          fail "Could not parse 'svn info' for directory #{dir}"
        end
      end
    end
  end
end