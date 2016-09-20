module CapHelper
  def sanitize_roles(roles)
    # remove :db (for migrations), remove  :primary => :true (for assets precompile)
    roles.inject([]){|acc, role|
      if !role.is_a?(Hash)
        acc << role if role != :db
      else
        acc << role.reject{|k,v| k == :primary}
      end
      acc
    }
  end
end