module BX
  module TmuxWrapper
    # Session management
    def self.create_session(name)
      return false if session_exists?(name)
      system("tmux new-session -d -s #{shell_escape(name)}")
      $?.success?
    end

    def self.kill_session(name)
      return false unless session_exists?(name)
      system("tmux kill-session -t #{shell_escape(name)}")
      $?.success?
    end

    def self.session_exists?(name)
      system("tmux has-session -t #{shell_escape(name)} 2>/dev/null")
      $?.success?
    end

    def self.list_sessions
      output = `tmux list-sessions -F '#{session_name}' 2>/dev/null`
      return [] unless $?.success?
      output.split("\n").map(&:strip)
    end

    # Window management
    def self.create_window(session, window_name, command, env = {})
      target = "#{session}:#{window_name}"

      # Create window
      system("tmux new-window -t #{shell_escape(session)} -n #{shell_escape(window_name)}")
      return nil unless $?.success?

      # Set environment variables
      env.each do |key, value|
        system("tmux setenv -t #{shell_escape(target)} #{shell_escape(key)} #{shell_escape(value)}")
      end

      # Send command
      system("tmux send-keys -t #{shell_escape(target)} #{shell_escape(command)} C-m")
      return nil unless $?.success?

      # Get PID of the running process
      pid_output = `tmux display-message -t #{shell_escape(target)} -p '#{pane_pid}' 2>/dev/null`.strip
      pid_output.to_i if $?.success? && !pid_output.empty?
    end

    def self.send_keys(target, keys)
      system("tmux send-keys -t #{shell_escape(target)} #{shell_escape(keys)}")
      $?.success?
    end

    def self.attach_session(name)
      exec("tmux attach-session -t #{shell_escape(name)}")
    end

    # Window queries
    def self.list_windows(session)
      output = `tmux list-windows -t #{shell_escape(session)} -F '#{window_name}' 2>/dev/null`
      return [] unless $?.success?
      output.split("\n").map(&:strip)
    end

    def self.window_exists?(session, window)
      target = "#{session}:#{window}"
      system("tmux list-windows -t #{shell_escape(session)} 2>/dev/null | grep -q '^#{window}:'")
      $?.success?
    end

    # Pane management
    def self.capture_pane(target, lines = 100)
      output = `tmux capture-pane -t #{shell_escape(target)} -p -S -#{lines} 2>/dev/null`
      $?.success? ? output : nil
    end

    def self.get_pane_pid(target)
      pid_output = `tmux display-message -t #{shell_escape(target)} -p '#{pane_pid}' 2>/dev/null`.strip
      pid_output.to_i if $?.success? && !pid_output.empty?
    end

    # Hooks
    def self.set_hook(target, hook_name, command)
      system("tmux set-hook -t #{shell_escape(target)} #{hook_name} #{shell_escape(command)}")
      $?.success?
    end

    # Utility methods
    private

    def self.shell_escape(str)
      "'#{str.to_s.gsub("'", "'\\\\''")}'"
    end
  end
end
