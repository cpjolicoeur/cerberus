#
# IRCUtil is a module that contains utility functions for use with the
# rest of Ruby-IRC. There is nothing required of the user to know or
# even use these functions, but they are useful for certain tasks
# regarding IRC connections.
#

module IRCUtil
    #
    # Matches hostmasks against hosts. Returns t/f on success/fail.
    #
    # A hostmask consists of a simple wildcard that describes a
    # host or class of hosts.
    #
    # f.e., where the host is 'bar.example.com', a host mask
    # of '*.example.com' would assert.
    #

    def assert_hostmask(host, hostmask)
        return !!host.match(quote_regexp_for_mask(hostmask))
    end

    module_function :assert_hostmask

    #
    # A utility function used by assert_hostmask() to turn hostmasks
    # into regular expressions.
    #
    # Rarely, if ever, should be used by outside code. It's public
    # exposure is merely for those who are interested in it's
    # functionality.
    #

    def quote_regexp_for_mask(hostmask)
        # Big thanks to Jesse Williamson for his consultation while writing this.
        #
        # escape all other regexp specials except for . and *.
        # properly escape . and place an unescaped . before *.
        # confine the regexp to scan the whole line.
        # return the edited hostmask as a string.
        hostmask.gsub(/([\[\]\(\)\?\^\$])\\/, '\\1').
            gsub(/\./, '\.').
            gsub(/\*/, '.*').
            sub(/^/, '^').
            sub(/$/, '$')
    end

    module_function :quote_regexp_for_mask
end
