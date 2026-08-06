import csv
import os
import random
import uuid
from datetime import datetime, timedelta

random.seed()  # non-deterministic: every run = a new incremental batch

try:
    dbutils.widgets.text("catalog", "dev")
    CATALOG = dbutils.widgets.get("catalog")
except NameError:
    # allows running this as a plain .py script too (e.g. via a Job task)
    CATALOG = os.environ.get("CATALOG", "dev")

LANDING_ZONE = f"/Volumes/{CATALOG}/bronze/raw"
BATCH_ID = datetime.now().strftime("%Y%m%d_%H%M%S")

FIRST_NAMES = ["John", "Jane", "Amit", "Priya", "Wei", "Fatima", "Carlos", "Elena", "Tom", "Sara"]
LAST_NAMES = ["Doe", "Smith", "Sharma", "Chen", "Khan", "Garcia", "Rossi", "Kim", "Brown", "Lee"]
CITIES = [("New York", "NY"), ("Los Angeles", "CA"), ("Chicago", "IL"), ("Jaipur", "RJ"), ("Mumbai", "MH")]
CATEGORIES = ["Electronics", "Apparel", "Home", "Sports", "Books"]
REGIONS = ["US", "EU", "APAC"]
COUNTRIES = ["USA", "Germany", "India", "China", "Brazil"]


def write_csv(path, header, rows):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"wrote {len(rows)} rows -> {path}")


def gen_customers(n=1000, dup_rate=0.02, null_email_rate=0.05):
    rows = []
    for i in range(1, n + 1):
        cid = i
        name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
        email = None if random.random() < null_email_rate else f"{name.lower().replace(' ', '.')}@example.com"
        city, state = random.choice(CITIES)
        signup = (datetime(2023, 1, 1) + timedelta(days=random.randint(0, 900))).date().isoformat()
        phone = f"555-{random.randint(1000,9999)}"
        rows.append((cid, name, email, city, state, signup, phone))
        if random.random() < dup_rate:
            rows.append((cid, name, email, city, state, signup, phone))
    return rows


def gen_products(n=500, dup_rate=0.02, null_price_rate=0.04):
    rows = []
    for i in range(1, n + 1):
        pid = i
        name = f"Product {i}"
        category = random.choice(CATEGORIES)
        price = None if random.random() < null_price_rate else round(random.uniform(5, 500), 2)
        supplier_id = random.randint(1, 100)
        rows.append((pid, name, category, price, supplier_id))
        if random.random() < dup_rate:
            rows.append((pid, name, category, price, supplier_id))
    return rows


def gen_suppliers(n=100, null_contact_rate=0.06):
    rows = []
    for i in range(1, n + 1):
        contact = None if random.random() < null_contact_rate else f"supplier{i}@vendor.com"
        rows.append((i, f"Supplier {i}", contact, random.choice(COUNTRIES)))
    return rows


def gen_sales(n=5000, max_customer=1000, max_product=500, null_qty_rate=0.03, orphan_rate=0.02):
    rows = []
    for i in range(1, n + 1):
        sid = str(uuid.uuid4())
        cust = random.randint(1, max_customer + (50 if random.random() < orphan_rate else 0))
        prod = random.randint(1, max_product + (50 if random.random() < orphan_rate else 0))
        qty = None if random.random() < null_qty_rate else random.randint(1, 10)
        amount = round((qty or 1) * random.uniform(5, 500), 2)
        sale_date = (datetime(2024, 1, 1) + timedelta(days=random.randint(0, 550))).date().isoformat()
        region = random.choice(REGIONS)
        rows.append((sid, cust, prod, qty, amount, sale_date, region))
    return rows


def main():
    print(f"Landing zone: {LANDING_ZONE}")
    if not os.path.isdir(f"/Volumes/{CATALOG}/bronze"):
        raise RuntimeError(
            f"/Volumes/{CATALOG}/bronze not found — check the catalog/schema widget "
            f"values match what actually exists (Catalog panel showed dev.bronze)."
        )

    write_csv(f"{LANDING_ZONE}/customers/customers_{BATCH_ID}.csv",
              ["customer_id", "name", "email", "city", "state", "signup_date", "phone"],
              gen_customers())
    write_csv(f"{LANDING_ZONE}/products/products_{BATCH_ID}.csv",
              ["product_id", "product_name", "category", "price", "supplier_id"],
              gen_products())
    write_csv(f"{LANDING_ZONE}/suppliers/suppliers_{BATCH_ID}.csv",
              ["supplier_id", "supplier_name", "contact_email", "country"],
              gen_suppliers())
    write_csv(f"{LANDING_ZONE}/sales/sales_{BATCH_ID}.csv",
              ["sale_id", "customer_id", "product_id", "quantity", "sale_amount", "sale_date", "region"],
              gen_sales())
    print(f"Batch {BATCH_ID} complete.")


if __name__ == "__main__":
    main()