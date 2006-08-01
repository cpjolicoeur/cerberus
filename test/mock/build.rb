class DummyBuild
  attr_reader :output, :scm
  SCM = Struct.new(:last_commit_message, :current_revision, :last_author)

  def initialize(last_commit_message, output, current_revision, last_author)
    @output = output

    @scm = SCM.new(last_commit_message, current_revision, last_author)
  end
end