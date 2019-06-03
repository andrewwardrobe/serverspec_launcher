module PropertiesHelper

  def default_targets
    {
        'ssh-example' => {
            backend: 'ssh',
            variables: { leek: 'bleek'}
        },
        'exec-example' => {
            backend: 'exec'
        },
        'vagrant-example' => {
            backend: 'vagrant'
        },
        'docker-image-example' => {
            backend: 'docker',
            docker_image: 'jenkins'
        }

    }
  end

  def default_properties
    {
        targets: default_targets,
        variables: {leek: 'sheek'},
        environments: {
            'test' => {
                targets: {
                    target1: {
                        backend: 'exec',
                        variables: {leek: 'meek'}
                    },
                    target2: {
                        backend: 'exec'
                    }
                },
                variables: {leek: 'treek'}
            }
        }
    }
  end

  def default_properties_yaml
    <<~HEREDOC
    ---  
    targets:
      target1:
        backend: exec
        variables: 
          leek: meek
    variables: 
      var1: $VAR1
      var2: ${VAR2}
      var3: \$VAR3

      

    HEREDOC
  end

  def same_target_names
    {
        targets: default_targets,
        variables: {leek: 'sheek'},
        environments: {
            'test' => {
                targets: {
                    'exec-example': {
                        backend: 'exec',
                        variables: {leek: 'meek'}
                    },
                    target2: {
                        backend: 'exec'
                    }
                },
                variables: {leek: 'treek'}
            }
        }
    }
  end
end