const DATA = [
  { t:"Before you start", d:"Two minutes of setup. Everything below assumes these.", items:[
    ["Install the build","Install the APK on a real Android phone or an emulator.","","","It installs and opens to the landing screen without a crash."],
    ["Two accounts ready","Renter aajoo.renter1@mailinator.com / Renter@12345 · Host aajoo.host1@mailinator.com / Host@12345","","","Both sign in. The tab on the login screen decides WHICH side you enter — use the Host tab for the host account."],
    ["Location set to India","Allow location. On an emulator set it to Manali (32.2432, 77.1892) in Extended controls, then restart the app.","","","The home screen names an Indian place. A foreign location makes every distance check meaningless."],
    ["Know the test stays","29262 Malhotra Villa (weekend rates + extra-guest charge + capacity 8) · 29263 (extra guests, capacity 6) · 8 (legacy weekend rate) · 29253 (host blocked 25 and 27 Aug).","","","Pricing and capacity are EMPTY on almost every other listing, so a random stay looks broken when it is not. Use these."],
  ]},

  { t:"Signing in", d:"The app and the website must agree about who you are and what went wrong.", items:[
    ["Renter signs in","Log in on the Renter tab.","/user/login","","Lands on the guest home with the map and the bottom tab bar."],
    ["Host signs in","Log out, log in on the HOST tab.","/user/login","","Lands on the host dashboard, not the guest home."],
    ["Wrong password says so","Type a wrong password.","/user/login","","Plain English. No database text, no error code."],
    ["Wrong tab is explained","Sign in with the HOST account on the Renter tab.","/user/login","","It says this is a host account and to switch tabs — not “no record found”."],
    ["Back from Sign up returns to Login","Tap Sign up, then press the Android back button.","","","You return to “Welcome back”. It used to close the app entirely."],
    ["Session survives a restart","Force-stop the app and reopen it.","","","Still signed in, same account."],
    ["Logout is clean","Log out, then reopen.","/user/logout","","Back at the landing screen, with no trace of the previous account’s name or photo."],
  ]},

  { t:"Finding a stay", d:"Guest side. Keep the website open beside you and compare.", items:[
    ["Home loads","Open the guest home.","/properties/search","","Map, stay count and rails all render. “1 home near you” reads as ONE home, not “1 homes”."],
    ["Map pins are priced","Look at the pins.","","","A pin reads ₹3,200 — comma, no .00, no paise."],
    ["Search by place","Open the search sheet, pick a destination, Search.","/properties/search","","Results move to that place."],
    ["Dates and guests are kept","In the search sheet set When and Who, search, then open any stay.","/properties/search","","The property page ALREADY has your dates and guest count. You are not asked twice. This is the biggest recent fix."],
    ["Categories filter","Tap a category chip.","/common/categories","","Only stays of that type. The chips come from the admin catalogue, so Pool House should be among them."],
    ["Nothing found says so","Search a remote spot, or set filters nothing matches.","","","It says nothing matched and offers to clear the filters. It must NOT say “Homes near you” over an empty list."],
    ["LUXE mode","Turn LUXE on.","/properties/search","","Only luxury stays, and the transition plays."],
  ]},

  { t:"The property page", d:"Everything a guest reads before paying.", items:[
    ["Gallery and details","Open 29262.","/properties/:id","","Photos, About, amenities, house rules, map and reviews all present."],
    ["No invented rating","Open a stay with no reviews.","","","It says New — it does not show 4.5 out of thin air."],
    ["Guest stepper is capped","On 29262 hold + on Adults.","","","Stops at 10: “This place sleeps 10 guests” — capacity 8 plus the 2 extra the host will take."],
    ["Weekend nights cost more","On 29262 pick Fri 28 → Mon 31 Aug.","","","₹19,000 for 3 nights (6,000 + 6,500 + 6,500), NOT 3 × 5,000. The header shows the average per night."],
    ["Guest count changes the price","With those dates, take guests from 8 to 10.","","","A line appears: 2 extra guests × ₹1,000 × 3 nights = ₹6,000. Total ₹19,950 → ₹26,250."],
    ["Legacy weekend rate works too","Open property 8 and pick a weekend.","","","Fri/Sat/Sun cost ₹9,500 against a ₹8,500 base."],
    ["Booked dates are blocked","Open 29253 and open the date picker.","/booking/property-availability","","25 and 27 August cannot be picked. 26 CAN — they are two separate one-day blocks."],
    ["Dates are readable","Look at the check-in/check-out fields.","","","24/08/2026, zero-padded — not 24/8/2026."],
    ["Prices are formatted","Look at every price, including the bottom bar.","","","₹2,000 with a comma. Never ₹2000, never paise."],
    ["A story links to its stay","Open a stay with Guides & stories (29250), open a post.","/blog/search","","The post ends with “The stay in this story” naming the house, and it opens that stay."],
  ]},

  { t:"Booking and paying", d:"Real bookings in test mode. Use a Razorpay test card.", items:[
    ["Review carries everything","Book 29262 with dates and 10 guests.","","","Checkout shows the same dates, party and ₹26,250."],
    ["Changing the party re-prices","On checkout change the guest count.","","","The extra-guest line and the total both change — they must not stay stale."],
    ["Coupon applies","Apply a coupon code.","/user/coupons/validate","","The saving shown matches what the booking actually charges."],
    ["Approval-required stay says so","Book a normal listing.","/booking/create","","It tells you the host has to confirm. Almost every listing works this way."],
    ["Pay at property","Book choosing pay-on-arrival.","/booking/create","","Confirmed, and the amount due on arrival is the FULL taxed total."],
    ["Pay online","Book choosing online payment.","/create/payment-verify","","Razorpay opens, a test card completes, the booking shows as paid."],
    ["A refusal explains itself","Force a failure with a bad card.","","","The reason stays on screen with a way forward — not a bare “failed”."],
    ["Your own held dates stay yours","Start a booking, abandon it at payment, then book the SAME dates again.","","","It goes through. It used to refuse with “already booked” against your own unpaid hold."],
    ["Verifying does not lose the booking","Book on an unverified account so it sends you to ID verification, finish, return.","","","The home screen offers to resume, and reopens the SAME stay with the same dates AND guest count."],
  ]},

  { t:"Negotiating a price", d:"The product’s whole point. Test both sides.", items:[
    ["Send an offer","On a stay, Send an Offer below the asking price.","/user/negotiations/offer","","It sends and appears under My Negotiations."],
    ["Offer above list is refused","Offer MORE than the asking price.","","","It tells you to just book it."],
    ["Host sees it","Sign in as the host, open Negotiations.","/host/negotiations/list","","The offer is there with the amount and the guest."],
    ["Host counters","Counter from the host side.","/host/negotiations/respond","","The guest sees the counter, with the amount and the round."],
    ["Host accepts","Accept an offer.","/host/negotiations/respond","","The guest’s negotiation shows Accepted."],
    ["Book at the agreed price","As the guest, tap “Book at the agreed price”.","","","The stay opens with the AGREED dates and the coupon applied. It must not open an empty listing."],
    ["Accepted is not confirmed","Read the accepted deal.","","","It explains the price is agreed but the host still confirms the booking — so “Accepted” here and “Pending” in bookings do not contradict."],
  ]},

  { t:"My bookings", d:"After the money.", items:[
    ["Bookings list","Open Booking History.","/user/booking-history","","Upcoming, ongoing, past and cancelled all under the right heading."],
    ["Detail opens the right one","Tap View details on a specific booking.","","","It opens THAT booking, not a different one."],
    ["Refund is shown BEFORE cancelling","Tap Cancel on a paid booking.","/user/cancel/quote","","It tells you what you get back and under which policy BEFORE you confirm. New — it used to just cancel."],
    ["Unpaid booking says nothing to refund","Cancel a pay-at-property booking.","","","It says nothing has been charged so there is nothing to refund. It must not show ₹0."],
    ["Cancel that cannot happen","Try to cancel a stay that has checked in.","","","It says why, instead of opening a dialog that fails."],
    ["Invoice","Download an invoice.","/user/invoice/:id/download","","A real PDF with the right amount."],
    ["Review after the stay","Leave a review on a completed stay.","/user/review-add","","It saves and shows on the property."],
  ]},

  { t:"Messages, profile and settings", d:"Guest account area.", items:[
    ["Messages inbox","Profile → Messages.","/user/messages/threads","","Your conversations are listed with unread counts. This screen is NEW on mobile."],
    ["A conversation loads and sends","Open a thread, send a message.","","","History loads, your message appears on the right and survives a reopen."],
    ["Profile completion","Open Profile.","/user/detail","","If anything is missing it shows a percentage and names what to add. At 100% the card is not shown at all."],
    ["Edit profile","Change your name or address and save.","/user/update","","It saves and shows the new value."],
    ["Phone needs a code","Try to change your phone number.","/user/security/otp","","It asks for an emailed code first."],
    ["Notifications","Open Notifications.","/user/notification/Listing","","Real notifications, and tapping one opens the thing it is about."],
    ["Saved stays","Save a stay, open Bookmarks.","/properties/user-saveProp","","It is there, and unsaving removes it."],
  ]},

  { t:"Host — setting up", d:"Sign in on the HOST tab for everything below.", items:[
    ["Host dashboard","Open the host home.","/host/home","","Earnings, bookings and property counts are real, and grouped Indian-style (₹1,10,678 — pairs above the last three digits)."],
    ["Bank account","Menu → Bank Account.","/payout/account/details","","The saved account shows, masked. Do NOT type a real account number — check the form refuses an empty or malformed one."],
  ]},

  { t:"Host — listing a property", d:"The 5-step wizard, driven by the same schema as the website.", items:[
    ["Wizard opens","Tap + Add on the host dashboard.","/listing/schema","","Step 1 of 5, with a progress bar."],
    ["Categories come from admin","Look at the property types.","","","The same list the admin catalogue holds — Pool House included."],
    ["Empty step is refused","Press Continue with nothing filled.","","","A banner at the top AND a red mark under each missing field, scrolled into view."],
    ["Name rule matches its own hint","Type a 4-letter name.","","","Refused with “Use 5–80 characters…” — the same words as the hint under the field. It used to say “at least 3” and disagree with itself."],
    ["Category changes the questions","Pick different property types.","","","The questions below change — each category has its own flow."],
    ["Capacity is collected","Fill Guest capacity and Basic configuration.","/listing/step1","","Adults, children, total, bedrooms, beds and baths all save."],
    ["Price limits","Enter a price of 5, then 99999999.","/listing/step4","","Both refused: must be between ₹100 and ₹1,000,000."],
    ["Photos have a minimum","Reach step 5 without photos.","","","Readiness shows a percentage, lists what is missing, and Submit for review is DISABLED until it is complete."],
    ["Identity is not asked twice","Look at step 5 as a verified host.","","","“Already done — nothing to fill in.”"],
    ["Draft survives","Leave the wizard part-way and reopen it.","/listing/draft/:id","","Your answers are still there."],
  ]},

  { t:"Host — bookings", d:"The core loop. Nearly every booking needs the host to act.", items:[
    ["Bookings list","Open Bookings.","/host/booking-history","","Upcoming / Ongoing / Completed / Cancelled all list correctly."],
    ["The card does not contradict itself","Read a card for an unpaid ONLINE booking.","","","One status chip, not the same words twice. The line by the price names the METHOD (“Online payment”), never “Paid online” on something unpaid. Nothing is clipped at the card edge."],
    ["Amounts are grouped","Look at the prices.","","","₹3,938 — comma, no paise. The detail page agrees with the list."],
    ["CONFIRM a booking","Open one showing “Awaiting approval” and tap Confirm.","/host/confirm-book","","It becomes Confirmed, the button disappears, and the guest is told. THE MOST IMPORTANT CHECK HERE — it did not exist before."],
    ["Cancel with a reason","Tap Cancel this booking.","/host/cancel-booking","","It insists on a reason, says the guest is refunded under the policy, and the guest is told why."],
    ["Check in a guest","On a stay starting today, tap Mark guest as checked-in.","/host/booking/check-in","","It flips to Staying now and the GUEST gets a notification."],
    ["Guest contact","Open a booking detail.","","","Call and Chat both work, and the staying-guest card shows when the booking was made for someone else."],
  ]},

  { t:"Host — calendar", d:"Where a host protects their own dates.", items:[
    ["Calendar opens","Open Calendar and pick a listing.","/host/calendar","","The month renders with a legend; bookings and blocks are marked."],
    ["The past is closed","Try to tap a date earlier than today.","","","It is dimmed and does nothing. You cannot start a range in the past."],
    ["Block a range","Tap two future dates, give a reason, Block.","/host/calendar/block","","The dates show as blocked."],
    ["Blocking reaches guests","As a GUEST, open that listing’s date picker.","/booking/property-availability","","Those dates cannot be booked."],
    ["Unblock","Open a blocked range and remove it.","/host/calendar/unblock","","It clears, and the guest can book again."],
  ]},

  { t:"Host — money", d:"Earnings, payouts, statements.", items:[
    ["Earnings","Open Earnings.","/host/earnings/summary","","Total, settled, pending and last payout are real and grouped (₹1,04,814)."],
    ["Pay-at-property is explained","Read the awaiting-collection note.","","","It says that money is not counted as earnings until it reaches the platform, and no payout is scheduled against it."],
    ["A failed payout says why","Find a FAILED payout.","","","The reason is printed under it, and FAILED is coloured as a problem — not the same grey as QUEUED. NEW."],
    ["Request a payout","Request one.","/payout/request/create","","It is accepted and appears in the list."],
    ["Statements","Open Statements.","/host/statements/search","","Periods list, and a statement downloads."],
  ]},

  { t:"Host — negotiations and support", d:"The two remaining host surfaces.", items:[
    ["Offers list","Open Negotiations.","/host/negotiations/list","","Live offers with the guest, the amount and the round count."],
    ["Respond","Accept, counter and decline.","/host/negotiations/respond","","Each reaches the guest, and the round count moves."],
    ["Floor is respected","Check an offer at or above your minimum.","","","Accepted automatically. Anything below comes to you to decide."],
    ["Raise a ticket","Host Support → new ticket.","/host/support/tickets/create","","It is created and appears in your list."],
    ["Reply on a ticket","Reply to a ticket.","/host/support/tickets/reply","","Your reply is added and the admin sees it."],
    ["Admin reply arrives","Have the admin reply from the panel.","/host/support/tickets/search","","It appears on the phone."],
  ]},

  { t:"Not built on mobile yet", d:"These exist on the website and are NOT in the app. Please do not report them as bugs — mark Blocked if you go looking.", items:[
    ["Refer & Earn","Look for it on either side.","","","Absent on mobile. The web has /account/refer and /host/refer."],
    ["Host Performance","Look for a performance screen.","","","Absent on mobile."],
    ["Host Boost","Look for paid placement / Boost.","","","Absent on mobile — a host cannot buy placement from the phone."],
    ["Host notifications list","Look for host notifications.","","","Absent on mobile. The GUEST side has one."],
    ["State and City are typed, not picked","In the listing wizard look at State and City.","","","Free text on mobile; the website picks from the reference tables. Flagged, not yet changed."],
  ]},

  { t:"Regression — fixed this week", d:"Every one of these was broken and is meant to be fixed. If any fails, tell me before going further.", items:[
    ["Search answers travel","Dates and guests from search reach the property page and checkout.","","","Asked once, not three times."],
    ["Host can confirm","A host can accept a booking from the phone.","","","The single most important fix — without it every booking sat pending."],
    ["Refund shown before cancelling","The guest sees the refund first.","","","Before, not after."],
    ["Calendar refuses the past","Past dates are dimmed and inert.","","","You cannot block yesterday."],
    ["Payout failure has a reason","FAILED payouts explain themselves.","","","On the app and the website."],
    ["One rupee format","Every price on every screen.","","","₹1,10,678 — Indian grouping, no paise, identical everywhere."],
    ["Booking card is consistent","Chips and the payment line agree.","","","No duplicated chip, nothing clipped, no “Paid online” on an unpaid booking."],
    ["Wizard name rule","Matches its own hint.","","","5 characters, not 3."],
    ["Back from signup","Returns to login.","","","Does not close the app."],
    ["Blog post links to its stay","Property posts open and link back.","","","They used to show “That post isn’t available”."],
  ]},
];
