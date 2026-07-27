# Never auto-seed demo data in production — `db:prepare` runs this on a fresh
# database (e.g. first Kamal deploy), which would wipe real data and create
# fake pages/users. For prod test data, run db/seeds/orders.rb explicitly.
if Rails.env.production?
  puts "Skipping demo seed in production."
  return
end

# Clear existing seed data
User.destroy_all
FaqEntry.destroy_all
Order.destroy_all
SupportTicket.destroy_all
UserProfile.destroy_all
ConnectedPage.destroy_all
WebhookLog.destroy_all

puts "Seeding Default Facebook SSO User..."
demo_user = User.create!(
  name: "Demo Facebook Admin",
  email: "admin@example.com",
  facebook_uid: "109876543210987",
  facebook_access_token: "EAA...demo_user_token"
)

puts "Seeding FAQ Entries..."
FaqEntry.create!([
  {
    question: "What are your business hours?",
    answer: "🕒 Our business hours are Monday – Friday, 9:00 AM to 6:00 PM EST. We are closed on weekends and public holidays.",
    keywords: "hours,open,closing,schedule,time"
  },
  {
    question: "Where are you located?",
    answer: "📍 Our flagship store is located at 123 Tech Avenue, Suite 400, San Francisco, CA 94107.",
    keywords: "location,address,where,directions,find"
  },
  {
    question: "What is your pricing structure?",
    answer: "💳 We offer flexible plans: Basic ($19/mo), Pro ($49/mo), and Enterprise (Custom). Contact us for volume discounts!",
    keywords: "pricing,price,cost,plans,subscription,fee"
  },
  {
    question: "What is your return policy?",
    answer: "🔄 We offer a 30-day money-back guarantee on all physical and digital products. No questions asked!",
    keywords: "return,refund,guarantee,policy,exchange"
  }
])

puts "Seeding Mock Orders..."
Order.create!([
  {
    order_number: "1001",
    status: "shipped",
    customer_name: "Jane Doe",
    item_details: "1x Wireless Headphones (Tracking #TRK98765)"
  },
  {
    order_number: "1002",
    status: "processing",
    customer_name: "John Smith",
    item_details: "2x Mechanical Keyboards"
  },
  {
    order_number: "1003",
    status: "delivered",
    customer_name: "Alice Johnson",
    item_details: "1x UltraWide Monitor"
  }
])

puts "Seeding Escalated Support Tickets for Human Handoff..."
SupportTicket.create!([
  {
    psid: "1234567890123456",
    customer_name: "Bob Williams",
    status: "open",
    last_message: "My order #1009 was damaged during transit. Can I speak to a representative?",
    human_agent_notes: nil
  },
  {
    psid: "9876543210987654",
    customer_name: "Sarah Miller",
    status: "open",
    last_message: "I'd like a custom quote for enterprise deployment.",
    human_agent_notes: nil
  }
])

puts "Seeding User Profiles for Profile Lookup Demo..."
UserProfile.create!([
  {
    psid: "1234567890123456",
    first_name: "Bob",
    last_name: "Williams",
    profile_pic: "https://via.placeholder.com/150/3b82f6/ffffff?text=BW",
    locale: "en_US"
  },
  {
    psid: "9876543210987654",
    first_name: "Sarah",
    last_name: "Miller",
    profile_pic: "https://via.placeholder.com/150/22c55e/ffffff?text=SM",
    locale: "en_US"
  }
])

puts "Seeding Connected Pages for Onboarding Demo..."
ConnectedPage.create!([
  {
    user: demo_user,
    page_id: "109876543210987",
    name: "Demo Enterprise Store",
    access_token: "EAA...demo_access_token",
    instagram_business_account_id: "17841400000000000",
    subscribed: true
  }
])

puts "Seeding Complete! Seeded Facebook SSO User (#{demo_user.display_name}), #{FaqEntry.count} FAQs, #{Order.count} Orders, #{SupportTicket.count} Tickets, #{UserProfile.count} Profiles, #{ConnectedPage.count} Pages."
