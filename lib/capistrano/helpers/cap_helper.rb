module CapHelper
  # Role names can be given as strings (e.g. %w{web app db}); compare them as symbols
  def symbolize_roles(roles)
    roles.map { |role| role.is_a?(String) ? role.to_sym : role }
  end

  # Roles for every instance but the first: no :db (for migrations) and
  # no primary: true (for assets precompile)
  def sanitize_roles(roles)
    symbolize_roles(roles).filter_map do |role|
      if role.is_a?(Hash)
        role.except(:primary)
      elsif role != :db
        role
      end
    end
  end
end
