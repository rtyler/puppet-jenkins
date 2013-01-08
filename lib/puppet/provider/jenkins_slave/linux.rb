
require 'rubygems'
require 'json'
require "uri"
require "net/http"
require "net/https"


## this is an ugly post that has to be made to the jenkins master to create a new node, because the cli tool does not allow it.
def create_node(name,
                num_exec  = '2',
                remote_fs = '/var/lib/jenkins',
                desc      = '' ,
                labelstr  = '',
                url       = 'http://localhost:8080',
                ui_user   = '',
                ui_pass   = '',
                ssh_user  = '',
                ssh_pass  = '',
                ssh_key   = '')
    params = {
       'Submit'            =>'Save',
       '_.command'         => '',
       '_.host'            => "#{name}",
       '_.javaPath'        => '',
       '_.jvmOptions'      => '',
       '_.labelString'     => '',
       '_.nodeDescription' => '',
       '_.numExecutors'    => '2',
       '_.password'        => "#{ssh_pass}",
       '_.port'            => '22',
       '_.prefixStartSlaveCmd' => '',
       '_.privatekey'      => "#{ssh_key}",
       '_.remoteFS'        => "#{remote_fs}",
       '_.suffixStartSlaveCmd' => '',
       '_.tunnel'          => '',
       '_.username'        => "#{ssh_user}",
       '_.vmargs'          => '',
       'json'              => "{\"name\": \"#{name}\", \"nodeDescription\": \"#{desc}\", \"numExecutors\": \"#{num_exec}\", \"remoteFS\": \"#{remote_fs}\", \"labelString\": \"#{labelstr}\", \"mode\": \"NORMAL\", \"\": [\"hudson.plugins.sshslaves.SSHLauncher\", \"hudson.slaves.RetentionStrategy$Always\"], \"launcher\": {\"stapler-class\": \"hudson.plugins.sshslaves.SSHLauncher\", \"host\": \"#{name}\", \"username\": \"#{ssh_user}\", \"password\": \"#{ssh_pass}\", \"privatekey\": \"#{ssh_key}\", \"port\": \"22\", \"javaPath\": \"\", \"jvmOptions\": \"\", \"prefixStartSlaveCmd\": \"\", \"suffixStartSlaveCmd\": \"\"}, \"retentionStrategy\": {\"stapler-class\": \"hudson.slaves.RetentionStrategy$Always\"}, \"nodeProperties\": {\"stapler-class-bag\": \"true\"}, \"type\": \"hudson.slaves.DumbSlave\"}",
       'mode'              => 'NORMAL',
       'name'              => "#{name}",
       'retentionStrategy.idleDelay' => '',
       'retentionStrategy.inDemandDelay' => '',
       'retentionStrategy.keepUpWhenActive' => 'on',
       'retentionStrategy.startTimeSpec' => '',
       'retentionStrategy.upTimeMins' => '',
       'stapler-class'     => 'hudson.plugins.sshslaves.SSHLauncher',
       'stapler-class'     => 'hudson.slaves.JNLPLauncher',
       'stapler-class'     => 'hudson.slaves.CommandLauncher',
       'stapler-class'     => 'hudson.os.windows.ManagedWindowsServiceLauncher',
       'stapler-class'     => 'hudson.os.windows.ManagedWindowsServiceAccount$LocalSystem',
       'stapler-class'     => 'hudson.os.windows.ManagedWindowsServiceAccount$AnotherUser',
       'stapler-class'     => 'hudson.os.windows.ManagedWindowsServiceAccount$Administrator',
       'stapler-class'     => 'hudson.slaves.RetentionStrategy$Always',
       'stapler-class'     => 'hudson.slaves.SimpleScheduledRetentionStrategy',
       'stapler-class'     => 'hudson.slaves.RetentionStrategy$Demand',
       'stapler-class-bag' => 'true',
       'type'              => 'hudson.slaves.DumbSlave',
    }
    proto, _,  _, host, port = url.split(/[\/:]/)
    http = Net::HTTP::Post.new("#{url}/computer/doCreateItem")
    if proto == 'https'
        http.use_ssl = true
    end
    if ui_user != ''
        http.basic_auth(ui_user, ui_pass)
    end
    http.set_form_data(params)
    sock = Net::HTTP.new(host, port)
    resp = sock.start {|o| o.request(http) }
    return resp.code.to_i < 400
end


def delete_node(name, ui_user='', ui_pass='', url='http://localhost:8080')
    params = {
       'Submit' =>'yes',
       'json' => '{}'
    }
    proto, _,  _, host, port = url.split(/[\/:]/)
    http = Net::HTTP::Post.new("#{url}/computer/#{name}/doDelete")
    if proto == 'https'
        http.use_ssl = true
    end
    if ui_user != ''
        http.basic_auth(ui_user, ui_pass)
    end
    http.set_form_data(params)
    sock = Net::HTTP.new(host, port)
    resp = sock.start {|o| o.request(http) }
    return resp.code.to_i < 400
end


def get_nodes
        nodes = Facter['jenkins_nodes']
        if nodes != ''
            begin
                return JSON.load(Facter['jenkins_nodes'].value)
            rescue
            end
        end
        return []
end

Puppet::Type.type(:jenkins_slave).provide(:linux) do
    commands :java => 'java'
    $java_args = ['-jar', '/var/cache/jenkins/war/WEB-INF/jenkins-cli.jar', '-s']

    def ensurea
        nodes = get_nodes
        if nodes.include? resource[:name]
            offline = Facter["jenkins_#{resource[:name]}_offline"]
            if offline != nil
                offline = offline.value
                if not offline
                    :enabled
                else
                    :disabled
                end
            else
            #if offline  == nil means that we did not have acces
                #to the web ui, assume disabled
                :disabled
            end
        else
            :deleted
        end
    end

    def ensurea=(value)
        $java_args += [resource[:url]]
        if resource[:ui_user] != ''
            $auth = ['--username', resource[:ui_user], '--password', resource[:ui_pass]]
        else
            $auth = []
        end
        case value
        when :enabled
            enable
        when :disabled
            disable
        when :deleted
            delete
        end
    end

    def enable
        nodes = get_nodes()
        if not nodes.include? resource[:name]
            debug('  Creating new node')
            if not create_node(resource[:name],
                               resource[:num_exec],
                               resource[:remote_fs],
                               resource[:desc],
                               resource[:labels],
                               resource[:url],
                               resource[:ui_user],
                               resource[:ui_pass],
                               resource[:ssh_user],
                               resource[:ssh_pass],
                               resource[:ssh_key])
                fail("Failed to create node #{resource[:name]} on #{resource[:master]}")
            end
        end
        debug('  Connecting master to the node')
        java(*get_java_args('connect-node'))
        debug('  Enabling the node')
        java(*get_java_args('online-node'))
    end

    def disable
        debug('  Disabling the node')
        nodes = get_nodes
        if not nodes.include? resource[:name]
            if not create_node(resource[:name],
                               resource[:num_exec],
                               resource[:remote_fs],
                               resource[:desc],
                               resource[:labels],
                               resource[:url],
                               resource[:ui_user],
                               resource[:ui_pass],
                               resource[:ssh_user],
                               resource[:ssh_pass],
                               resource[:ssh_key])
                fail("Failed to create node #{resource[:name]} on #{resource[:master]}")
            end
            java(*get_java_args('connect-node'))
        end
        java(*get_java_args('offline-node'))
    end

    def delete
        debug('  Deleting')
        if not delete_node(resource[:name], resource[:ui_user], resource[:ui_pass], resource[:url])
            fail("Failed to delete node #{resource[:name]} on #{resource[:master]}")
        end
    end

    def get_java_args(command)
        ## for some reason it does not allow the [*array, elem] construction, only [elem, *array]
        return $java_args + [command, *$auth] + [resource[:name]]
    end

end

