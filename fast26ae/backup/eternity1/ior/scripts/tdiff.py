import re
import sys
import socket
import numpy as np

def process_log_file(file_path, total_time):
    try:
        with open(file_path, 'r') as file:
            log_data = file.readlines()
        
        lock_time_values = []
        for line in log_data:
            lock_match = re.search(r'tdiff:(\d+)', line)
            if lock_match:
                lock_time_values.append(int(lock_match.group(1)))
        
        if lock_time_values:
            lock_sum = sum(lock_time_values)
            lock_avg = lock_sum / len(lock_time_values)
            lock_ratio = (lock_sum / 1000) / (total_time / 1000) * 100
            fs_ratio = 100.0 - lock_ratio
            
            print(f"DLM-side latency ratio: {lock_ratio:.2f}%")
            print(f"FS-side latency ratio: {fs_ratio:.2f}%")
            
            lock_time_values_us = np.array([value / 1000 for value in lock_time_values])
            
            bin_width = 20
            max_range = 200
            bins = [(i, i+bin_width) for i in range(0, max_range, bin_width)]
            histogram = {i: 0 for i in range(0, max_range, bin_width)}
            
            for value in lock_time_values_us:
                if value < max_range:
                    bin_start = int(value // bin_width) * bin_width
                    histogram[bin_start] += 1
            
            print("\nLock Time Distribution (PDF):")
            total_locks = len(lock_time_values)
            if total_locks > 0:
                for bin_start, bin_end in bins:
                    probability = histogram.get(bin_start, 0) / total_locks
                    print(f"  {bin_start}-{bin_end}us: {probability:.4f}")
        else:
            print("no lock_time found")
    
    except FileNotFoundError:
        print(f"FileNotFoundError: {file_path}")
    except PermissionError:
        print(f"PermissionError: {file_path}")
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 tdiff.py <total_time_in_ns>")
        sys.exit(1)
        
    try:
        total_time = float(sys.argv[1])
    except ValueError:
        print("Error: total_time_in_ns must be a number.")
        sys.exit(1)
        
    file_path = "/sys/kernel/debug/tracing/trace"
    process_log_file(file_path, total_time)
