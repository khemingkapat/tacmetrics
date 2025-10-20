import os
import sys
import pandas as pd
from awpy import Demo


def main():
    if len(sys.argv) != 2:
        print("Usage: python parse_demo_to_csv.py <path_to_demo.dem>")
        sys.exit(1)

    demo_path = sys.argv[1]

    if not os.path.isfile(demo_path):
        print(f"Error: File '{demo_path}' not found.")
        sys.exit(1)

    demo_name = os.path.splitext(os.path.basename(demo_path))[0]
    output_dir = os.path.join(os.getcwd(), demo_name)
    os.makedirs(output_dir, exist_ok=True)

    print(f"📦 Parsing demo: {demo_name}")
    print(f"   Output directory: {output_dir}")

    dem = Demo(demo_path)
    dem.parse()

    data_attrs = {
        "header": dem.header,
        "rounds": dem.rounds,
        "grenades": dem.grenades,
        "kills": dem.kills,
        "damages": dem.damages,
        "bomb": dem.bomb,
        "smokes": dem.smokes,
        "infernos": dem.infernos,
        "shots": dem.shots,
        "ticks": dem.ticks,
    }

    for name, df in data_attrs.items():
        if df is None:
            print(f"⚠️  {name} is None, skipping.")
            continue

        if hasattr(df, "to_pandas"):
            df = df.to_pandas()

        if isinstance(df, dict):
            df = pd.DataFrame([df])

        if not isinstance(df, pd.DataFrame):
            print(f"⚠️  {name} is not a DataFrame, skipping.")
            continue

        csv_path = os.path.join(output_dir, f"{name}.csv")
        df.to_csv(csv_path, index=False)
        print(f"✅ Saved {name}.csv ({len(df)} rows)")

    print(f"\n🎯 Done! All CSVs saved in: {output_dir}")


if __name__ == "__main__":
    main()
