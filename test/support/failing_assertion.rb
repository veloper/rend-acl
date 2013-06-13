class FailingAssertion < Rend::Acl::Assertion

  def pass?(acl, role = nil, resource = nil, privilege = nil)
    false
  end

end
