import unittest
from src.transformations import clean_sales_data, calculate_total_sales

class TestTransformations(unittest.TestCase):
    def test_clean_sales_data_filters_incomplete(self):
        raw_data = [
            {"order_id": 1, "customer": " alice ", "amount": 100.50, "status": "COMPLETED"},
            {"order_id": 2, "customer": "bob", "amount": 0.0, "status": "COMPLETED"},
            {"order_id": 3, "customer": "charlie", "amount": 50.0, "status": "CANCELLED"},
        ]
        cleaned = clean_sales_data(raw_data)
        self.assertEqual(len(cleaned), 1)
        self.assertEqual(cleaned[0]["customer"], "Alice")
        self.assertEqual(cleaned[0]["order_id"], 1)
        self.assertEqual(cleaned[0]["amount"], 100.50)

    def test_calculate_total_sales(self):
        data = [
            {"order_id": 1, "customer": "Alice", "amount": 100.50, "status": "COMPLETED"},
            {"order_id": 2, "customer": "Bob", "amount": 25.25, "status": "COMPLETED"},
        ]
        total = calculate_total_sales(data)
        self.assertEqual(total, 125.75)

if __name__ == "__main__":
    unittest.main()
