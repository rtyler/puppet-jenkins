
require 'rubygems'
require 'json'

module Puppet
    newtype(:jenkins_slave) do
        @doc = "Ensure that the host is included as a slave on the server."
        newparam(:name) do
            desc "The name of the slave"
        end
        newparam(:num_exec) do
            desc "Number of executors"
            defaultto 2
            newvalues(/^[0-9]+$/)
        end
        newparam(:master) do
            desc "The name of the master that owns this slave"
        end
        newparam(:remote_fs) do
            desc "Remote filesystem to use"
            defaultto '/var/lib/jenkins'
        end
        newparam(:desc) do
            desc "Description of the node"
            defaultto 'Added by puppet'
        end
        newparam(:labels) do
            desc "Space separated list of the labels"
            defaultto ''
        end
        newparam(:url) do
            desc "Url to the jenkins server"
            defaultto 'http://localhost:8080'
        end
        newparam(:ui_user) do
            desc "HTTP user to use to connect to the master"
            defaultto ''
        end
        newparam(:ui_pass) do
            desc "HTTP pass to use to connect to the master"
            defaultto ''
        end
        newparam(:ssh_user) do
            desc "SSH user to use when installing from the master"
            defaultto ''
        end
        newparam(:ssh_pass) do
            desc "SSH password to use when installing from the master"
            defaultto ''
        end
        newparam(:ssh_key) do
            desc "SSH key to use when installing from the master"
            defaultto ''
        end

        newproperty(:ensure) do
            desc("Whether the slave is enabled, disabled or deleted from the master")
            newvalues(:enabled, :disabled, :deleted)
            defaultto :enabled
            def retrieve
                nodes = Facter['jenkins_nodes']
                if nodes != ''
                    nodes = Facter['jenkins_nodes'].value
                end
                if nodes and JSON.load(nodes).include? resource[:name]
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
        end
    end
end
