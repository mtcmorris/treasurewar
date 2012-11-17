dep 'after deploy', :old_id, :new_id, :branch, :env do
  requires 'server restarted'
end

dep 'server restarted', :template => 'task' do
  run {
    output = shell?('ps ux | grep -v grep | grep "node .* server.coffee"')

    if output.nil?
      log "`coffee server.coffee` isn't running."
      true
    else
      pid = output.scan(/^\S+\s+(\d+)\s+/).flatten.first
      log_shell "Sending SIGTERM to #{pid}", "kill -s TERM #{pid}"
    end
  }
end
