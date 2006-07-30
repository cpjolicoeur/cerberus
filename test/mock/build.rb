class DummyBuild
  attr_reader :output, :checkout
  Checkout = Struct.new(:last_commit_message, :current_revision, :last_author)

  def initialize(last_commit_message, output, current_revision, last_author)
    @output = output

    @checkout = Checkout.new(last_commit_message, current_revision, last_author)
  end
end