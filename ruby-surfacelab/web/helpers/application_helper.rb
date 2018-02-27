module ApplicationHelper

  def title(value = nil)
    @title = value if value
    @title ? "electrobot | #{@title}" : "electrobot"
  end

  def login?
    if session[:username].nil?
      return false
    else
      return true
    end
  end
  
  def username
    return session[:username]
  end
end