# Army KlangTECH — App Review Justifications

Copy each block below into the matching permission/feature request in
App Dashboard → App Review. Write in English (Meta reviews in English).
Each request also needs a screencast upload and the confirmation checkbox ticked.

Before submitting: complete Business Verification, set the Privacy Policy URL
(https://army.klangtech.com/privacy) and Data Deletion URL
(https://army.klangtech.com/data-deletion), keep the app hosted at
https://army.klangtech.com, and add the reviewer's Facebook account as a Tester
(App Roles) so the flow works in Development mode.


## pages_show_list

Army KlangTECH is a customer-support inbox for Facebook Pages. We use pages_show_list to retrieve the list of Pages the logged-in person manages (GET /me/accounts) during onboarding, so they can choose which Page to connect to our app.

Why it is necessary: the app cannot receive or send a Page's messages until the person selects and connects a specific Page they manage. Listing their Pages is the only way to let them pick the correct one.

Benefit to the person using the app: they see all their manageable Pages and connect the right one in a single click, instead of manually finding and entering a Page ID or access token.

How to test:
1. Go to https://army.klangtech.com and click "Continue with Facebook".
2. Grant access. The app calls /me/accounts and shows the Pages you manage.
3. Select a Page to connect it.


## pages_manage_metadata

We use pages_manage_metadata to programmatically subscribe the connected Page to our webhook (POST /{page-id}/subscribed_apps) during onboarding, and to set the Messenger welcome screen (Get Started button and persistent menu) via the Messenger Profile API.

Why it is necessary: without subscribing the Page to the app's webhook, Army KlangTECH would receive no message events, so no auto-replies or human handoff could work.

Benefit to the person using the app: they connect a Page and it is instantly ready to receive and answer messages, with no manual webhook configuration in the App Dashboard.

How to test:
1. Sign in with Facebook and connect a Page.
2. On connect, the app subscribes the Page to webhooks and sets up the welcome screen. The Page shows as "Active".
3. Message the Page. The message is received by the app.


## pages_messaging

Army KlangTECH uses pages_messaging to receive messages that customers send to a connected Page (via webhooks) and to send replies on the Page's behalf. Replies are either automated answers to common questions and order-status lookups, or messages written by a human support agent. We only reply to customers who first messaged the Page, and we never send promotional or bulk messages.

Why it is necessary: receiving and answering Page messages is the core function of the app.

Benefit to the person using the app: businesses answer customer questions instantly (FAQ and order status) and hand off complex cases to a human agent, all from one inbox.

How to test:
1. Sign in with Facebook and connect a Page.
2. From another account, message the Page "where is order 1001". The app replies with the order status.
3. Message something unrecognized such as "my item arrived damaged". It is escalated to the human agent inbox.


## Human Agent (Advanced Access feature — requested separately)

Army KlangTECH escalates customer inquiries that our automation cannot resolve to a human support agent. Because investigating an issue (for example a damaged order or a refund) can take longer than Meta's standard 24-hour window, the human agent uses the Human Agent tag to deliver their personally written reply within the permitted 7-day window. The tag is never used for automated, promotional, or bulk messages, only for a human agent responding to a specific customer inquiry. Before sending, the app requires the agent to confirm "I am a human agent", and it blocks sending once the 7-day window has expired.

How to test:
1. From a customer account, send the Page a message the bot cannot auto-answer. It appears in the "Needs a human" queue.
2. In Army KlangTECH, open that conversation, read the thread, type a reply, tick the "I confirm I am a human agent" box, and send.
3. The message is delivered to the customer using the Human Agent tag.


## public_profile

Granted by default. No review required. Used for the person's basic identity at login.


## Screencast (one video covers all)

Record one end-to-end video and upload it (or the relevant portion) to each request:
1. Sign in with Facebook at https://army.klangtech.com.
2. See and select the Page you manage, then connect it.
3. From another account, message the Page "where is order 1001". The bot replies with the order status.
4. Message something unrecognized. It lands in the "Needs a human" queue.
5. Open the conversation, type a reply, tick the human-agent confirmation, and send. The reply is delivered with the Human Agent tag.

This single flow demonstrates pages_show_list, pages_manage_metadata, pages_messaging, and Human Agent.


## Reviewer instructions (paste into the "instructions for reviewers" field)

App: Army KlangTECH, a customer-support inbox for Facebook Pages, hosted at https://army.klangtech.com

Facebook Login confirmation: The app uses Facebook Login for Business. A Page admin signs in with Facebook, grants pages_show_list, pages_manage_metadata, and pages_messaging, then connects a Page. The app auto-replies to customer messages (order lookup) and escalates unresolved cases to a human agent who replies using the Human Agent tag.

1) Sign in (Facebook Login for Business)
- Go to https://army.klangtech.com and click "Continue with Facebook".
- Grant the requested permissions. You will land on the Home page.

2) Connect a Page (uses pages_show_list and pages_manage_metadata)
- Go to https://army.klangtech.com/onboarding/connect and click "Connect with Facebook".
- The app calls GET /me/accounts to list the Pages you manage (pages_show_list). Select a Page.
- The app calls POST /{page-id}/subscribed_apps to subscribe the Page to webhooks (pages_manage_metadata) and sets up the Messenger welcome screen. The Page then shows as "Active".

3) Test messaging (uses pages_messaging)
- From another Facebook account, send a message to the connected Page:
  - Send "where is order 1001". The bot replies with the order status (test order numbers 1001 to 1008 are available).
  - Send "my item arrived damaged". The message is not auto-resolved, so it is escalated: the bot replies that a human agent will follow up, and a ticket is created.
- In the app, open Inbox then "Needs a human" to see the escalated conversation.

4) Test Human Agent tag
- In Inbox then "Needs a human", open the escalated conversation, type a reply, tick the "I confirm I am a human agent" checkbox, and click Send.
- The reply is delivered using messaging_type=MESSAGE_TAG, tag=HUMAN_AGENT (used only by a human agent, within the 7-day window).

Optional (auto-reply rules): Go to "Automations" to add an FAQ rule (topic, trigger words, reply). Messaging the Page with a trigger word then returns that reply automatically.

Privacy Policy: https://army.klangtech.com/privacy
Data Deletion: https://army.klangtech.com/data-deletion

Note: order numbers 1001 to 1008 are global test data seeded in production, so they work for any Page the reviewer connects. Add the reviewer's Facebook account as a Tester (App Roles) so the login flow works while the app is in Development mode.
