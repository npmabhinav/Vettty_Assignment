# Vettty_Assignment
Repository for my Vettty SQL Assessment submission. Includes full MySQL implementation of the provided dataset snapshot, solution queries (Q1–Q8), explanations, and execution screenshots.
# SQL Test – Solutions & Approach (MySQL 8+)

**Author:** <Your Name>  
**Date:** <Submission Date>  
**Source:** Dataset snapshot provided in the assignment PDF.  

This repository contains all SQL solutions for the SQL Test.  
The goal of the test is to demonstrate SQL querying ability, window functions, data handling, and analytical thinking based on the given snapshot of two tables:

- `transactions`
- `items`

---

# 📂 Dataset Description

### **Table: transactions**
Contains purchase information, possible refund timestamps, store details, and transaction amounts.

Columns:
- `buyer_id`
- `purchase_time`
- `refund_time`
- `refund_item` (snapshot column name, though it stores refund timestamp text)
- `store_id`
- `item_id`
- `gross_transaction_value`

### **Table: items**
Contains item metadata.

Columns:
- `store_id`
- `item_id`
- `item_category`
- `item_name`

---

# 📝 Assumptions

✔ Snapshot contains only sample rows; no additional data is implied  
✔ `refund_time IS NOT NULL` means a refunded purchase  
✔ MySQL version is **8.0+** (required for window functions like `ROW_NUMBER()`)  
✔ Transaction timestamps are treated as `DATETIME`  
✔ Refund validity is defined as:  
> refund_time - purchase_time ≤ 72 hours  
(as stated in the assignment)

---

