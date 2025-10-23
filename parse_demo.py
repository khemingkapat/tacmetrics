import os
import sys
import pandas as pd
from awpy import Demo


def main():
    if len(sys.argv) < 2:
        print(
            "Usage: python parse_demo_to_csv.py <path_to_demo.dem> [--to_parquet true|false]"
        )
        sys.exit(1)
    demo_path = sys.argv[1]

    # Default to False unless explicitly set
    to_parquet = False
    if len(sys.argv) > 2:
        if sys.argv[2] == "--to_parquet" and len(sys.argv) > 3:
            to_parquet = sys.argv[3].lower() == "true"

    if not os.path.isfile(demo_path):
        print(f"Error: File '{demo_path}' not found.")
        sys.exit(1)

    # Extract just the filename without extension
    demo_name = os.path.splitext(os.path.basename(demo_path))[0]

    # Create output dir next to the demo file (same level as input)
    demo_dir = os.path.dirname(os.path.abspath(demo_path))
    output_dir = os.path.join(demo_dir, demo_name)

    os.makedirs(output_dir, exist_ok=True)

    print(f"📦 Parsing demo: {demo_name}")
    print(f"   Output directory: {output_dir}")
    print(f"   Export format: {'Parquet' if to_parquet else 'CSV'}")

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

        if to_parquet:
            output_path = os.path.join(output_dir, f"{name}.parquet")
            df.to_parquet(output_path, index=False)
        else:
            output_path = os.path.join(output_dir, f"{name}.csv")
            df.to_csv(output_path, index=False)

        print(f"✅ Saved {os.path.basename(output_path)} ({len(df)} rows)")

    print(
        f"\n🎯 Done! All {'Parquet' if to_parquet else 'CSV'} files saved in: {output_dir}"
    )


if __name__ == "__main__":
    main()
