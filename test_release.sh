puts `rm -rf ~/repos`
puts `bundle exec sandbox-create -n box12323 -m apache`
bundle exec release-mod -m ~/repos/apache/`