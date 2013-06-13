class PassingAssertion < Rend::Acl::Assertion

  def pass?(acl, role = nil, resource = nil, privilege = nil)
    true
  end

end
