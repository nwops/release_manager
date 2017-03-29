class WorkflowAction
  def self.check_requirements
    raise NotImplementedError
  end
end