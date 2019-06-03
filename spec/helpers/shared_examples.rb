# frozen_string_literal: true
module SharedExamplesHelper
  def shared_example(name)
    <<~HEREDOC
      shared_examples '#{name}' do
        describe file('/etc/hosts') do
          it { should exist }
        end
      end
    HEREDOC
  end

  def create_shared_example(name)
    se = shared_example(name)

    dir = Dir.mktmpdir
    Dir.mkdir "#{dir}/shared"
    File.open("#{dir}/shared/example.rb", 'w') do |f|
      f.write se
    end
    dir
  end
end
