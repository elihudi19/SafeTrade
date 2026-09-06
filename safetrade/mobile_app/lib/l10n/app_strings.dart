/// Kamusi ya maneno yote ya app - Kiswahili cha Tanzania (sw) na
/// English (en). Maneno ya Kiswahili yameandikwa kwa lugha ya asili ya
/// kibiashara Tanzania (siyo tafsiri ngumu ya moja kwa moja) ili
/// yasikike ya kawaida kwa mfanyabiashara halisi.
library app_strings;

const Map<String, Map<String, String>> appStrings = {
  // ---------------------------------------------------------------------
  // JUMLA (Common)
  // ---------------------------------------------------------------------
  "app_name": {"sw": "SafeTrade", "en": "SafeTrade"},
  "tagline": {"sw": "Mauzo bila kikomo", "en": "Unlimited Sales"},
  "logout": {"sw": "Toka", "en": "Logout"},
  "cancel": {"sw": "Ghairi", "en": "Cancel"},
  "save": {"sw": "Hifadhi", "en": "Save"},
  "confirm": {"sw": "Thibitisha", "en": "Confirm"},
  "loading": {"sw": "Inapakia...", "en": "Loading..."},
  "retry": {"sw": "Jaribu Tena", "en": "Try Again"},
  "language": {"sw": "Lugha", "en": "Language"},
  "swahili": {"sw": "Kiswahili", "en": "Swahili"},
  "english": {"sw": "Kiingereza", "en": "English"},
  "ok": {"sw": "Sawa", "en": "OK"},
  "yes": {"sw": "Ndiyo", "en": "Yes"},
  "no": {"sw": "Hapana", "en": "No"},

  // ---------------------------------------------------------------------
  // LOGIN
  // ---------------------------------------------------------------------
  "username_label": {"sw": "Jina la Mtumiaji", "en": "Username"},
  "password_label": {"sw": "Nywila", "en": "Password"},
  "login_button": {"sw": "Ingia", "en": "Log In"},
  "login_error": {
    "sw": "Jina la mtumiaji au nywila si sahihi.",
    "en": "Incorrect username or password.",
  },
  "register_owner_link": {
    "sw": "Sajili Biashara Mpya (Mmiliki)",
    "en": "Register New Business (Owner)",
  },

  // ---------------------------------------------------------------------
  // REGISTER OWNER (NIDA + OTP)
  // ---------------------------------------------------------------------
  "register_owner_title": {"sw": "Sajili Biashara (Mmiliki)", "en": "Register Business (Owner)"},
  "business_name_label": {"sw": "Jina la Biashara", "en": "Business Name"},
  "nida_number_label": {"sw": "Namba ya NIDA", "en": "NIDA Number"},
  "nida_number_helper": {
    "sw": "Mfano: 19900101-12345-00001-12",
    "en": "Example: 19900101-12345-00001-12",
  },
  "phone_number_nida_label": {
    "sw": "Namba ya Simu (iliyosajiliwa NIDA)",
    "en": "Phone Number (registered with NIDA)",
  },
  "phone_number_helper": {"sw": "Mfano: 0712345678", "en": "Example: 0712345678"},
  "confirm_continue_button": {"sw": "Thibitisha na Endelea", "en": "Confirm and Continue"},
  "register_generic_error": {
    "sw": "Imeshindikana kusajili. Angalia taarifa ulizoweka.",
    "en": "Registration failed. Please check the details you entered.",
  },

  // ---------------------------------------------------------------------
  // OTP VERIFICATION
  // ---------------------------------------------------------------------
  "otp_verify_title": {"sw": "Thibitisha OTP", "en": "Verify OTP"},
  "otp_sent_to": {"sw": "Tumetuma OTP kwenye", "en": "We sent an OTP to"},
  "otp_input_label": {"sw": "Weka OTP", "en": "Enter OTP"},
  "otp_verify_button": {"sw": "Thibitisha", "en": "Verify"},
  "otp_resend_button": {"sw": "Tuma OTP Tena", "en": "Resend OTP"},
  "otp_invalid_error": {"sw": "OTP siyo sahihi.", "en": "Incorrect OTP."},
  "otp_resent_message": {"sw": "OTP mpya imetumwa.", "en": "A new OTP has been sent."},

  // ---------------------------------------------------------------------
  // OWNER DASHBOARD
  // ---------------------------------------------------------------------
  "owner_dashboard_title": {"sw": "Dashibodi ya Mmiliki", "en": "Owner Dashboard"},
  "add_staff_button": {"sw": "Ongeza Mfanyakazi", "en": "Add Staff"},
  "no_stores_message": {
    "sw": "Bado hakuna duka lililosajiliwa.",
    "en": "No store registered yet.",
  },
  "warehouse_label": {"sw": "Stoo", "en": "Warehouse"},
  "counter_label": {"sw": "Kaunta", "en": "Counter"},
  "pieces_unit": {"sw": "vipande", "en": "pcs"},
  "active_shifts_label": {"sw": "Shift zinazoendelea", "en": "Active shifts"},
  "today_sales_label": {"sw": "Mauzo ya leo", "en": "Today's sales"},
  "discrepancy_flags_label": {"sw": "Tofauti za Stock (Discrepancy)", "en": "Stock Discrepancies"},
  "predictive_analytics_title": {
    "sw": "Utabiri wa Akiba (Predictive Analytics)",
    "en": "Inventory Forecasting (Predictive Analytics)",
  },
  "recompute_button": {"sw": "Kokotoa Upya", "en": "Recalculate"},
  "no_alerts_message": {
    "sw": "Hakuna alert kwa sasa - kila kitu kiko sawa.",
    "en": "No alerts right now - everything looks good.",
  },
  "fast_moving_title": {"sw": "Bidhaa Inakaribia Kuisha", "en": "Stock Running Low"},
  "slow_moving_title": {"sw": "Bidhaa Inauzwa Polepole", "en": "Slow-Moving Stock"},
  "acknowledge_tooltip": {"sw": "Nimeshughulikia", "en": "Mark as Handled"},
  "current_stock_label": {"sw": "Stock ya sasa", "en": "Current stock"},
  "days_until_stockout_label": {
    "sw": "Inatarajiwa kuisha baada ya siku",
    "en": "Expected to run out in",
  },
  "daily_sales_pace_label": {"sw": "Kasi ya mauzo (siku 7)", "en": "Sales pace (7 days)"},
  "per_day_label": {"sw": "kwa siku", "en": "per day"},
  "trend_label": {
    "sw": "Mwenendo ikilinganishwa na wastani wa mwezi",
    "en": "Trend vs. monthly average",
  },
  "lead_time_label": {"sw": "Muda wa uagizaji", "en": "Restock lead time"},
  "days_unit": {"sw": "siku", "en": "days"},
  "suggested_reorder_label": {
    "sw": "Pendekezo: agiza vipande",
    "en": "Suggestion: reorder pieces",
  },
  "sold_last_30_days_label": {"sw": "Mauzo (siku 30)", "en": "Sales (30 days)"},
  "days_of_stock_remaining_label": {
    "sw": "Itachukua siku kuuza kwa kasi ya sasa",
    "en": "Days to sell out at current pace",
  },

  // ---------------------------------------------------------------------
  // STAFF CREATE (Owner)
  // ---------------------------------------------------------------------
  "add_staff_title": {"sw": "Ongeza Mfanyakazi", "en": "Add Staff"},
  "store_label": {"sw": "Duka", "en": "Store"},
  "select_store_first_error": {
    "sw": "Chagua duka kwanza (tengeneza duka kama halipo).",
    "en": "Select a store first (create one if none exists).",
  },
  "staff_type_label": {"sw": "Aina ya Mfanyakazi", "en": "Staff Type"},
  "cashier_role": {"sw": "Cashier", "en": "Cashier"},
  "storekeeper_role": {"sw": "Storekeeper", "en": "Storekeeper"},
  "phone_number_label": {"sw": "Namba ya Simu", "en": "Phone Number"},
  "register_button": {"sw": "Sajili", "en": "Register"},
  "staff_create_error": {
    "sw": "Imeshindikana - angalia taarifa ulizoweka.",
    "en": "Failed - please check the details entered.",
  },

  // ---------------------------------------------------------------------
  // STOREKEEPER DASHBOARD
  // ---------------------------------------------------------------------
  "storekeeper_dashboard_title": {
    "sw": "Dashibodi ya Storekeeper",
    "en": "Storekeeper Dashboard",
  },
  "transfer_button": {"sw": "Hamisha", "en": "Transfer"},
  "transfer_dialog_title": {"sw": "Hamisha", "en": "Transfer"},
  "transfer_quantity_label": {
    "sw": "Idadi ya kuhamisha kwenda Kaunta",
    "en": "Quantity to transfer to Counter",
  },
  "transfer_initiated_message": {
    "sw": "Uhamisho umeanzishwa - unasubiri ACCEPT ya Cashier.",
    "en": "Transfer initiated - waiting for Cashier to ACCEPT.",
  },
  "transfer_failed_message": {
    "sw": "Imeshindikana kuanzisha uhamisho.",
    "en": "Failed to initiate transfer.",
  },
  "offline_transfer_synced_message": {
    "sw": "Uhamisho uliosubiri offline umetumwa.",
    "en": "Offline-queued transfers have been sent.",
  },

  // ---------------------------------------------------------------------
  // CASHIER DASHBOARD
  // ---------------------------------------------------------------------
  "cashier_dashboard_title": {"sw": "Dashibodi ya Cashier", "en": "Cashier Dashboard"},
  "shift_active_label": {"sw": "Shift Inaendelea", "en": "Shift In Progress"},
  "shift_not_started_label": {"sw": "Hujaingia Shift", "en": "Shift Not Started"},
  "close_shift_button": {"sw": "Funga Hesabu", "en": "Close Shift"},
  "start_shift_button": {"sw": "Ingia Shift", "en": "Start Shift"},
  "shift_report_title": {"sw": "Ripoti ya Shift", "en": "Shift Report"},
  "pending_transfers_title": {"sw": "Mzigo Unaosubiri ACCEPT", "en": "Stock Awaiting ACCEPT"},
  "no_pending_transfers_message": {
    "sw": "Hakuna mzigo unaosubiri kwa sasa.",
    "en": "No stock awaiting acceptance right now.",
  },
  "quantity_sent_label": {"sw": "Idadi iliyotumwa", "en": "Quantity sent"},
  "confirm_receipt_dialog_title": {"sw": "Thibitisha Mapokezi", "en": "Confirm Receipt"},
  "actual_quantity_received_label": {
    "sw": "Idadi HALISI uliyopokea",
    "en": "ACTUAL quantity received",
  },
  "create_receipt_button": {"sw": "Kata Risiti", "en": "Create Receipt"},
  "printer_settings_tooltip": {"sw": "Mipangilio ya Printer", "en": "Printer Settings"},
  "offline_receipts_synced_message": {
    "sw": "Risiti za offline zimetumwa kikamilifu.",
    "en": "Offline receipts have been sent successfully.",
  },

  // ---------------------------------------------------------------------
  // RECEIPT CREATE
  // ---------------------------------------------------------------------
  "create_receipt_title": {"sw": "Kata Risiti", "en": "Create Receipt"},
  "counter_stock_label": {"sw": "Kaunta", "en": "Counter"},
  "available_label": {"sw": "zilizopo", "en": "available"},
  "total_label": {"sw": "Jumla", "en": "Total"},
  "customer_name_optional_label": {
    "sw": "Jina la Mteja (hiari)",
    "en": "Customer Name (optional)",
  },
  "customer_phone_digital_label": {
    "sw": "Namba ya Simu ya Mteja (kwa risiti ya kidijitali)",
    "en": "Customer Phone (for digital receipt)",
  },
  "payment_method_label": {"sw": "Njia ya Malipo", "en": "Payment Method"},
  "cash_payment": {"sw": "Cash", "en": "Cash"},
  "lipa_namba_payment": {"sw": "Lipa Namba", "en": "Lipa Namba"},
  "mpesa_payment": {"sw": "M-Pesa", "en": "M-Pesa"},
  "tigopesa_payment": {"sw": "Tigo Pesa", "en": "Tigo Pesa"},
  "digital_receipt_switch_title": {
    "sw": "Tuma Risiti ya SMS/WhatsApp (Digital)",
    "en": "Send Digital Receipt (SMS/WhatsApp)",
  },
  "digital_receipt_switch_subtitle": {
    "sw": "Cash bila hii = Nusu Ada. Ukiwasha = Ada Kamili.",
    "en": "Cash without this = Half Fee. Enabled = Full Fee.",
  },
  "print_on_counter_switch": {
    "sw": "Chapisha kwenye Printer ya Kaunta",
    "en": "Print on Counter Printer",
  },
  "finish_create_receipt_button": {"sw": "Maliza na Kata Risiti", "en": "Finish & Create Receipt"},
  "receipt_created_message": {"sw": "Risiti imekatwa kikamilifu.", "en": "Receipt created successfully."},
  "receipt_failed_message": {"sw": "Imeshindikana", "en": "Failed"},
  "printer_not_found_message": {
    "sw": "Risiti imehifadhiwa lakini printer haikupatikana - angalia Mipangilio ya Printer.",
    "en": "Receipt saved but printer not found - check Printer Settings.",
  },
  "print_failed_message": {
    "sw": "Risiti imehifadhiwa lakini uchapishaji umeshindikana.",
    "en": "Receipt saved but printing failed.",
  },

  // ---------------------------------------------------------------------
  // PRINTER SETTINGS
  // ---------------------------------------------------------------------
  "printer_settings_title": {"sw": "Mipangilio ya Printer", "en": "Printer Settings"},
  "bluetooth_off_message": {
    "sw": "Bluetooth ya kifaa hiki imezimwa. Iwashe kisha rudi hapa.",
    "en": "This device's Bluetooth is off. Turn it on and come back.",
  },
  "printer_pick_instructions": {
    "sw": "Chagua printer iliyokwisha-pair (Bluetooth Settings za kifaa) kisha bonyeza 'Jaribu Kuchapisha'.",
    "en": "Select an already-paired printer (in device Bluetooth Settings) then tap 'Test Print'.",
  },
  "no_paired_printers_message": {
    "sw": "Hakuna printer iliyo-pair kwenye Bluetooth ya kifaa.",
    "en": "No printer paired in this device's Bluetooth.",
  },
  "printer_selected_message": {"sw": "imechaguliwa.", "en": "selected."},
  "test_print_button": {"sw": "Jaribu Kuchapisha", "en": "Test Print"},
  "test_print_success_message": {
    "sw": "Risiti ya jaribio imetumwa kwa printer.",
    "en": "Test receipt sent to printer.",
  },
  "test_print_failed_message": {
    "sw": "Imeshindikana - hakikisha printer imewashwa na iko karibu.",
    "en": "Failed - make sure the printer is on and nearby.",
  },

  // ---------------------------------------------------------------------
  // MARKETPLACE / CART / ORDERS
  // ---------------------------------------------------------------------
  "marketplace_title": {"sw": "SafeTrade Marketplace", "en": "SafeTrade Marketplace"},
  "added_to_cart_message": {"sw": "Imeongezwa kwenye Cart.", "en": "Added to Cart."},
  "add_to_cart_button": {"sw": "Ongeza Cart", "en": "Add to Cart"},
  "cart_title": {"sw": "Cart Yangu", "en": "My Cart"},
  "cart_empty_message": {"sw": "Cart iko tupu.", "en": "Your cart is empty."},
  "delivery_type_label": {"sw": "Aina ya Delivery", "en": "Delivery Type"},
  "pickup_option_label": {
    "sw": "Pickup Mwenyewe Dukani (Bila Delivery)",
    "en": "Self Pickup at Store (No Delivery)",
  },
  "bolt_note": {
    "sw": "Kwa Bolt: pesa ya delivery haitolewi kwa dereva mpaka uthibitishe umepokea mzigo wako - hii inamlinda mteja.",
    "en": "For Bolt: delivery payment is not released to the driver until you confirm you've received your package - this protects you as the customer.",
  },
  "product_total_label": {"sw": "Jumla ya Bidhaa", "en": "Items Total"},
  "delivery_label": {"sw": "Delivery", "en": "Delivery"},
  "bolt_estimate_note": {
    "sw": "(makadirio - bei ya mwisho itathibitishwa)",
    "en": "(estimate - final price will be confirmed)",
  },
  "grand_total_label": {"sw": "JUMLA YA KULIPA", "en": "TOTAL TO PAY"},
  "cash_on_delivery_payment": {"sw": "Cash on Delivery", "en": "Cash on Delivery"},
  "checkout_button": {"sw": "Maliza Malipo (Checkout)", "en": "Complete Payment (Checkout)"},
  "checkout_failed_message": {"sw": "Checkout imeshindikana", "en": "Checkout failed"},
  "order_history_title": {"sw": "Oda Zangu", "en": "My Orders"},
  "no_orders_message": {"sw": "Bado hujafanya oda yoyote.", "en": "You haven't placed any orders yet."},
  "order_label": {"sw": "Oda", "en": "Order"},
  "confirm_delivery_dialog_title": {
    "sw": "Thibitisha Umepokea Mzigo",
    "en": "Confirm You've Received Your Package",
  },
  "confirm_delivery_dialog_content": {
    "sw": "Kama umepokea bidhaa zako kikamilifu, thibitisha hapa. Kwa Bolt, hii ndiyo itakayowezesha malipo kwenda kwa dereva.",
    "en": "If you've fully received your items, confirm here. For Bolt, this is what releases payment to the driver.",
  },
  "confirm_received_button": {"sw": "Ndiyo, Nimepokea", "en": "Yes, I've Received It"},
  "confirm_delivery_success_message": {
    "sw": "Asante! Umethibitisha kupokea mzigo wako.",
    "en": "Thank you! You've confirmed receipt of your package.",
  },
  "confirm_delivery_action_label": {"sw": "Nimepokea Mzigo", "en": "I've Received the Package"},

  // ---------------------------------------------------------------------
  // STOCK INTAKE (Mzigo Mpya - Storekeeper)
  // ---------------------------------------------------------------------
  "add_stock_intake_button": {"sw": "Ongeza Mzigo Mpya", "en": "Add New Stock"},
  "stock_intake_title": {"sw": "Andika Mzigo Mpya", "en": "Record New Stock Intake"},
  "product_label": {"sw": "Bidhaa", "en": "Product"},
  "quantity_received_label": {"sw": "Idadi ya Vipande Vilivyoletwa", "en": "Quantity Received (units)"},
  "is_bundle_switch": {
    "sw": "Bidhaa hii imenunuliwa kwa Carton/Kifungu?",
    "en": "Was this purchased as a Carton/Bundle?",
  },
  "units_per_bundle_label": {
    "sw": "Vipande kwa kila Carton/Kifungu",
    "en": "Units per Carton/Bundle",
  },
  "bundle_cost_price_label": {
    "sw": "Bei ya Carton/Kifungu Kizima (TZS)",
    "en": "Cost of Whole Carton/Bundle (TZS)",
  },
  "unit_cost_price_label": {"sw": "Bei ya Kipande Kimoja (TZS)", "en": "Cost per Unit (TZS)"},
  "transport_cost_label": {
    "sw": "Gharama ya Usafiri (TZS)",
    "en": "Transport Cost (TZS)",
  },
  "other_costs_label": {
    "sw": "Gharama Nyingine (kupakia, forodha, n.k.)",
    "en": "Other Costs (loading, customs, etc.)",
  },
  "computed_unit_cost_label": {"sw": "Bei ya Kipande (Imekokotolewa)", "en": "Cost per Unit (Computed)"},
  "total_shipment_cost_label": {"sw": "Gharama Jumla ya Mzigo Huu", "en": "Total Cost of This Shipment"},
  "suggested_min_price_label": {
    "sw": "Bei ya Chini Kabisa Isiyo na Hasara",
    "en": "Minimum Break-Even Price",
  },
  "save_stock_intake_button": {"sw": "Hifadhi Mzigo", "en": "Save Stock Intake"},
  "stock_intake_saved_message": {
    "sw": "Mzigo umeandikwa - stock ya Stoo imesasishwa.",
    "en": "Stock intake recorded - warehouse stock updated.",
  },
  "stock_intake_failed_message": {
    "sw": "Imeshindikana kuandika mzigo. Angalia taarifa ulizoweka.",
    "en": "Failed to record stock intake. Please check the details entered.",
  },

  // ---------------------------------------------------------------------
  // EXPENSES (Gharama za Jumla)
  // ---------------------------------------------------------------------
  "add_expense_button": {"sw": "Ongeza Gharama", "en": "Add Expense"},
  "expense_title": {"sw": "Ongeza Gharama ya Biashara", "en": "Add Business Expense"},
  "expense_category_label": {"sw": "Aina ya Gharama", "en": "Expense Category"},
  "category_transport": {"sw": "Usafiri", "en": "Transport"},
  "category_rent": {"sw": "Kodi ya Duka", "en": "Store Rent"},
  "category_utilities": {"sw": "Umeme/Maji", "en": "Utilities"},
  "category_salaries": {"sw": "Mishahara", "en": "Salaries"},
  "category_other": {"sw": "Nyingine", "en": "Other"},
  "expense_period_label": {"sw": "Kipindi", "en": "Period"},
  "period_daily": {"sw": "Kila Siku", "en": "Daily"},
  "period_weekly": {"sw": "Kila Wiki", "en": "Weekly"},
  "period_monthly": {"sw": "Kila Mwezi", "en": "Monthly"},
  "period_one_time": {"sw": "Mara Moja", "en": "One-Time"},
  "amount_label": {"sw": "Kiasi (TZS)", "en": "Amount (TZS)"},
  "description_optional_label": {"sw": "Maelezo (hiari)", "en": "Description (optional)"},
  "expense_date_label": {"sw": "Tarehe ya Gharama", "en": "Expense Date"},
  "save_expense_button": {"sw": "Hifadhi Gharama", "en": "Save Expense"},
  "expense_saved_message": {"sw": "Gharama imehifadhiwa.", "en": "Expense saved."},
  "expense_failed_message": {
    "sw": "Imeshindikana kuhifadhi gharama.",
    "en": "Failed to save expense.",
  },

  // ---------------------------------------------------------------------
  // SALE TYPE (Jumla/Rejareja) - Receipt Create
  // ---------------------------------------------------------------------
  "sale_type_label": {"sw": "Aina ya Uuzaji", "en": "Sale Type"},
  "retail_sale_type": {"sw": "Rejareja", "en": "Retail"},
  "wholesale_sale_type": {"sw": "Jumla", "en": "Wholesale"},
  "selling_price_label": {"sw": "Bei ya Kuuzia (TZS)", "en": "Selling Price (TZS)"},
  "below_cost_warning": {
    "sw": "ONYO: Bei hii iko CHINI ya gharama ya ununuzi - utapata HASARA kwenye mauzo haya.",
    "en": "WARNING: This price is BELOW cost - you will make a LOSS on this sale.",
  },

  // ---------------------------------------------------------------------
  // PROFIT / LOSS (Owner Dashboard + Predictive)
  // ---------------------------------------------------------------------
  "today_profit_loss_title": {"sw": "Faida/Hasara ya Leo", "en": "Today's Profit/Loss"},
  "profit_label": {"sw": "FAIDA", "en": "PROFIT"},
  "loss_label": {"sw": "HASARA", "en": "LOSS"},
  "loss_warning_title": {"sw": "Onyo la Hasara", "en": "Loss Warning"},
  "profit_trend_title": {"sw": "Mwenendo wa Faida", "en": "Profit Trend"},
  "avg_daily_profit_7d_label": {
    "sw": "Wastani wa faida ya siku 7",
    "en": "Average profit (last 7 days)",
  },
  "projected_monthly_label": {
    "sw": "Makadirio ya mwezi kwa kasi ya sasa",
    "en": "Projected for month at current pace",
  },
  "view_profit_loss_report_button": {
    "sw": "Angalia Ripoti Kamili ya Faida/Hasara",
    "en": "View Full Profit/Loss Report",
  },
  "profit_loss_report_title": {"sw": "Ripoti ya Faida/Hasara", "en": "Profit/Loss Report"},
  "revenue_label": {"sw": "Mapato", "en": "Revenue"},
  "cogs_label": {"sw": "Gharama za Bidhaa Zilizouzwa", "en": "Cost of Goods Sold"},
  "gross_profit_label": {"sw": "Faida Ghafi", "en": "Gross Profit"},
  "transport_expenses_label": {"sw": "Gharama za Usafiri", "en": "Transport Expenses"},
  "other_expenses_label": {"sw": "Gharama Nyingine za Uendeshaji", "en": "Other Operating Expenses"},
  "net_profit_label": {"sw": "Faida/Hasara Halisi", "en": "Net Profit/Loss"},
};
