# Meta App Review Demo Application (Ruby on Rails)

A Ruby on Rails application containing **5 minimal, isolated demo flows** designed specifically to satisfy Meta's App Review process for Messenger and Instagram Messaging permissions.

Each demo flow is self-contained, easy for a human reviewer to click through in under 5 minutes during screencast recording, and features **strict HMAC-SHA256 signature verification** (`X-Hub-Signature-256`), **Facebook-Only Login (OAuth SSO)**, **Conversations Chat History API**, **Message Echoes**, **UChat-style strict Human Agent Tag Operator Desk**, and **live audit logging**.

---

## 🎯 4 Core Boss Requirements Coverage Summary

| Requirement | Meta Permission / API | Implementation Details |
| :--- | :--- | :--- |
| **1. ตอบแชทได้ (Reply to Chats)** | `pages_messaging` (Send API `POST /me/messages`) | Fully supported across all 5 demo flows using Faraday `MetaGraphClient` with quick replies & text. |
| **2. Get History ย้อนหลังได้ (Chat History)** | `pages_messaging` / Conversations API (`GET /{page_id}/conversations`) | Built `get_page_conversations` API client method & interactive Chat History Viewer in Agent Inbox (`/profiles/inbox`). |
| **3. ขอ Human Agent Tag ได้ (UChat Mockup)** | `human_agent` message tag (`pages_messaging_subscriptions`) | Built a UChat-style strict Human Operator Station (`/orders/tickets`) featuring 7-day window timers, resolution category pickers, operator confirmation checkboxes, and tag payload inspection. |
| **4. Echo ได้ (Read messages from Page Inbox / Other Apps)** | `pages_messaging` webhook field `message_echoes` (`is_echo: true`) | Webhook processor parses `is_echo: true` events and records outgoing admin messages sent from Meta Business Suite / Page Inbox into ticket history. |

---

## 🛠 Step-by-Step: Meta Developer Portal App Setup

Follow these exact steps to configure your app in the [Meta Developer Portal](https://developers.facebook.com):

### Step 1: Create a Meta Business App
1. Go to [developers.facebook.com](https://developers.facebook.com) and sign in.
2. Click **My Apps** → **Create App**.
3. Select **Business** as the app type (or **Other** → **Business**).
4. Enter an **App Display Name** (e.g. `My Business Messaging Platform`) and select your App Contact Email. Click **Create App**.

### Step 2: Add Required Products
From your App Dashboard, add the following products:
- **Messenger**: Click **Set Up** under Messenger.
- **Facebook Login for Business**: Click **Set Up** under Facebook Login.
- **Instagram Graph API**: Click **Set Up** (if submitting Flow 5 for IG DMs).

### Step 3: Configure Facebook Login Settings (OAuth)
1. In the left sidebar, navigate to **Facebook Login** → **Settings**.
2. Scroll to **Valid OAuth Redirect URIs** and add:
   - `http://localhost:3000/auth/facebook/callback` (for local development)
   - `http://localhost:3000/onboarding/callback`
   - `https://<your-ngrok-or-cloudflare-domain>/auth/facebook/callback` (for public testing)
   - `https://<your-ngrok-or-cloudflare-domain>/onboarding/callback`
3. Click **Save Changes**.

### Step 4: Configure Webhooks
1. In the left sidebar, navigate to **Messenger** → **Settings** → **Webhooks**.
2. Click **Add Callback URL** (or **Configure Webhooks**):
   - **Callback URL**: `https://<your-ngrok-or-cloudflare-domain>/faq/webhook` (or any of your flow webhook paths)
   - **Verify Token**: Must match `FB_VERIFY_TOKEN` in your `.env` file (e.g., `demo_webhook_verify_token`).
3. Click **Verify and Save**. (Your Rails app must be running behind ngrok/Cloudflare to respond to GET verification).
4. Under **Subscription Fields**, subscribe to:
   - `messages`
   - `messaging_postbacks`
   - `messaging_optins`
   - `message_echoes` *(for Echo Requirement #4)*

### Step 5: Generate Page Access Token & Connect Page
1. Navigate to **Messenger** → **Settings** → **Access Tokens**.
2. Click **Add or Remove Pages** and select your Facebook Page.
3. Click **Generate Token** next to your Page. Copy this token into `FB_PAGE_ACCESS_TOKEN` in your `.env`.

### Step 6: Copy App Credentials to `.env`
1. Navigate to **App Settings** → **Basic**.
2. Copy your **App ID** → paste into `FB_APP_ID` in `.env`.
3. Click **Show** next to **App Secret**, copy it → paste into `FB_APP_SECRET` in `.env`.

---

## ⚡ Technical Architecture & Tradeoffs

### Graph API Client Choice: Faraday vs Koala
- **Tradeoff Analysis**:
  - *Koala*: Provides a high-level wrapper for Meta Graph API calls. However, Koala has not maintained active support for recent Graph API versions (v19.0/v20.0), message tags (`HUMAN_AGENT`), structured Instagram messaging quick replies, Conversations API, or modern webhook signature validation.
  - *Faraday*: Lightweight, modular, and natively supports custom Graph API versioning (`v20.0`), explicit JSON payload manipulation, headers, connection pooling, and transparent request logging.
- **Decision**: We use **Faraday** direct Graph API calls encapsulated inside a dedicated `MetaGraphClient` service object (`app/services/meta_graph_client.rb`).

---

## 🛠 Local Setup & Tunneling (ngrok / Cloudflare)

### 1. Installation
```bash
# Clone and setup environment variables
cp .env.example .env

# Install dependencies
bundle install

# Run database setup & seeds
bin/rails db:migrate
bin/rails db:seed

# Start Rails server
bin/rails server -p 3000
```

### 2. Exposing Webhooks via Tunnel (ngrok / Cloudflare Tunnel)
Meta webhooks require a publicly accessible HTTPS endpoint.

#### Using ngrok:
```bash
ngrok http 3000
```

#### Using Cloudflare Tunnel:
```bash
cloudflared tunnel --url http://localhost:3000
```

---

## 🔐 Environment Variables (`.env`)

| Variable | Description |
| :--- | :--- |
| `FB_APP_ID` | Your Meta Application ID (App Settings → Basic) |
| `FB_APP_SECRET` | Your Meta Application Secret (App Settings → Basic) |
| `FB_PAGE_ACCESS_TOKEN` | Generated Facebook Page Access Token |
| `FB_VERIFY_TOKEN` | Custom Webhook Verification Token (e.g., `demo_webhook_verify_token`) |
| `IG_ACCESS_TOKEN` | Instagram Access Token |
| `GRAPH_API_VERSION` | Meta Graph API Version (Default: `v20.0`) |

---

# 📋 5 Meta App Review Permission Flows

Below are the 5 review cards containing the exact permission names, submission justifications, and step-by-step screencast walkthroughs.

---

## Flow 1: Page Auto-Responder / FAQ Bot

### Permission(s) Requested
- `pages_messaging`

### Submission Justification (Paste into Meta Review Form)
> This application uses the `pages_messaging` permission to automatically process incoming customer messages sent to our Facebook Page. Upon receiving a message, the app searches a pre-configured FAQ table (business hours, location, pricing, return policy) and uses the Graph API Send API to return an automated text response along with interactive quick-reply buttons so customers receive immediate support.

### Step-by-Step Screencast Walkthrough
1. **Start Screencast**: Show your Meta App Dashboard and the local application running at `http://localhost:3000`.
2. **Configure Webhook**: Set the webhook URL in Meta App Dashboard to `https://<your-domain>/faq/webhook` with verify token `demo_webhook_verify_token`. Subscribed field: `messages`.
3. **Send Message on Facebook Page**: Open Messenger as a user and send `"What are your business hours?"` or `"Location"`.
4. **Demonstrate Bot Response**: Show the bot instantly replying with business hours/location and 3 interactive Quick Reply buttons ("Store Hours", "Location", "Pricing").
5. **Click Quick Reply**: Click "Pricing" and show the bot responding with pricing details.
6. **Show Logs**: Open `http://localhost:3000/webhook_logs` to show the logged `200 OK` webhook execution and signature verification.

---

## Flow 2: Order/Inquiry Status Bot with Human Handoff (UChat Style)

### Permission(s) Requested
- `pages_messaging`
- `human_agent` Message Tag (or `pages_messaging_subscriptions` if outside 24h window)

### Submission Justification (Paste into Meta Review Form)
> This application uses `pages_messaging` and the `human_agent` message tag to allow human customer support representatives to respond to customer inquiries outside the standard 24-hour messaging window (up to 7 days). When a customer's inquiry cannot be resolved automatically, a support ticket is created in our human operator console. Human agents select a resolution category, complete an operator confirmation check, and issue a human-authored response using the `HUMAN_AGENT` message tag.

### Step-by-Step Screencast Walkthrough
1. **Send Order Inquiry**: Message the Page with `"where is my order #1001"`. Show the bot replying with mock order status (`SHIPPED`).
2. **Trigger Human Handoff**: Message the Page with `"I need help with my damaged order #1009"`.
3. **Show Ticket Escalation**: Show the bot replying that a human agent has been notified, and creating an open ticket in the Rails application.
4. **Open Human Agent Operator Desk**: Navigate to `http://localhost:3000/orders/tickets`. Point out ticket #1 generated for the user's PSID with the outside-24h window countdown indicator.
5. **Demonstrate UChat Human Verification**:
   - Select Resolution Category: `Order Issue / Damage`.
   - Type custom reply: `"Hi Bob, I reviewed your damaged item and issued a replacement order."`
   - Check mandatory Human Confirmation: `[x] I confirm I am a human agent responding to a customer issue within the 7-day window`.
6. **Send Reply via Human Agent Tag**: Click **Send Reply via HUMAN_AGENT Tag**. Show success notification and API payload tag verification (`messaging_type: "MESSAGE_TAG"`, `tag: "HUMAN_AGENT"`).

---

## Flow 3: Page Profile Lookup & Chat History for Support Agents

### Permission(s) Requested
- `Business Asset User Profile Access`
- `pages_messaging` (Conversations API)

### Submission Justification (Paste into Meta Review Form)
> This application uses `Business Asset User Profile Access` to retrieve the sender's full name, profile picture, and locale via the Graph API (`GET /{psid}`) whenever a customer messages our business page. Additionally, it uses the Conversations API (`GET /{page_id}/conversations`) to fetch historical chat logs from Meta servers. This data is displayed in our internal Support Agent Inbox so agents can identify customers and review past conversation context.

### Step-by-Step Screencast Walkthrough
1. **Send Message**: Send any test message to the Page webhook at `https://<your-domain>/profiles/webhook`.
2. **Open Agent Inbox**: Navigate to `http://localhost:3000/profiles/inbox`.
3. **Show Profile Cards**: Point to the customer entry displaying the fetched user profile avatar, full name, PSID, and locale (`en_US`).
4. **Demonstrate Chat History API**: Select your Facebook Page in the **Meta Graph API Chat History Viewer** and click **Fetch Meta Chat History**. Show the raw JSON conversation history returned from `GET /{page_id}/conversations`.

---

## Flow 4: Page Connect / Onboarding Flow

### Permission(s) Requested
- `pages_show_list`
- `pages_manage_metadata`
- `business_management`

### Submission Justification (Paste into Meta Review Form)
> This application uses `pages_show_list`, `pages_manage_metadata`, and `business_management` to enable business owners to connect their Facebook Pages to our platform via Facebook Login for Business. The app calls `GET /me/accounts` to display the list of pages managed by the user, allows them to select a Page, and programmatically subscribes our webhook to that Page via `POST /{page_id}/subscribed_apps`.

### Step-by-Step Screencast Walkthrough
1. **Navigate to Onboarding**: Open `http://localhost:3000/onboarding/connect`.
2. **Initiate OAuth Flow**: Click **Connect with Facebook** (or paste a test User Access Token into the manual input box and click **Fetch Manageable Pages**).
3. **View Page List**: Show the rendered table listing pages returned from `GET /me/accounts`.
4. **Connect & Subscribe Page**: Click **Connect & Subscribe Webhook** next to a Page.
5. **Verify Subscription**: Show the success notification confirming `POST /{page_id}/subscribed_apps` returned `success: true` and the page status changed to `SUBSCRIBED`.

---

## Flow 5: Instagram DM Auto-Reply for Creator/Brand Inquiries

### Permission(s) Requested
- `instagram_manage_messages`
- `business_management`

### Submission Justification (Paste into Meta Review Form)
> This application uses `instagram_manage_messages` and `business_management` to manage Direct Messages sent to connected Instagram Professional Accounts. When a user sends a DM to the Instagram account, the webhook triggers an automated reply containing quick-reply options ("I'm a Brand" / "I'm a Creator") so brand collaboration and creator inquiries can be routed to the appropriate department.

### Step-by-Step Screencast Walkthrough
1. **Navigate to IG Accounts**: Open `http://localhost:3000/instagram/accounts`.
2. **Link IG Business Account**: Click **Fetch Linked IG Account** to demonstrate querying `GET /{page_id}?fields=instagram_business_account`.
3. **Send Instagram DM**: Send a direct message to the connected Instagram Business account or send a mock payload to `https://<your-domain>/instagram/webhook`.
4. **Demonstrate DM Auto-Reply**: Show the bot responding on Instagram with an intro message and Quick Replies ("I'm a Brand" / "I'm a Creator").
5. **Verify Execution**: Open `http://localhost:3000/webhook_logs` to show the completed Instagram webhook execution.
