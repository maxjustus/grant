module Grant
  module User
    def current_user
      Thread.current[@@current_user_symbol]
    end

    def current_user=(user)
      Thread.current[@@current_user_symbol] = user
    end
    
    module_function :current_user, :current_user=

    private
    @@current_user_symbol = :grant_current_user_symbol
  end
end