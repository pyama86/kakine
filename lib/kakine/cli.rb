require 'thor'
require 'fog'

module Kakine
  class CLI < Thor
    option :tenant, type: :string, aliases: '-t'
    desc 'show', 'show Security Groups specified tenant'
    def show
      security_groups_on_tenant(option[:tenant]).each do |sg|
        puts format_security_group(sg).to_yaml
      end
    end

    option :tenant, type: :string, aliases: "-t"
    option :dryrun, type: :boolean, aliases: "-d"
    desc 'apply', "apply local configuration into OpenStack"
    def apply

    end

    private

    def security_groups_on_tenant(tenant_name)
      security_groups = Fog::Network[:openstack].security_groups

      tenants = Fog::Identity[:openstack].tenants
      tenant = tenants.detect{|t| t.name == tenant_name}

      security_groups.select{|sg| sg.tenant_id == tenant.id}
    end

    def format_security_group(security_group)
      sg_hash = {}

      sg_hash[security_group.name] = []

      security_group.security_group_rules.each do |rule|
        rule_hash = {}

        rule_hash["direction"] = rule.direction
        rule_hash["protocol"] = rule.protocol

        if rule.port_range_max == rule.port_range_min
          rule_hash["port"] = rule.port_range_max
        else
          rule_hash["port_range_max"] = rule.port_range_max
          rule_hash["port_range_min"] = rule.port_range_min
        end

        if rule.remote_group_id
          response = Fog::Network[:openstack].get_security_group(rule.remote_group_id)
          rule_hash["remote_group"] = response.data[:body]["security_group"]["name"]
        else
          rule_hash["remote_ip"] = rule.remote_ip_prefix
        end

        sg_hash[security_group.name] << rule_hash
      end

      sg_hash
    end
  end
end
