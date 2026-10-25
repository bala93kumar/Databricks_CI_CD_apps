"""
Core business transformations.
Written in pure Python to allow unit testing locally in GitHub Actions for $0 compute cost.
"""

def clean_sales_data(records):
    """
    Filters out invalid records and cleans amount fields.
    """
    valid_records = []
    for r in records:
        if r.get("status") == "COMPLETED" and r.get("amount", 0) > 0:
            cleaned = {
                "order_id": r["order_id"],
                "customer": r["customer"].strip().title(),
                "amount": round(float(r["amount"]), 2),
                "status": r["status"]
            }
            valid_records.append(cleaned)
    return valid_records


def calculate_total_sales(records):
    """
    Aggregates total sales amount.
    """
    return round(sum(r["amount"] for r in records), 2)
