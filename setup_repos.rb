#!/usr/bin/env ruby
require 'gitlab'

def client
  @client ||= Gitlab.client
end

def devops_group
  unless @devops_group
    begin
      @devops_group = client.create_group('devops', 'devops')
    rescue Gitlab::Error::BadRequest => e
      if e.response_status == 400
        @devops_group = client.group('devops')
      end
    end
  end
  @devops_group
end

def create_puppet_file(proj)
  begin
    client.create_file(proj.id, 'Puppetfile', 'master', puppetfile_content, 'init commit')
  rescue Gitlab::Error::BadRequest => e
    if e.response_status == 400
      # already created
    end
  end
end

def create_control_repo
  begin
    proj = client.create_project('control-repo', namespace_id: devops_group.id)
    client.create_branch(proj.id, 'dev')
    client.create_branch(proj.id, 'production')
    create_puppet_file(proj)
  rescue Gitlab::Error::BadRequest => e
    if e.response_status == 400
      # already created
      proj = client.project("devops%2Fcontrol-repo")
      create_puppet_file(proj)
    end
  end
end

def modules
  <<-EOF
  # Example42 v4.x modules (Used in various profiles)
  mod 'docker',
     :git => 'https://github.com/example42/puppet-docker'
  mod 'network',
     :git => 'https://github.com/example42/puppet-network'
  mod 'apache',
     :git    => 'https://github.com/example42/puppet-apache',
     :branch => '4.x'
  mod 'puppet',
     :git => 'https://github.com/example42/puppet-puppet',
     :branch => 'master'
  mod 'rails',
     :git => 'https://github.com/example42/puppet-rails'
  mod 'ansible',
     :git => 'https://github.com/example42/puppet-ansible'
  mod 'icinga',
     :git => 'https://github.com/example42/puppet-icinga',
     :branch => '4.x'

  EOF

end

def puppetfile_content
  @puppetfile_content ||= ''
end

def mod(name, *args)
  url = args.first[:git]
  begin
    proj = client.create_project(name, import_url: url, namespace_id: devops_group.id)
  rescue Gitlab::Error::BadRequest => e
    if e.response_status == 400
      proj = client.project("devops%2F#{name}")
    end
  end
  args.first[:git] = proj.ssh_url_to_repo
  data = args.first.sort.map { |k, v| ":#{k} => '#{v}'" }.join(",\n  ")
  puppetfile_content << "mod '#{name}',\n  #{data}\n\n"
end

eval(modules)
create_control_repo

client.create_user('joe@foo.org', 'password', 'joe', { name: 'Joe Smith' })

# add the ssh key
# create_ssh_key(title, key)
