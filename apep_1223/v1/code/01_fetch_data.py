"""01_fetch_data.py — Parse FCA Retirement Income Market Data into clean CSVs."""

import openpyxl
import csv
import os
import json

data_dir = "../data"
xlsx_path = os.path.join(data_dir, "rimd_2023-24.xlsx")
assert os.path.exists(xlsx_path), f"Excel file not found: {xlsx_path}"

wb = openpyxl.load_workbook(xlsx_path, read_only=True, data_only=True)

# ============================================================
# Helper: convert sheet to list of lists
# ============================================================
def sheet_to_list(ws):
    rows = []
    for row in ws.iter_rows(values_only=True):
        rows.append(list(row))
    return rows

# ============================================================
# SECTION A: Parse 2018-24 Data Tables
# ============================================================
print("Parsing 2018-24 data...")
rows_1824 = sheet_to_list(wb["2018-24 Data Tables"])

periods_1824 = [
    "H1_2018", "H2_2018", "H1_2019", "H2_2019",
    "H1_2020", "H2_2020", "H1_2021", "H2_2021",
    "H1_2022", "H2_2022", "H1_2023", "H2_2023"
]

pot_sizes = ["<10K", "10-29K", "30-49K", "50-99K", "100-249K", "250K+"]
pot_labels_1824 = [
    "Less than £10,000", "£10,000 - £29,000", "£30,000 - £49,000",
    "£50,000 - £99,000", "£100,000 - £249,000", "£250,000 and above"
]

# Find table start rows by scanning for table labels
def find_row(rows, label):
    for i, row in enumerate(rows):
        for cell in row:
            if cell and isinstance(cell, str) and label in cell:
                return i
    return None

# --- Table 1: Overview ---
t1_row = find_row(rows_1824, "Table 1: Overview")
print(f"Table 1 at row {t1_row}")

# The data structure: each period has a block of columns.
# Row t1_row+3 has the method labels, data in rows t1_row+3 to t1_row+7
# But the layout is complex. Let me find the "Total pots" row.
total_row = None
for i in range(t1_row, min(t1_row + 15, len(rows_1824))):
    for cell in rows_1824[i]:
        if cell and isinstance(cell, str) and "Total pots" in cell:
            total_row = i
            break
    if total_row:
        break

print(f"Total pots row: {total_row}")

# Each period block has: Number, AUA (£000), Number of firms, % of policies, (maybe blank)
# The number column for each period starts at different offsets
# Let me find the pattern by looking at the actual data

# Print the first period's data to understand column layout
if total_row:
    print("Row content around total_row:")
    for offset in range(5):
        row = rows_1824[total_row + offset]
        # Print non-None values with their column indices
        vals = [(j, v) for j, v in enumerate(row) if v is not None]
        print(f"  +{offset}: {vals[:20]}")

# Parse overview
overview = []
if total_row:
    for offset, method in enumerate(["total", "annuity", "drawdown", "ufpls", "full_withdrawal"]):
        row = rows_1824[total_row + offset]
        # Extract numeric values — these are the counts for each period
        nums = []
        for cell in row:
            if isinstance(cell, (int, float)) and cell > 100:  # Filter out percentages
                nums.append(cell)
        # Should have 12 count values (one per period)
        if len(nums) >= 12:
            for p_idx, period in enumerate(periods_1824):
                overview.append({
                    "period": period,
                    "method": method,
                    "count": int(nums[p_idx]) if p_idx < len(nums) else None
                })
        else:
            print(f"  WARNING: {method} has {len(nums)} numeric values (expected 12)")
            # Try alternative: take all numeric values including smaller ones
            all_nums = [cell for cell in row if isinstance(cell, (int, float)) and not isinstance(cell, bool)]
            print(f"  All numerics: {all_nums[:15]}")

print(f"Overview records: {len(overview)}")

# --- Parse pot-size × age tables ---
def parse_potsize_table(rows, table_label, method_name, periods):
    """Parse a table with pot_size rows and period×age columns."""
    start = find_row(rows, table_label)
    if start is None:
        print(f"WARNING: Could not find '{table_label}'")
        return []

    # Find the pot-size data rows (look for "Less than £10,000")
    data_start = None
    for i in range(start, min(start + 10, len(rows))):
        for cell in rows[i]:
            if cell and isinstance(cell, str) and "Less than" in cell:
                data_start = i
                break
        if data_start:
            break

    if not data_start:
        print(f"WARNING: Could not find data start for '{table_label}'")
        return []

    print(f"  {table_label}: data starts at row {data_start}")

    # Each period has 5 columns: Under55, 55-64, 65-74, 75+, All ages
    # Find the column structure by looking at the age header row
    ages = ["Under_55", "55-64", "65-74", "75+", "All"]

    records = []
    for ps_idx in range(6):
        row = rows[data_start + ps_idx]
        # Skip the label in first column(s), then get numeric values
        nums = []
        for cell in row:
            if isinstance(cell, (int, float)) and not isinstance(cell, bool):
                nums.append(cell)

        # Each period contributes 5 values (4 ages + All)
        for p_idx, period in enumerate(periods):
            base = p_idx * 5
            if base + 4 < len(nums):
                all_ages_val = nums[base + 4]
                records.append({
                    "period": period,
                    "pot_size": pot_sizes[ps_idx],
                    "method": method_name,
                    "count": int(all_ages_val) if all_ages_val else 0
                })
                # Also save age detail
                for a_idx, age in enumerate(ages[:4]):
                    if base + a_idx < len(nums):
                        records.append({
                            "period": period,
                            "pot_size": pot_sizes[ps_idx],
                            "method": method_name,
                            "age_group": age,
                            "count": int(nums[base + a_idx]) if nums[base + a_idx] else 0
                        })

    return records

# Parse 2018-24 tables
all_records = []
all_records += parse_potsize_table(rows_1824, "Table 2: Annuity purchases", "annuity", periods_1824)
all_records += parse_potsize_table(rows_1824, "Table 3: Number of pots that entered drawdown", "drawdown", periods_1824)
all_records += parse_potsize_table(rows_1824, "Table 5: Number of pots where first UFPLS", "ufpls", periods_1824)
all_records += parse_potsize_table(rows_1824, "Table 6: Number of plans fully withdrawn", "full_withdrawal", periods_1824)

# ============================================================
# SECTION B: Parse 2015-18 Data Tables
# ============================================================
print("\nParsing 2015-18 data...")
rows_1518 = sheet_to_list(wb["2015-18 Data Tables"])

# Note: H1_2015 has data quality issues per FCA; use H2_2015 onward
periods_1518 = ["H2_2015", "H1_2016", "H2_2016", "H1_2017", "H2_2017"]

all_records += parse_potsize_table(rows_1518, "Table 4: Annuity purchases by pot size", "annuity", periods_1518)
all_records += parse_potsize_table(rows_1518, "Table 5: Number of pots entering drawdown", "drawdown", periods_1518)
all_records += parse_potsize_table(rows_1518, "Table 6: Number of pots where first UFPLS", "ufpls", periods_1518)
all_records += parse_potsize_table(rows_1518, "Table 7: Number of pots fully withdrawn", "full_withdrawal", periods_1518)

# ============================================================
# SECTION C: Write CSV outputs
# ============================================================
print(f"\nTotal records: {len(all_records)}")

# Separate records with and without age detail
records_all_ages = [r for r in all_records if "age_group" not in r]
records_by_age = [r for r in all_records if "age_group" in r]

# Write pot-size × period panel (All ages only)
with open(os.path.join(data_dir, "panel_potsize_method.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["period", "pot_size", "method", "count"])
    writer.writeheader()
    writer.writerows(records_all_ages)

print(f"Wrote panel_potsize_method.csv ({len(records_all_ages)} rows)")

# Write age-detailed panel
with open(os.path.join(data_dir, "panel_age_detail.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["period", "pot_size", "method", "age_group", "count"])
    writer.writeheader()
    writer.writerows(records_by_age)

print(f"Wrote panel_age_detail.csv ({len(records_by_age)} rows)")

# Write overview
with open(os.path.join(data_dir, "overview.csv"), "w", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=["period", "method", "count"])
    writer.writeheader()
    writer.writerows(overview)

print(f"Wrote overview.csv ({len(overview)} rows)")

wb.close()
print("\nData fetch complete.")
