"""
Generates a realistic synthetic e-commerce dataset for the
E-commerce Sales Analysis SQL project.

Produces 4 CSVs (customers, products, orders, order_items) with
seasonal patterns, repeat customers, and realistic price/cost margins,
so every number in the README/queries is computed from real data
(not invented).
"""
import random
import csv
from datetime import date, timedelta
from faker import Faker

random.seed(42)
fake = Faker("en_IN")
Faker.seed(42)

OUT = "/home/claude/ecommerce-sql-analysis/data"

# ---------------------------------------------------------------
# 1. CUSTOMERS
# ---------------------------------------------------------------
N_CUSTOMERS = 4000
CITIES_STATES = [
    ("Mumbai", "Maharashtra"), ("Delhi", "Delhi"), ("Bengaluru", "Karnataka"),
    ("Hyderabad", "Telangana"), ("Pune", "Maharashtra"), ("Kanpur", "Uttar Pradesh"),
    ("Lucknow", "Uttar Pradesh"), ("Jaipur", "Rajasthan"), ("Ahmedabad", "Gujarat"),
    ("Chennai", "Tamil Nadu"), ("Kolkata", "West Bengal"), ("Varanasi", "Uttar Pradesh"),
    ("Indore", "Madhya Pradesh"), ("Nagpur", "Maharashtra"), ("Patna", "Bihar"),
    ("Surat", "Gujarat"), ("Bhopal", "Madhya Pradesh"), ("Chandigarh", "Chandigarh"),
]

customers = []
start_signup = date(2023, 6, 1)
end_signup = date(2025, 11, 30)
signup_range_days = (end_signup - start_signup).days

for cid in range(1, N_CUSTOMERS + 1):
    city, state = random.choice(CITIES_STATES)
    signup_date = start_signup + timedelta(days=random.randint(0, signup_range_days))
    customers.append({
        "customer_id": cid,
        "customer_name": fake.name(),
        "email": f"customer{cid}@example.com",
        "city": city,
        "state": state,
        "signup_date": signup_date.isoformat(),
    })

with open(f"{OUT}/customers.csv", "w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=customers[0].keys())
    w.writeheader()
    w.writerows(customers)

# ---------------------------------------------------------------
# 2. PRODUCTS
# ---------------------------------------------------------------
CATEGORIES = {
    "Electronics": (800, 45000),
    "Fashion": (299, 4500),
    "Home & Kitchen": (199, 12000),
    "Beauty & Personal Care": (99, 2500),
    "Sports & Fitness": (249, 9000),
    "Books": (99, 1200),
    "Grocery": (49, 900),
    "Toys & Baby": (149, 3500),
}

PRODUCT_NAME_WORDS = {
    "Electronics": ["Wireless Earbuds", "Bluetooth Speaker", "Smartwatch", "Power Bank",
                    "LED Monitor", "Mechanical Keyboard", "Wireless Mouse", "USB-C Hub",
                    "Home Theatre System", "Smart LED Bulb", "Laptop Stand", "Webcam HD"],
    "Fashion": ["Cotton Kurta", "Denim Jacket", "Running Shoes", "Leather Wallet",
                "Formal Shirt", "Sunglasses", "Analog Watch", "Backpack", "Sneakers",
                "Woolen Sweater", "Saree", "Ethnic Set"],
    "Home & Kitchen": ["Non-Stick Cookware Set", "Air Fryer", "Mixer Grinder", "Bed Sheet Set",
                       "Table Lamp", "Storage Organizer", "Electric Kettle", "Curtain Set",
                       "Dinner Set", "Vacuum Cleaner", "Water Bottle Set", "Wall Clock"],
    "Beauty & Personal Care": ["Face Wash", "Herbal Shampoo", "Moisturizer", "Lipstick Set",
                               "Trimmer", "Perfume", "Sunscreen SPF50", "Hair Dryer",
                               "Face Serum", "Body Lotion"],
    "Sports & Fitness": ["Yoga Mat", "Dumbbell Set", "Resistance Bands", "Cricket Bat",
                         "Badminton Racket", "Football", "Skipping Rope", "Fitness Tracker",
                         "Gym Bag", "Protein Shaker"],
    "Books": ["Self-Help Book", "Fiction Novel", "Competitive Exam Guide", "Cookbook",
              "Biography", "Children's Story Set", "Programming Guide", "Business Book"],
    "Grocery": ["Basmati Rice 5kg", "Cooking Oil 1L", "Masala Combo Pack", "Green Tea Box",
                "Dry Fruits Pack", "Organic Honey", "Atta 10kg", "Instant Noodles Pack"],
    "Toys & Baby": ["Building Blocks Set", "Remote Control Car", "Soft Toy", "Baby Diaper Pack",
                    "Baby Stroller", "Puzzle Set", "Board Game", "Feeding Bottle Set"],
}

SUFFIXES = ["Pro", "Plus", "Max", "Classic", "Lite", "Elite", "Everyday", "Premium"]

products = []
pid = 1
for category, (lo, hi) in CATEGORIES.items():
    names = PRODUCT_NAME_WORDS[category]
    n_products = 18 if category in ("Electronics", "Fashion", "Home & Kitchen") else 16
    used_names = set()
    for i in range(n_products):
        # guarantee a unique product_name within the category (retry until unused combo found)
        for _ in range(50):
            base_name = random.choice(names)
            brand_suffix = random.choice(SUFFIXES)
            product_name = f"{base_name} {brand_suffix}"
            if product_name not in used_names:
                used_names.add(product_name)
                break
        else:
            product_name = f"{base_name} {brand_suffix} {pid}"  # fallback, should not trigger
            used_names.add(product_name)
        unit_price = round(random.uniform(lo, hi), 2)
        cost_ratio = random.uniform(0.55, 0.80)
        cost_price = round(unit_price * cost_ratio, 2)
        products.append({
            "product_id": pid,
            "product_name": product_name,
            "category": category,
            "unit_price": unit_price,
            "cost_price": cost_price,
        })
        pid += 1

with open(f"{OUT}/products.csv", "w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=products[0].keys())
    w.writeheader()
    w.writerows(products)

N_PRODUCTS = len(products)

# ---------------------------------------------------------------
# 3 & 4. ORDERS + ORDER_ITEMS
# ---------------------------------------------------------------
START = date(2024, 1, 1)
END = date(2025, 12, 31)
TOTAL_DAYS = (END - START).days

N_ORDERS = 23000
ORDER_STATUS_WEIGHTS = [("Delivered", 0.85), ("Cancelled", 0.08), ("Returned", 0.07)]

def seasonal_weight(d: date) -> float:
    """Boost order volume around festive season (Oct-Nov) and mild dip in summer (May-Jun)."""
    m = d.month
    if m in (10, 11):
        return 1.9
    if m == 12:
        return 1.4
    if m in (5, 6):
        return 0.75
    return 1.0

# Precompute per-day weights to sample order dates
day_weights = []
days_list = []
d = START
while d <= END:
    days_list.append(d)
    day_weights.append(seasonal_weight(d))
    d += timedelta(days=1)

# 70% of orders come from a "repeat-customer" pool (30% of customers) to create realistic repeat-purchase behavior
repeat_pool = random.sample(range(1, N_CUSTOMERS + 1), int(N_CUSTOMERS * 0.30))
one_time_pool = [c for c in range(1, N_CUSTOMERS + 1) if c not in repeat_pool]

orders = []
order_items = []
item_id = 1

customer_signup_lookup = {c["customer_id"]: c["signup_date"] for c in customers}

for oid in range(1, N_ORDERS + 1):
    order_date = random.choices(days_list, weights=day_weights, k=1)[0]

    if random.random() < 0.72:
        cust_id = random.choice(repeat_pool)
    else:
        cust_id = random.choice(one_time_pool)

    # don't let order date be before customer signup
    signup = date.fromisoformat(customer_signup_lookup[cust_id])
    if order_date < signup:
        order_date = signup + timedelta(days=random.randint(0, 30))
        if order_date > END:
            order_date = END

    status = random.choices(
        [s for s, _ in ORDER_STATUS_WEIGHTS],
        weights=[w for _, w in ORDER_STATUS_WEIGHTS], k=1
    )[0]

    city, state = random.choice(CITIES_STATES)

    orders.append({
        "order_id": oid,
        "customer_id": cust_id,
        "order_date": order_date.isoformat(),
        "order_status": status,
        "shipping_city": city,
        "shipping_state": state,
    })

    n_items = random.choices([1, 2, 3, 4, 5], weights=[35, 30, 20, 10, 5], k=1)[0]
    chosen_products = random.sample(range(1, N_PRODUCTS + 1), min(n_items, N_PRODUCTS))
    for prod_id in chosen_products:
        qty = random.choices([1, 2, 3, 4], weights=[55, 25, 12, 8], k=1)[0]
        discount_pct = random.choices([0, 5, 10, 15, 20], weights=[45, 20, 15, 12, 8], k=1)[0]
        prod = products[prod_id - 1]
        order_items.append({
            "order_item_id": item_id,
            "order_id": oid,
            "product_id": prod_id,
            "quantity": qty,
            "unit_price": prod["unit_price"],
            "discount_pct": discount_pct,
        })
        item_id += 1

with open(f"{OUT}/orders.csv", "w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=orders[0].keys())
    w.writeheader()
    w.writerows(orders)

with open(f"{OUT}/order_items.csv", "w", newline="", encoding="utf-8") as fh:
    w = csv.DictWriter(fh, fieldnames=order_items[0].keys())
    w.writeheader()
    w.writerows(order_items)

print(f"customers:   {len(customers):,}")
print(f"products:    {len(products):,}")
print(f"orders:      {len(orders):,}")
print(f"order_items: {len(order_items):,}")
