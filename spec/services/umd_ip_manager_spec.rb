require 'rails_helper'

describe UmdIPManager do
  let(:ip_manager) { described_class.new }

  context '#groups' do
    it 'returns a GroupsResult with a list of UmdIPManager::Groups on success' do
      test_group = UmdIPManager::Group.new(base_key: 'test-group', name: 'Test Group')
      allow(ip_manager).to receive(:retrieve_groups) {
        [test_group]
      }

      groups_result = ip_manager.groups

      expect(groups_result.success?).to be(true)
      expect(groups_result.groups).to contain_exactly(test_group)
    end

    it 'returns a GroupsResult with errors on failure' do
      allow(ip_manager).to receive(:retrieve_groups) { raise StandardError, "An error occurred" }

      groups_result = ip_manager.groups
      expect(groups_result.success?).to be(false)
    end
  end

  context '#check_ip' do
    it 'raises an ArgumentError when given invalid parameters' do
      expect { ip_manager.check_ip }.to raise_error(ArgumentError)
      expect { ip_manager.check_ip(group_base_key: '') }.to raise_error(ArgumentError)
      expect { ip_manager.check_ip(ip_address: '') }.to raise_error(ArgumentError)
      expect { ip_manager.check_ip(group_base_key: '', ip_address: '') }.to raise_error(ArgumentError)
    end

    it 'returns a successful CheckIPResult indicating whether an IP is a member when no errors occur' do
      allow(ip_manager).to receive(:do_check_ip).with(group_base_key: 'test_localhost', ip_address: '127.0.0.1').and_return(true)
      allow(ip_manager).to receive(:do_check_ip).with(group_base_key: 'test_localhost', ip_address: '192.168.1.105').and_return(false)

      check_ip_result = ip_manager.check_ip(group_base_key: 'test_localhost', ip_address: '127.0.0.1')
      expect(check_ip_result.success?).to be(true)
      expect(check_ip_result.ip_is_member?).to be(true)

      check_ip_result = ip_manager.check_ip(group_base_key: 'test_localhost', ip_address: '192.168.1.105')
      expect(check_ip_result.success?).to be(true)
      expect(check_ip_result.ip_is_member?).to be(false)
    end

    it 'returns a CheckIPResult with errors on failure' do
      allow(ip_manager).to receive(:do_check_ip) { raise StandardError, "An error occurred" }

      check_ip_result = ip_manager.check_ip(group_base_key: 'test_localhost', ip_address: '127.0.0.1')
      expect(check_ip_result.success?).to be(false)
      expect(check_ip_result.ip_is_member?).to be(false)
      expect(check_ip_result.errors.length).to eq(1)
    end
  end
end

describe UmdIPManager::CheckIPResult do
  context '#success?' do
    it 'returns true when there are no errors' do
      check_ip_result = described_class.new
      expect(check_ip_result.success?).to be(true)
      expect(check_ip_result.errors.length).to eq(0)
    end

    it 'returns false when there are errors' do
      check_ip_result = described_class.new(errors: ['An error occurred!'])
      expect(check_ip_result.success?).to be(false)
      expect(check_ip_result.errors.length).to eq(1)
    end
  end

  it 'returns true when an IP Address is a member of the group' do
    check_ip_result = described_class.new(ip_is_member: true)
    expect(check_ip_result.ip_is_member?).to be(true)
  end

  it 'returns false when an IP Address is not a member of the group' do
    check_ip_result = described_class.new(ip_is_member: false)
    expect(check_ip_result.ip_is_member?).to be(false)
  end
end

describe UmdIPManager::GroupsResult do
  context '#success?' do
    it 'returns true when there are no errors' do
      groups_result = described_class.new
      expect(groups_result.success?).to be(true)
      expect(groups_result.errors.length).to eq(0)
    end

    it 'returns false when there are errors' do
      groups_result = described_class.new(errors: ['An error occurred!'])
      expect(groups_result.success?).to be(false)
      expect(groups_result.errors.length).to eq(1)
    end
  end

  it 'returns a list of provided groups' do
    group1 = UmdIPManager::Group.new(base_key: 'group-1', name: 'Group 1')
    group2 = UmdIPManager::Group.new(base_key: 'group-2', name: 'Group 2')
    groups = [group1, group2]

    groups_result = described_class.new(groups: groups)
    expect(groups_result.groups).to contain_exactly(group1, group2)
  end

  it 'may return an empty list of groups' do
    groups_result = described_class.new
    expect(groups_result.groups).to be_empty
    expect(groups_result.success?).to be(true)
  end
end

describe UmdIPManager::Group do
  EXPECTED_PREFIX = 'umd.ip.manager:'

  it 'provides the base_key for a group' do
    group = described_class.new(base_key: 'test-base-key', name: 'Test')
    expect(group.base_key).to eq('test-base-key')
  end

  it 'provides the prefixed_key for a group' do
    group = described_class.new(base_key: 'test-base-key', name: 'Test')
    expect(group.prefixed_key).to eq("#{EXPECTED_PREFIX}test-base-key")
  end

  it 'provides the name of the group' do
    group = described_class.new(base_key: 'test-base-key', name: 'Test')
    expect(group.name).to eq('Test')
  end

  context '#initialize' do
    it 'raises an ArgumentError when given invalid parameters' do
      expect { described_class.new }.to raise_error(ArgumentError)
      expect { described_class.new(name: '') }.to raise_error(ArgumentError)
      expect { described_class.new(base_key: '') }.to raise_error(ArgumentError)
      expect { described_class.new(base_key: '', name: '') }.to raise_error(ArgumentError)
      expect { described_class.new(base_key: 'foo', name: '') }.to raise_error(ArgumentError)
      expect { described_class.new(base_key: '', name: 'Foo') }.to raise_error(ArgumentError)
    end

    it 'is properly constructed when given valid parameters' do
      group = described_class.new(base_key: 'test-base-key', name: 'Test')
      expect(group.base_key).to eq('test-base-key')
      expect(group.name).to eq('Test')
      expect(group.prefixed_key).to eq("#{EXPECTED_PREFIX}test-base-key")
    end
  end

  context '.as_prefixed_key' do
    context 'raises an ArgumentError' do
      it 'when given a nil base_key' do
        expect { described_class.as_prefixed_key(nil) }.to raise_error(ArgumentError)
      end

      it 'when given an empty base_key' do
        expect { described_class.as_prefixed_key('') }.to raise_error(ArgumentError)
      end

      it 'when given an base_key of only whitespace' do
        expect { described_class.as_prefixed_key("  \t  ") }.to raise_error(ArgumentError)
      end
    end

    it 'returns the given base_key prefixed with UmdIPManager::Group.PREFIX' do
      expect(described_class.as_prefixed_key('foo')).to eq("#{EXPECTED_PREFIX}foo")
    end
  end

  context '.as_base_key' do
    context 'raises an ArgumentError' do
      it 'when given a nil prefixed_key' do
        expect { described_class.as_base_key(nil) }.to raise_error(ArgumentError)
      end

      it 'when given an empty prefixed_key' do
        expect { described_class.as_base_key('') }.to raise_error(ArgumentError)
      end

      it 'when given a prefixed_key of only whitespace' do
        expect { described_class.as_base_key("  \t  ") }.to raise_error(ArgumentError)
      end

      it 'when given a prefixed_key without the expected prefix' do
        expect { described_class.as_base_key("UNEXPECTED_PREFIX") }.to raise_error(ArgumentError)
      end
    end

    it 'returns the given prefixed_key without the UmdIPManager::Group.PREFIX' do
      expect(described_class.as_base_key("#{EXPECTED_PREFIX}foo")).to eq('foo')
    end
  end

  context '.valid_prefixed_key?' do
    context 'return false' do
      it 'when given a nil prefixed_key' do
        expect(described_class.valid_prefixed_key?(nil)).to be(false)
      end

      it 'when given an empty prefixed_key' do
        expect(described_class.valid_prefixed_key?('')).to be(false)
      end

      it 'when given a prefixed_key without the expected prefix' do
        expect(described_class.valid_prefixed_key?("UNEXPECTED_PREFIX:test")).to be(false)
      end
    end

    it 'returns true when given prefixed_key with the expected prefix' do
      expect(described_class.valid_prefixed_key?("#{EXPECTED_PREFIX}foo")).to be(true)
    end
  end
end
