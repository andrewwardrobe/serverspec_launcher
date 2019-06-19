RSpec::Support.require_rspec_core "formatters/base_formatter"
require 'json'

class LauncherJsonFormatter < RSpec::Core::Formatters::BaseFormatter
  RSpec::Core::Formatters.register self, :message, :dump_summary, :dump_profile, :stop, :seed, :close,
                                   :example_group_started, :example_group_finished

  attr_reader :output_hash

  def initialize(output)
    super
    @output_hash = {
        :version => RSpec::Core::Version::STRING
    }
    @context = []
    @resource = ''
  end

  def message(notification)
    (@output_hash[:messages] ||= []) << notification.message
  end

  def dump_summary(summary)
    @output_hash[:summary] = {
        :duration => summary.duration,
        :example_count => summary.example_count,
        :failure_count => summary.failure_count,
        :pending_count => summary.pending_count,
        :errors_outside_of_examples_count => summary.errors_outside_of_examples_count
    }
    @output_hash[:summary_line] = summary.totals_line
  end

  def stop(notification)
    @output_hash[:examples] = notification.examples.map do |example|
      format_example(example).tap do |hash|
        e = example.exception
        if e
          hash[:exception] =  {
              :class => e.class.name,
              :message => e.message,
              :backtrace => e.backtrace,
          }
        end
      end
    end
  end

  def seed(notification)
    return unless notification.seed_used?
    @output_hash[:seed] = notification.seed
  end

  def close(_notification)
    output.write @output_hash.to_json
  end

  def dump_profile(profile)
    @output_hash[:profile] = {}
    dump_profile_slowest_examples(profile)
    dump_profile_slowest_example_groups(profile)
  end

  def example_group_started(example_group)
    @context.push "#{example_group.group.description}"
    @resource = "#{example_group.group.description}"
  end

  def example_group_finished(example_group)

  end

  # @api private
  def dump_profile_slowest_examples(profile)
    @output_hash[:profile] = {}
    @output_hash[:profile][:examples] = profile.slowest_examples.map do |example|
      format_example(example).tap do |hash|
        hash[:run_time] = example.execution_result.run_time
      end
    end
    @output_hash[:profile][:slowest] = profile.slow_duration
    @output_hash[:profile][:total] = profile.duration
  end

  # @api private
  def dump_profile_slowest_example_groups(profile)
    @output_hash[:profile] ||= {}
    @output_hash[:profile][:groups] = profile.slowest_groups.map do |loc, hash|
      hash.update(:location => loc)
    end
  end

  private

  def format_example(example)
    {
        :id => example.id,
        :description => example.description,
        :full_description => example.full_description,
        :status => example.execution_result.status.to_s,
        :file_path => example.metadata[:file_path],
        :line_number  => example.metadata[:line_number],
        :run_time => example.execution_result.run_time,
        :pending_message => example.execution_result.pending_message,
        :resource => example.example_group.description,
        :context => get_tree(example),
        :metadata => example.metadata,
        :tags => example.metadata[:tags],
        :type => example.metadata[:type]
    }
  end

  def get_tree(example)
    example.example_group.ancestors.select do |o|
      /RSpec::ExampleGroups/.match?(o.to_s) && o.respond_to?(:description)
    end.map do |object|
      object.description
    end.reverse
  end

end
