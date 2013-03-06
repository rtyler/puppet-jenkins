require 'facter'
require 'rubygems'
require 'json'
require 'rexml/document'
require 'uri'
require 'net/http'

#using the xml file avoids the need to authenticate, a failover
$conf_path = '/var/lib/jenkins/config.xml'

#try to get the slaves stats, needs anonymous read permission
$url = URI.parse('http://localhost:8080/computer/api/json')


def add_facts()
    nodes = []
    begin
        ##try first through the web interface to get themost updated/complete info
        http = Net::HTTP.new($url.host, $url.port)
        req = Net::HTTP::Get.new($url.request_uri)
        resp = http.request(req)
        if resp.code.to_i >= 400
            raise 'Unauthorized'
        end
        nodes_list = JSON.load(resp.body)["computer"]
        nodes_list.each {|node|
            name = node['displayName']
            nodes += [name]
            node.each { |prop, pval|
                begin
                    pval = JSON.generate(pval)
                rescue
                end
                Facter.add("jenkins_#{name}_#{prop}") { setcode { pval } }
            }
        }
    rescue
        ## if unable, try the config file
        config = File.read($conf_path)
        xml = REXML::Document.new(config)
        xml.elements.each('hudson/slaves/slave') { |node|
            name = node.elements['name'].text
            %w[numExecutors remoteFS description].each { |prop|
                begin
                    pval = JSON.generate(node.elements[prop].text)
                rescue
                    pval = node.elements[prop].text
                end
                Facter.add("jenkins_#{name}_#{prop}") { setcode { pval } }
            }
            nodes += [name]
        }
    end
    return nodes
end

begin
    begin
        nodes = add_facts()
        Facter.add("jenkins_nodes") { setcode { JSON.generate(nodes) } }
    rescue
        Facter.debug("Unable to load nodes.")
    end
    begin
        key = File.read(File.expand_path('~jenkins/.ssh/id_rsa.pub'))
        Facter.add("jenkins_master_sshkey") { setcode { key.chomp } }
    rescue
        Facter.debug("Unable to load jenkins ssh key.")
    end
rescue
end
