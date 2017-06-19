#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

require_relative '../common'
require_relative '../helpers/blueprint_common'

describe "master courses - course picker" do
  include_context "in-process server selenium tests"
  include BlueprintCourseCommon

  before :once do
    # create the master course
    Account.default.enable_feature!(:master_courses)
    @master = course_factory(active_all: true)
    @template = MasterCourses::MasterTemplate.set_as_master_course(@master)

    # create some courses
    c = Course.create!(
      :account => @account, :name => "AlphaDog", :course_code => "CCC1", :sis_source_id => "SIS_A1"
    )
    c.offer!
    c = Course.create!(
      :account => @account, :name => "AlphaMale", :course_code => "CCC2", :sis_source_id => "SIS_A2"
    )
    c.offer!
    c = Course.create!(
      :account => @account, :name => "Alphabet", :course_code => "CCC3", :sis_source_id => "SIS_A3"
    )
    c.offer!
    c = Course.create!(
      :account => @account, :name => "BetaCarotine", :course_code => "DDD4", :sis_source_id => "SIS_B4"
    )
    c.offer!
    c = Course.create!(
      :account => @account, :name => "BetaGetOuttaHere", :course_code => "DDD5", :sis_source_id => "SIS_B5"
    )
    c.offer!
    account_admin_user(active_all: true)
  end

  before :each do
    user_session(@admin)
  end

  let(:course_search_input) {'.bca-course-filter input[type="search"]'}
  let(:filter_output) {'.bca-course-details__wrapper'}
  let(:loading) {'.bca-course-picker__loading'}

  # enter search term into the filter text box and wait for the response
  # this is complicated b the fact that the search api query doesn't happen until
  # after the user enters at least 3 chars and stops typing for 200ms,
  # then we have to wait for the api response
  def test_filter(search_term)
    get "/courses/#{@master.id}"
    open_associations
    open_courses_list
    filter = f(course_search_input)
    filter.click
    filter.send_keys(search_term)                         # type into the filter text box
    expect(f(filter_output)).to contain_css(loading)      # the loading spinner appears
    expect(f(filter_output)).not_to contain_css(loading)  # and disappears
    available_courses
  end

  it "should show all courses by default", priority: "1", test_id: "3072438" do
    get "/courses/#{@master.id}"
    open_associations
    open_courses_list
    expect(available_courses_table).to be_displayed
    expect(available_courses().length).to eq(5)
  end

  it "should filter the course list by name", priority: "1", test_id: "3072438" do
    matches = test_filter('Alpha')
    expect(matches.length).to eq(3)
  end

  it "should filter the course list by short name", priority: "1", test_id: "3072438" do
    matches = test_filter('CCC')
    expect(matches.length).to eq(3)
  end

  it "should filter the course list by SIS ID", priority: "1", test_id: "3072438" do
    matches = test_filter('SIS_B')
    expect(matches.length).to eq(2)
  end
end