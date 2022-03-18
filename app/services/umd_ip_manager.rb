# frozen_string_literal: true

class UmdIPManager
  GROUP_PREFIX = 'umd.ip.manager:'

  def groups
    groups = retrieve_groups
    GroupsResult.new(groups: groups)
  rescue StandardError => e
    GroupsResult.new(errors: [e.message])
  end

  def check_ip(group_base_key:, ip_address:)
    raise ArgumentError, "invalid argument: group_base_key='#{group_base_key}'" unless group_base_key.present?
    raise ArgumentError, "invalid argument: ip_address='#{ip_address}'" unless ip_address.present?

    begin
      ip_is_member = do_check_ip(group_base_key: group_base_key, ip_address: ip_address)
      CheckIPResult.new(ip_is_member: ip_is_member)
    rescue StandardError => e
      CheckIPResult.new(errors: [e.message])
    end
  end

  def retrieve_groups
    # TODO - returns an array of UmdIPManager::Group, or raises an exception
  end

  def do_check_ip(group_base_key:, ip_address:)
    # TODO - returns true, if the given IP Address is in the given group,
    # false otherwise. Raise an exception if an error occurs
  end

  class Group
    PREFIX = UmdIPManager::GROUP_PREFIX

    attr_reader :base_key, :prefixed_key, :name

    def initialize(base_key:, name:)
      raise ArgumentError, "invalid argument: base_key='#{base_key}'" unless base_key.present?
      raise ArgumentError, "invalid argument: name='#{name}'" unless name.present?
      @base_key = base_key
      @name = name
      @prefixed_key = Group.as_prefixed_key(base_key)
    end

    def self.as_prefixed_key(base_key)
      raise ArgumentError, "invalid argument: base_key='#{base_key}'" unless base_key.present?
      "#{PREFIX}#{base_key}"
    end

    def self.as_base_key(prefixed_key)
      raise ArgumentError, 'prefixed_key does not start with expected prefix' unless prefixed_key&.starts_with?(PREFIX)
      prefixed_key.delete_prefix(PREFIX)
    end
  end

  class GroupsResult
    attr_reader :groups, :errors

    def initialize(groups: [], errors: [])
      @groups = groups
      @errors = errors
    end

    def success?
      @errors.empty?
    end
  end

  class CheckIPResult
    attr_reader :errors

    def initialize(ip_is_member: false, errors: [])
      @ip_is_member = ip_is_member
      @errors = errors
    end

    def ip_is_member?
      @ip_is_member
    end

    def success?
      @errors.empty?
    end
  end
end
