class DummyManager
  attr_reader :builder, :scm

  DummyScm = Struct.new(:last_commit_message, :current_revision, :last_author)
  DummyBuilder = Struct.new(:output)

  def initialize(last_commit_message, output, current_revision, last_author)
    @scm = DummyScm.new(last_commit_message, current_revision, last_author)
    @builder = DummyBuilder.new(output)
  end
end