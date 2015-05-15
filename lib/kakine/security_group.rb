module Kakine
  class SecurityGroup
    attr_accessor :name, :div, :description, :tenant_id, :tenant_name, :rules
    def initialize(tenant_name, diff)
      @diff            = diff
      @name            = diff[1].split(/[\.\[]/, 2)[0]
      @div             = diff[0]
      @tenant_name     = tenant_name
      @tenant_id       = Kakine::Resource.tenant(tenant_name).id
      @rules           = []
      entry            = Kakine::Resource.security_groups_hash(@tenant_name)

      if ["+", "-"].include?(@div)
        # ["+", "sg_name", {"rules"=>[{"direction"=>"egress" ~ }]}] 
        unless diff[2]["rules"].nil?
          @description  = diff[2]["description"]
          @rules        = diff[2]["rules"]
        # ["-", "sg_namerules[0]", {"direction"=>"egress" ~ }]
        else
          @description = entry[@name]["description"]
          @rules      << diff[2]
        end
      else
        # ["~", "sg_name.description", "before_value", "after_value"]
        if m = diff[1].match(/^([\w-]+)\.([\w]+)$/)
          @discription = diff[3]
          @rules       = entry[@name]["rules"]
        # ["~", "sg_name.rules[0].port", before_value, after_value]
        elsif m = diff[1].match(/^([\w-]+).([\w]+)\[(\d)\].([\w]+)$/)
          @description    = entry[@name]["description"]
          @rules         << entry[@name]["rules"][m[3].to_i]
          @rules[0][m[4]] = diff[3]
        else
          raise
        end
      end
      set_remote_security_group_id
    end

    def set_remote_security_group_id
      self.rules.each do |rule|
        unless rule['remote_group'].nil?
          remote_security_group = Kakine::Resource.security_group(self.tenant_name, rule.delete("remote_group"))
          rule["remote_group_id"] = remote_security_group.id
        end
      end if has_rules?
    end

    def has_rules?
      self.rules.detect {|v| v.size > 0}
    end

    def is_add?
      self.div == "+"
    end

    def is_delete?
      self.div == "-"
    end

    def is_modify?
      !@diff[1].split(/[\.\[]/, 2)[1].nil?
    end
  end
end