module ApplicationHelper
=begin
  def title(value = nil)
    @title = value if value
    @title ? "surfacelab | #{@title}" : "surfacelab"
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
=end
  
  def write_unprotect(ro_root,directories)
    system("mount -o remount,rw #{ro_root}")
    directories.each do |dir|
      system("mount --bind #{ro_root}#{dir} #{dir}")
    end
    
    yield
    system("sync")
    directories.each do |dir|
      system("umount #{dir}")
    end
    system("mount -o remount,ro #{ro_root}")
  end
end