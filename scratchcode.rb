if remote
  raise NotImplemented
  diff_obj = control_repo.create_diff_obj(src_ref, dest_ref)
  actions = diff_2_commit(diff_obj)
  vcs_create_branch(url, branch_name, dest_ref)
  control_repo.commit(message, diff_obj, branch_name, remote)
  #rebase_mr(url, mr.id)
  #commit = vcs_create_commit(control_repo.url, branch_name, message, actions)
else

  opts.on('-r', '--remote-deploy', "Perform a remote deploy (For CI systems)") do |c|
    options[:remote] = c
  end