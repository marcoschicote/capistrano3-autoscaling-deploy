module CapHelper
  # Role names can be given as strings (e.g. %w{web app db}); compare them as symbols
  def symbolize_roles(roles)
    roles.map { |role| role.is_a?(String) ? role.to_sym : role }
  end

  def sanitize_roles(roles)
    # remove :db (for migrations), remove  :primary => :true (for assets precompile)
    symbolize_roles(roles).inject([]){|acc, role|
      if !role.is_a?(Hash)
        acc << role if role != :db
      else
        acc << role.reject{|k,v| k == :primary}
      end
      acc
    }
  end
end