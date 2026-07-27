# Orders-only seed for testing the order-status auto-reply.
# Safe + idempotent: touches ONLY the orders table, never pages/users/tickets.
# Run:  bin/rails runner db/seeds/orders.rb
#
# Order numbers are 4 digits so Order.find_by_query's /#?(\d{4})/ regex matches.
# Test by messaging the page e.g. "where is order 1001" or "status of #1005".

# NOTE: the Order model validates `status` as unique, so every status below is distinct.
orders = [
  { order_number: "1001", status: "shipped",          customer_name: "Jane Doe",        item_details: "1x Wireless Headphones (Tracking #TRK98765)" },
  { order_number: "1002", status: "processing",       customer_name: "John Smith",      item_details: "2x Mechanical Keyboards" },
  { order_number: "1003", status: "delivered",        customer_name: "Somchai P.",      item_details: "1x USB-C Charger, 1x Cable" },
  { order_number: "1004", status: "out for delivery", customer_name: "Maria Garcia",    item_details: "1x Office Chair" },
  { order_number: "1005", status: "cancelled",        customer_name: "Alex Wong",       item_details: "3x Notebooks (refund pending)" },
  { order_number: "1006", status: "refunded",         customer_name: "Priya Nair",      item_details: "1x Bluetooth Speaker" },
  { order_number: "1007", status: "on hold",          customer_name: "David Kim",       item_details: "1x Monitor (address unconfirmed)" },
  { order_number: "1008", status: "in transit",       customer_name: "Natthapat L.",    item_details: "1x Phone Case, 2x Screen Protectors" }
]

orders.each do |attrs|
  order = Order.find_or_create_by!(order_number: attrs[:order_number]) do |o|
    o.status = attrs[:status]
    o.customer_name = attrs[:customer_name]
    o.item_details = attrs[:item_details]
  end
  # keep an existing row in sync if statuses were changed in the seed
  order.update!(attrs) unless order.previously_new_record?
end

puts "Orders seeded. Total orders now: #{Order.count}"
puts "Test messages: 'where is order 1001', 'status #1005', 'order 1008?'"
