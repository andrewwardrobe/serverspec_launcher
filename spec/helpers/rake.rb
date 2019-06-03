# frozen_string_literal: true
module RakeHelpers
  def rake_tasks
    Rake.application.tasks.map(&:to_s)
  end
end
