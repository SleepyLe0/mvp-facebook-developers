# ReplyDesk — App Review Justifications

Paste each block into the matching permission/feature request in
App Dashboard → App Review → Permissions and Features.

> Before submitting: complete Business Verification, set the Privacy Policy URL
> (`/privacy`) and Data Deletion URL (`/data-deletion`), host on a stable public
> URL, and add the reviewer's Facebook account as a Tester (App Roles) so the
> flow works in Development mode.

---

## pages_messaging

ReplyDesk is a customer-support inbox for Facebook Pages. We use `pages_messaging`
to receive messages that customers send to a connected Page (via webhooks) and to
send replies on the Page's behalf. Replies are either automated answers to common
questions and order-status lookups, or messages written by a human support agent.
We only send messages in response to a customer who first messaged the Page; we do
not send promotional or bulk messages.

**How to test:**
1. Log in with Facebook and connect a Page.
2. From another account, message the Page: `where is order 1001` — ReplyDesk replies
   with the order status automatically.
3. Message something unrecognized (e.g. `my item arrived damaged`) — the conversation
   is escalated to the agent inbox for a human to answer.

---

## pages_manage_metadata

We use `pages_manage_metadata` to programmatically subscribe the connected Page to
our webhook (`POST /{page-id}/subscribed_apps`) during onboarding, so the Page can
receive message events without the admin having to configure webhooks manually in
the App Dashboard.

**How to test:** Connect a Page in the app. ReplyDesk subscribes it to the webhook
and shows its status as "Active" on the Connections screen.

---

## pages_show_list

We use `pages_show_list` to retrieve the list of Pages the logged-in user manages
(`GET /me/accounts`) so they can choose which Page to connect to ReplyDesk.

**How to test:** After signing in with Facebook, the app displays the user's Pages
and lets them pick one to connect.

---

## Human Agent (Advanced Access feature)

ReplyDesk escalates customer inquiries that our automation cannot resolve to a human
support agent. Because investigating an issue (for example a damaged order or a
refund) can take longer than Meta's standard 24-hour window, the human agent uses the
Human Agent tag to deliver their personally-written reply within the permitted 7-day
window. The tag is never used for automated, promotional, or bulk messages — only for
a human agent responding to a specific customer inquiry. Before sending, the app
requires the agent to confirm "I am a human agent," and it blocks sending once the
7-day window has expired.

**How to test:**
1. From a customer account, send the Page a message our bot cannot auto-answer — it
   appears in the "Needs a human" queue.
2. In ReplyDesk, open that conversation, read the thread, type a reply, tick the
   "I confirm I am a human agent" box, and send.
3. The message is delivered to the customer using the Human Agent tag.

---

## public_profile
Granted by default — no review required. Used for the user's basic identity at login.
