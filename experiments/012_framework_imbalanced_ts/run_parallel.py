import argparse
import subprocess
from concurrent.futures import ProcessPoolExecutor, as_completed
try:
    from tqdm import tqdm
except ImportError:
    import sys
    print("Please install tqdm: pip install tqdm")
    sys.exit(1)

def run_seed(seed, args):
    cmd = [
        "python", "src/adapted/train.py",
        "--data-path", args.data_path,
        "--output-dir", args.output_dir,
        "--epochs", str(args.epochs),
        "--seed", str(seed)
    ]
    # Suppress stdout/stderr to keep the progress bar clean
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        return seed, False, result.stderr
    return seed, True, ""

def main():
    parser = argparse.ArgumentParser(description="Parallel Runner")
    parser.add_argument("--data-path", type=str, required=True)
    parser.add_argument("--output-dir", type=str, default="weights")
    parser.add_argument("--epochs", type=int, default=200)
    parser.add_argument("--seeds", type=int, default=30)
    parser.add_argument("--workers", type=int, default=8)
    
    parsed_args = parser.parse_args()

    print(f"Starting {parsed_args.seeds} seeds across {parsed_args.workers} parallel workers...")
    
    failed_seeds = []
    with ProcessPoolExecutor(max_workers=parsed_args.workers) as executor:
        futures = {executor.submit(run_seed, s, parsed_args): s for s in range(parsed_args.seeds)}
        
        for future in tqdm(as_completed(futures), total=parsed_args.seeds, desc="Training Progress"):
            seed, success, error = future.result()
            if not success:
                failed_seeds.append((seed, error))

    if failed_seeds:
        print("\nSome seeds failed:")
        for seed, error in failed_seeds:
            print(f"Seed {seed} failed:\n{error}")
    else:
        print("\n✅ All seeds completed successfully!")

if __name__ == "__main__":
    main()
