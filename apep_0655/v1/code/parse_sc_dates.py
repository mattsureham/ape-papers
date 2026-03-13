"""Parse Secure Communities activation dates from ICE FOIA PDF."""
import subprocess
import re
import csv
import json
from collections import defaultdict

# Extract text from PDF
result = subprocess.run(
    ['pdftotext', '-layout', '../data/sc_jurisdictions_raw.pdf', '-'],
    capture_output=True, text=True, cwd='.'
)
text = result.stdout

# Split into state blocks
lines = text.split('\n')

# Parse state-by-state
current_state = None
state_data = {}
date_pattern = re.compile(
    r'(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s+\d{4}'
)

# Track current dates and counties for each state
all_records = []

i = 0
while i < len(lines):
    line = lines[i].strip()

    # Detect state header (all caps, no numbers, not a page footer)
    if (line and line.isupper() and len(line) > 2
        and not line.startswith('AILA')
        and 'ACTIVATED' not in line
        and 'PAGE' not in line
        and 'JURISDICTIONS' not in line
        and not any(c.isdigit() for c in line)
        and line not in ['OF', 'AND', 'THE']):

        # Handle multi-word state names
        if line in ['NEW', 'NORTH', 'SOUTH', 'WEST', 'RHODE', 'DISTRICT']:
            # Look ahead for next word
            next_line = lines[i+1].strip() if i+1 < len(lines) else ''
            # These are continuation states
            pass  # Will be handled differently

        current_state = line
        # Handle states that might have special formatting
        if current_state == 'NEW':
            i += 1
            continue

    i += 1

# Better approach: parse the raw text more carefully
# Re-extract with simpler layout
result2 = subprocess.run(
    ['pdftotext', '-raw', '../data/sc_jurisdictions_raw.pdf', '-'],
    capture_output=True, text=True, cwd='.'
)
raw_text = result2.stdout

# Use the layout version but parse more carefully
# The format is: dates appear as headers, counties listed under each date, grouped by state

# Let's use a simpler approach: parse line by line in layout mode
lines = text.split('\n')

# US state names for matching
US_STATES = [
    'ALABAMA', 'ALASKA', 'ARIZONA', 'ARKANSAS', 'CALIFORNIA', 'COLORADO',
    'CONNECTICUT', 'DELAWARE', 'DISTRICT OF COLUMBIA', 'FLORIDA', 'GEORGIA',
    'GUAM', 'HAWAII', 'IDAHO', 'ILLINOIS', 'INDIANA', 'IOWA', 'KANSAS',
    'KENTUCKY', 'LOUISIANA', 'MAINE', 'MARYLAND', 'MASSACHUSETTS', 'MICHIGAN',
    'MINNESOTA', 'MISSISSIPPI', 'MISSOURI', 'MONTANA', 'NEBRASKA', 'NEVADA',
    'NEW HAMPSHIRE', 'NEW JERSEY', 'NEW MEXICO', 'NEW YORK', 'NORTH CAROLINA',
    'NORTH DAKOTA', 'NORTHERN MARIANA ISLANDS', 'OHIO', 'OKLAHOMA', 'OREGON',
    'PENNSYLVANIA', 'PUERTO RICO', 'RHODE ISLAND', 'SOUTH CAROLINA',
    'SOUTH DAKOTA', 'TENNESSEE', 'TEXAS', 'U.S. VIRGIN ISLANDS', 'UTAH',
    'VERMONT', 'VIRGINIA', 'WASHINGTON', 'WEST VIRGINIA', 'WISCONSIN', 'WYOMING'
]

# Parse blocks: each state starts with its name, then has dates and counties
# We need to find each date and the counties associated with it

current_state = None
current_dates = []  # list of (date_str, column_position)
records = []

# Month names for date detection
months = ['January', 'February', 'March', 'April', 'May', 'June',
          'July', 'August', 'September', 'October', 'November', 'December']

def find_dates_in_line(line):
    """Find all dates and their positions in a line."""
    dates = []
    for m in re.finditer(r'((?:January|February|March|April|May|June|July|August|September|October|November|December)\s+\d{1,2},\s+\d{4})', line):
        dates.append((m.group(1), m.start()))
    return dates

def find_counties_in_line(line):
    """Find potential county names and their positions."""
    counties = []
    # Split by multiple spaces (county names are separated by whitespace)
    parts = re.split(r'\s{2,}', line.strip())
    pos = 0
    for part in parts:
        part = part.strip()
        if part and not re.match(r'^(January|February|March|April|May|June|July|August|September|October|November|December)\s+\d', part):
            if not re.match(r'^\d+\s+of\s+\d+$', part) and part != '100%':
                # Find actual position in original line
                idx = line.find(part, pos)
                counties.append((part, idx if idx >= 0 else pos))
                pos = idx + len(part) if idx >= 0 else pos + len(part)
    return counties

# Process the layout text
# Strategy: for each state, collect all date-county associations
# Dates appear in date lines, counties appear in subsequent lines at similar column positions

i = 0
while i < len(lines):
    line = lines[i]
    stripped = line.strip()

    # Check for state header
    found_state = None
    for st in US_STATES:
        if stripped == st:
            found_state = st
            break

    if found_state:
        current_state = found_state
        current_dates = []
        i += 1
        continue

    if current_state is None:
        i += 1
        continue

    # Skip metadata lines
    if any(x in stripped for x in ['of', '100%', 'AILA', 'Activated Jurisdictions', 'Page']):
        if re.match(r'^\d+\s+of\s+\d+$', stripped) or stripped == '100%':
            i += 1
            continue
        if 'AILA' in stripped or 'Activated Jurisdictions' in stripped or 'Page' in stripped:
            i += 1
            continue

    # Find dates in this line
    dates_found = find_dates_in_line(line)
    if dates_found:
        current_dates = dates_found
        # Also check for county names on the same line (after dates)
        # Counties might appear on lines with dates at different column positions
        # We'll check the line for both

    # Check for county names
    if current_state and current_dates:
        # Find county-like words in this line
        # Counties are at similar column positions as their date headers
        parts = re.split(r'\s{2,}', line)
        for part_raw in parts:
            part = part_raw.strip()
            if not part:
                continue
            # Skip dates, numbers, metadata
            if re.match(r'^(January|February|March|April|May|June|July|August|September|October|November|December)', part):
                continue
            if re.match(r'^\d+\s+of\s+\d+$', part) or part == '100%':
                continue
            if 'AILA' in part or 'Activated' in part or 'Page' in part:
                continue
            if part in US_STATES:
                continue

            # This looks like a county name
            # Find which date column it belongs to based on position
            part_pos = line.find(part)

            # Find closest date by column position
            best_date = None
            best_dist = float('inf')
            for date_str, date_pos in current_dates:
                dist = abs(part_pos - date_pos)
                if dist < best_dist:
                    best_dist = dist
                    best_date = date_str

            if best_date and len(part) > 1:
                # Clean up county name
                county = part.strip()
                # Remove trailing/leading special chars
                county = re.sub(r'^[^a-zA-Z]+', '', county)
                county = re.sub(r'[^a-zA-Z\s\.\'-]+$', '', county)
                if county and len(county) > 1:
                    records.append({
                        'state': current_state.title(),
                        'county': county,
                        'activation_date': best_date
                    })

    i += 1

# Deduplicate
seen = set()
unique_records = []
for r in records:
    key = (r['state'], r['county'])
    if key not in seen:
        seen.add(key)
        unique_records.append(r)

# Write CSV
with open('../data/sc_activation_dates.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['state', 'county', 'activation_date'])
    writer.writeheader()
    writer.writerows(unique_records)

print(f"Parsed {len(unique_records)} unique county-activation records")
print(f"States covered: {len(set(r['state'] for r in unique_records))}")

# Show distribution by year
from collections import Counter
years = Counter()
for r in unique_records:
    year = r['activation_date'].split(',')[-1].strip()
    years[year] += 1
print("\nActivation distribution by year:")
for y in sorted(years.keys()):
    print(f"  {y}: {years[y]} counties")

# Show first few
print("\nFirst 20 records:")
for r in unique_records[:20]:
    print(f"  {r['state']}: {r['county']} -> {r['activation_date']}")
