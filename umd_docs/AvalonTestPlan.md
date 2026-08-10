# Avalon Test Plan

## Introduction

This document provides a basic Avalon test plan that verifies as many UMD
customizations and other concerns (such as functionality when using read-only
containers) as feasible.

The intention is to provide basic assurance that the UMD customizations are in
place, and guard against regressions.

**The document is not intended to be an exhaustive test plan.**

As this test plan adds, modifies, and deletes data, it should ***not*** be used
to test the production system.

## Test Plan Assumptions

This test plan assumes that:

* the "umd-handle", "ipmanager", and "archelon" applications are also running
  in the Kubernetes namespace being tested.
* the user has "administrator" privileges, and can log in via CAS.
* the user has a video file to upload, such as a video file from the
  "SSDR/Developer Resource/savalon-sample-data" folder in Box.
* (optional) the user has an SSH public key registered with the Archelon
  instance running in the Kubernetes namespace (needed for the "SFTP Access"
  step).

The test plan steps are specified using URLs for the Kubernetes "test"
namespace, as that seems to be the most useful. Unless otherwise specified,
test steps should work in the local development environment as well.

## Test Plan

### 1) Avalon Home Page

1.1) In a web browser, go to

<https://av-test.lib.umd.edu/>

The Avalon home page will be displayed.

1.2) On the Avalon home page, verify that:

* The UMD favicon is displayed in the browser tab, and that the text in
  the browser tab is "Avalon"
* The appropriate SSDR environment banner is displayed.

1.3) At the bottom of the page, verify that the footer has the following links:

* "Give Now"
* "Privacy policy"
* "Web Accessibility"

1.3.1) Left-click the "Give Now" link. Verify that the "Giving to Maryland" page
on the university website is displayed.

1.3.2) Go back to the Avalon home page, and left-click the "Privacy policy" link.
Verify that the privacy policy page from the UMD Libraries website is displayed.

1.3.3) Go back to the Avalon home page, and left-click the "Web Accessibility"
link. Verify that the web accessibility page on the university website is
displayed.

### 2) CAS Login

2.1) On the Avalon home page, left-click the "Sign in" button in the upper-right
corner of the page. Verify that the browser is redirected to CAS.

2.2) Log in via CAS. Once returned to the Avalon home page, verify that your
user's email address (and a "Sign out" link) are displayed in the upper-right
corner of the page, along with a notification indicating a successful login.

### 3) Collection Creation

3.1) From the navigation bar, select "Manage | Manage Content" from the
navigation bar. The page will with units and collections will be displayed.

----

**Local Development Environment** <!-- markdownlint-disable-line MD036-->

When running in the local development environment, there may be no units
displayed on the page. If so, create a new unit,
`Special Collections in Performing Arts`, using the "Create New Unit" button
before proceeding to the next step.

After creating the unit, left-click  "Manage | Manage Content" from the
navigation bar to return to the page.

----

3.2) Create a new collection by left-clicking the "Create Collection" button.
The "New collection" page will be displayed.

3.3) On the "New collection" page, fill out the following fields:lds:

| Field | Value |
| ----- | ----- |
| Name  | SSDR Test Collection |
| Unit  | <Select "Special Collections in Performing Arts" from the dropdown> |

then left-click the "Create Collection" button. A notification will display
indicating that the collection was successfully created.  A
"Manage Collection | SSDR Test Collection" page will be displayed.

### 4) Item Submission

4.1) On the "Manage Collection | SSDR Test Collection" page, left-click the
"Create an Item" button. The "Edit Media Object > Manage files" page will be
displayed.

4.2) On the “Edit Media Object > Manage files” page, left-click the
“Browse...” button in the “Section files” section. In the resulting file
dialog, select a video file, and then left-click the “Upload” button. Once the
upload is complete, verify that that a notification is displayed indicating that
the uploaded content is a video file. Left-click the “Continue” button at the
bottom of the page. The “Edit Media Object > Resource description” page will
be displayed.

4.3) On the “Edit Media Object > Resource description” page, fill out the
following fields:

| Field | Value |
| ----- | ----- |
| Name  | SSDR Test Item |
| Publication Date | <Enter a date in YYYY-MM-DD format, i.e., `2025-08-27`> |

then left-click the “Save and continue” button at the bottom of the page. The
“Edit Media Object > Structure” page will be shown.

4.4) On the “Edit Media Object > Structure” page, left-click the “Continue”
button. The “Edit Media Object > Access Control” page will be shown.

4.5) On the “Edit Media Object > Access Control” page, left-click the
"UMD IP Manager" dropdown and verify that it is populated with one or more
entries (these entries are the "exported" groups from IP Manager).

Left-click the “Save and continue” button at the bottom of the page. The item
detail page for the item will be displayed.

4.6) On the item detail page, wait for the conversion process to complete
(if necessary), then left-click the “Publish” button to publish the item.
The item detail page will refresh. Verify that the page displays a notification
indicating that the page was successfully published.

4.7) On the item detail page, left-click the “Share” button to expand it. Verify
that the “Item” link has a handle URL appropriate for the Kubernetes namespace.
For example, for the Kubernetes "test" namespace the URL should have the form:

`https://hdl-test.lib.umd.edu/1903.1/<HANDLE_SUFFIX>`

where <HANDLE_SUFFIX> is a simple integer.

4.8) On the item detail page, verify that there is a
"Request This Item" button above the right sidebar. Left-click
the "Request This Item" button and verify that a new browser tab is
opened on the Aeon website. After logging in to Aeon, verify that
"New Duplication Request" page is displayed with the following fields
populated:

* Title - the title of the item
* Date - the publication date of the item
* Catalog Record ID - the handle URL for the item
* Location field - the name of the collection (i.e., "SSDR Test Collection")

Left-click the "Cancel - Return to Main Menu" button at the bottom of the page
and close the browser tab.

### 5) Collection-Level Discoverability for Restricted Streaming Items

This section verifies that items with restricted streaming access are still
discoverable to public (anonymous) users when discoverability is inherited
from a standard (non-Course-Reserves) collection.

The following steps assume that two browser windows are in use:

* A browser window with a logged-in administrator user, that was used in the
  previous steps
* A second, private/incognito browser window used at different points to test
  anonymous and logged-in user access.

> **Note**
> This section reuses the "SSDR Test Collection" and item from the previous
> steps.
>
> The permissions on the "SSDR Test Collection" detail page should be:
>
> * Item Discovery | “Hide this item from search results” - \<Unchecked>
> * Item Access - "Collection staff only".
> * Assign special access - \<No options set>
>
> The item in the collection should be:
>
> * Should be published
> * Access Control | Special Access inheritance - Disable parent permissions -
>   \<Unchecked>
> * Access Control | Item discovery - This item is not hidden from search results.
> * Access Control | Item access - This item is accessible by collection staff.
> * Access Control | Assign special access - \<No options set>
>
> If necessary, edit the collection and item to set these permissions and
> save the changes.

5.1) As the administrative user:

5.1.1) Go to the Archelon home page by left-clicking the "Home" button in the
navigation bar.

5.1.2) In the search textbox, search for the item added in the previous steps.
Verify that the item appears in the search results on the "Browse" page.

5.1.3) Left-click the item in the search results. The item detail page will
be displayed. Verify that:

* The item metadata (title, description, etc.) is displayed.
* the media player is visible and the item can be streamed

5.2) In the private/incognito browser window (not logged in):

5.2.1)  Go to

<https://av-test.lib.umd.edu/catalog>

Verify that the "Browse" page is displayed.

5.2.2) Search for the item added in the previous steps. Verify that the item
appears in the search results on the "Browse" page.

5.2.3) Left-click the item in the search results. The item detail page will
be displayed. Verify that:

* The item metadata (title, description, etc.) is visible.
* a "Playback Restricted" panel or equivalent restricted playback message is
  displayed in place of the media player.

### 6) Item-Level Override Restricts Access

This section verifies that item-level override can restrict discoverability
within a publicly discoverable standard (non *Course Reserves*) collection with
**no** special access configured.

6.1) As the administrative user:

6.1.1) Reuse the same published item from the previous steps. From the item
detail page, left-click the “Edit” button to go to the
“Edit Media Object > Access Control” page.

6.1.2) On the "Access Control" page:

* Left-click the “Disable parent permissions” checkbox to select it, then
  left-click “Save” at the bottom of the page.
* After saving, verify that the “Item Discovery” and “Item Access” edit options
  are visible.
* Under “Item Discovery”, left-click the “Hide this item from search results”
  checkbox to select it, and then left-click "Save"

Verify that the following permissions are now:

* Special Access inheritance - Disable parent permissions - \<Checked>
* Item discovery - Hide this item from search results - \<Checked>
* Item access - Collection staff only
* Assign special access - \<No options set>

> The expected results below depend on this: hiding an item does not
> take away access that Item Access grants, so it is the “Collection staff
> only” setting that refuses the anonymous user in the following steps

6.2) In the private/incognito browser window (not logged in), open the
"Developer Tools" in the browser, then:

6.2.1) Go to

<https://av-test.lib.umd.edu/catalog>

Verify that the "Browse" page is displayed.

6.2.2) Search for the title of the item and verify that the item does
**not** appear in the search results on the "Browse" page.

6.2.3) In the private/incognito window, go directly to the item detail page,
and verify that:

* A "Restricted Content" message is displayed
* The item metadata (title, description, etc.) is **not** displayed.
* a 401 Unauthorized response code is in the "Network" tab of the Developer
  Tools

6.3) To verify that hiding the item does **not** revoke an access token, as
the administrative user:

> Hiding an item controls only its discoverability; users who were granted
> access explicitly must still be able to reach it.

6.3.1) Reuse the same published item from the previous steps. From the item
detail page, left-click the “Edit” button to go to the
“Edit Media Object > Access Control” page.

6.3.2) On the "Access Control" page, add an access token by left-clicking the
"Create a new token" button in the "Access Token" panel. An access token form
will be displayed.

6.3.3) On the access token form, change the "Access" field to
"Streaming and Download" and left-click the “Save” button to generate an
access token for the media object. An access token detail page will be
displayed.

6.3.4) On the access token detail page, copy the access token URL near the
bottom of the page.

6.4) In the private/incognito browser window (not logged in):

6.4.1) Use the access token URL from the previous step. Verify that:

* The item detail page is displayed
* the media player is visible and the item can be streamed
* a "Files" tab (allowing downloads) is displayed in the right sidebar.

6.4.2) Left-click the "Files" tab, and then left-click the file link in the
"Media Files" section to download the file. Verify that the file downloads
successfully.

6.5) As the administrative user:

6.5.1) On the access token detail page, left-click the "Revoke" button. Verify
that the page is updated and now indicated that the status of the access token
is "Revoked".

6.5.2) On the access token detail page, left-click the "Access Tokens List"
button. The "Access Tokens" page will be displayed.

6.5.3) On the "Access Tokens" page verify that the token added in the previous
steps is *not* displayed (as it is not an active token). Change the
"Filter by status" dropdown to "revoked" and left-click the "Go" button.
Verify that the access token added in the previous steps is in the list.

6.6) In the private/incognito browser window (not logged in):

6.6.1) Refresh the private browser window and verify that the
"Restricted Content" message is again displayed.

6.7) To verify that hiding the item does **not** revoke
"Assign special access",as the administrative user:

> This step requires that you have access to an Avalon test account
> separate the account used in the previous steps.
>
> To create such a user, go to "Manage | Manage Users", then on the
> "Manager Users" page, enter `<CAS_ID>+test@umd.edu` where \<CAS_ID> is your
> UMD CAS username. Then left-click the "Invite user" button.
>
> An email will be sent to your UMD email account. Accept the invitation,
> and enter a password/password confirmation for the user.
>
> After logging out as the user, you can get back into the test user account by
> going to <https://av-test.lib.umd.edu/users/sign_in?admin=true> and
> signing using `<CAS_ID>+test@umd.edu` and the password that you entered.

6.7.1) Go to the item detail page, then left-click the "Edit" button for the
item to go to the “Edit Media Object > Access Control” page.

6.7.2) On the "Access Control" page, in the "Assign special access" section:

* Delete the entry in the "External Group" section created by the (now revoked)
  access token by left-clicking the "X" button on the right side of the entry.
* Add the test user's username to the "Avalon User" field, and left-click the
"Add" button.

Verify that the item access control permisisons are now:

* Special Access inheritance - Disable parent permissions - \<Checked>
* Item discovery - Hide this item from search results - \<Checked>
* Item access - Collection staff only
* Assign special access - Avalon User - `<CAS_ID>+test@umd.edu`

6.7.2) In the private/incognito window, go to

<https://av-test.lib.umd.edu/users/sign_in?admin=true>

log in to Avalon via CAS as the test user.

6.7.3) On the Avalon home page, search for the item. Verify that the item
**does not** appear in the search results on the "Browse" page.

6.7.4) Go directly to the item detail page, and verify that:

* The item detail page is displayed
* the media player is visible and the item can be streamed

6.7.5) In the private/incognito window log out form the test user by
left-clicking the "Sign out" link in the navigation bar.

6.8) To verify that hiding does **not** override Item Access, as the
administrative user:

> The item used above has Item Access "Collection staff only", which is why the
> anonymous user was refused in previous steps. Hiding an item removes it from
> browse/search and withdraws the metadata view a published item otherwise
> grants to everyone, but it never takes away access that Item Access itself
> grants.

6.8.1) Remove the special access for the test user by deleting the entry in
the "Avalon User" section by left-clicking the "X" button on the right side of
the entry.

Then change the settings to the following:

* "Item Access" to "Available to the general public", and left-click the "Save"
button.

Verify that:

* Special access inheritance  - Disable parent permissions - \<Checked>
* Item discovery - Hide this item from search results - \<Checked>
* Item access - "Available to the general public" selected
* Assign special access - \<No options set>

6.8.2) In the private/incognito window (not logged in), search for the title of
the item. Verify that the item is **not** displayed in the search results.

6.8.3)In the private/incognito window (not logged in), go directly to the
the item detail page, and verify that:

* the item detail page **is** viewable, and the item metadata (title,
  description, etc.) is displayed.
* The media player is displayed, and the item can be streamed successfully.

6.9) As the administrative user, set "Item Access" to "Logged in users
only" and left-click "Save".

6.10) In the private/incognito window (not logged in) refresh the item detail
page. Verify that:

* a "Restricted Content" page is displayed
* a 401 Unauthorized response code is displayed in the "Network" tab of the
browser tools.

6.11) In the private/incognito window, go to

<https://av-test.lib.umd.edu/users/sign_in?admin=true>

log in to Avalon as the test user (one who is not staff on the collection).

6.11.1) Search for the title of the item and verify that the item does
**not** appear in the search results on the "Browse" page.

6.11.2) Go directly to the item detail page, and verify that:

* the item detail page **is** viewable
* the item can be streamed successfully.

6.11.3) In the private/incognito window, logout from the test user by
left-clicking the "Sign out" link in the navigation bar.

6.12) Verify that the same holds when Item Access is set on the collection
As the administrative user:

6.12.1) Edit the item's "Access Control" page, change the settings to the
following:

----
TODO: Not sure if the following steps should be necessary

* In "Item Discovery", left-click the "Hide this item from search results" to
unselect it.
* In "Item Access", left-click the "Collection staff only" option to select it.
* Left-click the "Save" button to save the changes

----

* In "Special access inheritance", left-click the "Disable parent permissions"
checkbox to unselect it, and left-click the "Save" button.

Verify that the item settings are now:

* Special access inheritance  - Disable parent permissions - \<Unchecked>
* Item discovery - Displays "This item is not hidden from search results."
* Item access -  Displays "This item is accessible by collection staff. "
* Assign special access - \<No options set>

6.12.2) Left-click the "SSDR Test Collection" link in the breadcrumb bar. The
"Manage Collection" page will be displayed.

6.12.3) On the "Manage Collection" page:

* In "Item Discovery", left-click the "Hide this item from search results"
checkbox to select it, and left-click the "Save Setting" button.
* In "Item Access", left-cick the "Available to the general public" radio button
to select it and left-click the "Save Setting" button.

Verify that the collection settings are now:

* Item discovery - Hide this item from search results - \<Checked>
* Item access - Available to the general public
* Assign special access - \<No options set>

6.12.1) In the private/incognito window (not logged in):

6.12.1.1) Search for the title of the item and verify that the item does
**not** appear in the search results on the "Browse" page.

6.12.1.2) Go directly to the item detail page, and verify that:

* the item detail page **is** viewable
* the item can be streamed successfully.

### 7) UMD IP Manager Group-Based Access

> **Note:** Since the Avalon pre-production environments are not accessible
> outside the UMD network, we will test IP-based access control by first
> restricting access to a more restrictive IP Manager group (for example, *The
> Jim Henson Works* IP Manager group, which is limited to a small set of
> McKeldin public access computers) to verify that access is correctly
> **blocked**. We will then expand access to the broader *UMD College Park
> campus and VPN* group to verify that access is **granted** as expected.

7.1) As the administrative user, select "Manage | Manage Content".
The page with units and collections will be displayed.

7.2) Left-click the link for the "SSDR Test Collection.  The
"Manage Collection" collection detail page will be displayed.

7.3) On the collection detail page set the permissions as follows:

* Item Discovery | “Hide this item from search results” - \<Unchecked>,
  and left-click the "Save Setting" button.
* Item Access - "Collection staff only", and left-click the "Save Setting"
  button.
* Under the "Assign special access" section, left-click the UMD IP Manager
  dropdown and select *The Jim Henson Works* group, and then left-click the
  "Add" button next to the dropdown to save the change.

Verify that the collection settings are now:

* Item discovery - Hide this item from search results - \<Unchecked>
* Item access - Collection staff only
* Assign special access - UMD IP Manager - The Jim Henson Works

7.4) On the collection detail page, left-click the "List All Items" button,
then on the "Browse" page, left-click the "SSDR Test Item" entry. The
item detail page will be displayed.

7.4.1) On the item detail page, left-click the "Edit" button. The
"Access Control" page for the item will be displayed.

7.4.2) On the "Access Control" page, verify that the permissions are set
to the following, changing and saving them if necessary:

* Special Access inheritance - Disable parent permissions - \<Unchecked>
* Item discovery - Displays "This item is not hidden from search results."
* Item access -  Displays "This item is accessible by collection staff. "
* Access Control | Assign special access - External Group - umd.ip.manager:henson

7.5) In the private/incognito browser window (not logged in), go to

<https://av-test.lib.umd.edu/catalog>

Search for the title of the item and verify that the item appears in the search
results on the "Browse" page.

7.6) In the private/incognito window, go to the item detail page.

7.6.1) If you're on campus (McKeldin Library), and **not** connected to VPN,
verify that:

* The item metadata (title, description, etc.) is displayed.
* The media player is displayed, and the item can be streamed successfully.

7.6.2) If you're off/on campus, and connected to VPN, verify that:

* The item metadata (title, description, etc.) is displayed.
* A "Playback Restricted" panel or equivalent restricted playback message is
  displayed in place of the media player.

7.7) Optionally, if doing this test after a major upgrade, physically go the
McKeldin Library public access computers and test access anonymously from a
computer in the *The Jim Henson Works* IP Manager group.

Verify that:

* The item metadata (title, description, etc.) is displayed.
* The media player is displayed, and the item can be streamed successfully.

7.8) Change the IP Manager group for the
collection:

7.8.1) As the administrative user, select "Manage | Manage Content".
The page with units and collections will be displayed.

7.8.2) Left-click the link for the "SSDR Test Collection".  The
"Manage Collection" collection detail page will be displayed.

7.8.3) On the collection detail page, under the "Assign special access"
section, left-click the UMD IP Manager dropdown and select *UMD College Park
campus and VPN* group. Left-click the "**Add**" button next to the dropdown to
save the changes.

7.8.4) On the collection detail page, under the "Assign special access"
section, left-click the "X" next to the *The Jim Henson Works* group to remove
it.

7.9) In the private/incognito window, refresh the item detail page:

7.9.1) If you're on campus, or connected to VPN, verify that:

* The item metadata (title, description, etc.) is displayed.
* The media player is displayed, and the item can be streamed successfully.

### 8) LTI Flow

**Note:** Steps 8.1 and 8.2 require access to a running Docker environment or
Kubernetes namespace. The rake task provisions a test course and user.

8.1) In a terminal, run the following rake task to provision a test LTI course
and user:

```bash
docker compose exec avalon bash -c "rails umd:provision_test_lti_course_and_user"
```

The task defaults to `context_id=test-course-context-id` and
`title=Test Course Title`. To customise, set the `TEST_LTI_COURSE_CONTEXT_ID`
and `TEST_LTI_COURSE_TITLE` environment variables.

8.2) From the navigation bar, select "Manage | Manage Content" to go to the
Manage Content page. Create a new unit named **Streaming Reserves** and
within it create a new collection named **Digitized Items**:

  a) Left-click the "+ Create Unit" button. On the "New unit" page, enter
     **Streaming Reserves** in the Name field, then left-click "Create Unit".
     The unit detail page for "Streaming Reserves" will be displayed.

  b) On the "Streaming Reserves" unit page, left-click the "Create Collection"
     button. On the "New collection" page, fill out the following fields:

     | Field | Value |
     | ----- | ----- |
     | Name  | Digitized Items |
     | Unit  | Streaming Reserves (pre-filled) |

  then left-click the "Create Collection" button. Verify that the collection
  is created successfully.

8.3) On the "Digitized Items" collection page, left-click the
"Create an Item" button and create a new item following the same steps as
section 4 (upload a video file, add a title and publication date, continue
through Structure, and reach the "Access Control" step).

8.4) On the "Edit Media Object > Access Control" page, add the test course as
an external group:

  a) In the **External Groups** field, start typing `Test Course` (or the
     title used in step 8.1). An autocomplete dropdown will appear with
     formatted values (Eg. 1: Test Course Title).

  b) Left-clicking on the test course entry in the dropdown should fill the
     formatted value in the External Groups field, then left-click the "Add"
     button.

  c) Verify that the page reloads and the formatted course title is listed
     under the **External Groups** section (Eg. _1:_ Test Course Title).

Left-click the "Save and continue" button. The item detail page will be
displayed.

8.5) Publish the item by left-clicking the "Publish" button on the item detail
page and verify that a success notification is displayed.

8.6) From the navigation bar, select "Manage | View Courses". The "Courses"
page will be displayed. Locate the test course created in step 8.1 and
left-click the "Browse Course Items" button next to it.

8.7) Verify that the browse page is displayed, that the item created in step 8.3
is listed in the results, and that the left facet panel shows **Test Course
Title** (or the title used in step 8.1) pre-selected under the **Course Name**
facet.

8.8) From the navigation bar, select "Manage | View Courses". The "Courses"
page will be displayed. Locate the test course created in step 8.1 and
left-click the "Impersonate" button next to it.

8.9) Verify that the course view is displayed and that the item created in step
8.3 is listed in the course view.

8.10) In the browser, navigate to

<https://av-test.lib.umd.edu/>

Verify that the home page renders correctly within the LTI session. Then
left-click the "Sign out" link and verify that the LTI session is ended
successfully.

8.11) In the private/incognito browser window (not logged in):

8.11.1) Go to

<https://av-test.lib.umd.edu/catalog>

Verify that the browse page is displayed.

8.11.2) Search for the title of the Course Reserves item from the previous
steps. Verify that the item does not appear in the search results on the
"Browse" page.

8.11.3) In the private/incognito window, go directly to the item detail URL for
the Course Reserves item and verify that:

* a "Restricted Content" page is displayed
* a 401 Unauthorized response code is displayed in the "Network" tab of the
browser tools.

### 8) robots.txt

**Note:** This step cannot be tested in the local development environment.

8.1) In a web browser go to

<https://av-test.lib.umd.edu/robots.txt>

Verify the contents of a "robots.txt" file is displayed.

### 9) sitemap.xml

**Note:** This step cannot be tested in the local development environment.

9.1) In a web browser go to

<https://av-test.lib.umd.edu/sitemap.xml>

Verify that a "sitemap" file is returned.

### 10) Item Deletion

10.1) Go back to the item detail page of the item added in the previous steps.

10.2) On the item detail page, left-click the "Edit" button. The
"Edit Media Object > Access Control" page will be displayed.

10.3) On the "Edit Media Object > Access Control" page, left-click the
"Delete this item" button at the bottom of the left sidebar. A confirmation
page will be displayed.

10.4) On the confirmation page, left-click the "Yes, I am sure" button. The
Avalon home page will be displayed with a notification indicating that the
media object was deleted.

### 11) Collection Deletion

11.1) From the navigation bar, select "Manage | Manage Content" from the
navigation bar. The "My Collections" page will be displayed.

11.2) On the "My Collections" page, find the "SSDR Test Collection" entry in the
list and left-click the "Delete" button. A confirmation
page will be displayed.

11.3) On the confirmation page, left-click the "Yes, I am sure" button. The
"My Collections"" page will be displayed. Verify that the "SSDR Test Collection"
no longer appears in the list of collections.
