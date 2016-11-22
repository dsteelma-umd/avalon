# Copyright 2011-2015, The Trustees of Indiana University and Northwestern
#   University.  Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
#   under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
#   CONDITIONS OF ANY KIND, either express or implied. See the License for the
#   specific language governing permissions and limitations under the License.
# ---  END LICENSE_HEADER BLOCK  ---
require 'rails_helper'

describe 'MediaObject' do
  after { Warden.test_reset! }
  let(:media_object) { FactoryGirl.build(:media_object).tap {|mo| mo.workflow.last_completed_step = "resource-description"} }
  before :all do
    user = FactoryGirl.create(:administrator)
    login_as user, scope: :user
  end
  it 'can visit a media object' do
    media_object.save
    url = media_object_url(media_object)
    visit url
    expect(page.status_code). to eq(200)
  end
end
