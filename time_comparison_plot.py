import os
import re
import matplotlib.pyplot as plt
import numpy as np

def extract_time_from_log(content):
    """Extract the wall clock time from the log content. Return 3600 if timeout."""
    if "STATUS: TIMEOUT" in content:
        return 3600.0
    match = re.search(r"Pono wall clock time \(s\): (\d+\.\d+)", content)
    if match:
        return float(match.group(1))
    return 3600.0  # Default to timeout if no time is found

def read_log_files(directory):
    """Read all log files in the given directory and extract times."""
    times = {}
    for filename in os.listdir(directory):
        if filename.endswith("_log.txt"):
            filepath = os.path.join(directory, filename)
            with open(filepath, 'r') as file:
                content = file.read()
                times[filename] = extract_time_from_log(content)
    return times

def main():
    baseline_dir = "pono_baseline_solver_logs"
    ic3ng_dir = "pono_ic3ng_bzla_solver_logs"
    
    # Read times from both directories
    baseline_times = read_log_files(baseline_dir)
    ic3ng_times = read_log_files(ic3ng_dir)
    
    # Pair the times for common files
    common_files = set(baseline_times.keys()) & set(ic3ng_times.keys())
    
    # print the number of common files
    print(f"Number of common files: {len(common_files)}")
    x_data = np.array([baseline_times[f] for f in common_files])
    y_data = np.array([ic3ng_times[f] for f in common_files])
    
    # Determine colors based on whether ic3ng is faster or slower
    colors = np.where(y_data < x_data, 'green', 'red')
    
    # Create a square figure
    plt.figure(figsize=(8, 8))
    
    # Scatter plot of the times with conditional coloring
    plt.scatter(x_data, y_data, alpha=0.5, c=colors, label='Test Cases')
    
    # Plot y=x line
    plt.plot([0.1, 3600], [0.1, 3600], 'black', linestyle='--', label='y=x')
    
    # Set labels and title
    plt.xlabel('Pono Baseline Time (seconds)')
    plt.ylabel('Pono IC3NG Time (seconds)')
    plt.title('Comparison of Execution Times: Pono Baseline vs IC3NG\n(Green: IC3NG faster, Red: IC3NG slower)')
    
    # Set logarithmic scale for both axes to handle sparsity
    plt.xscale('log')
    plt.yscale('log')
    
    # Set axis limits
    plt.xlim(0.1, 3600)
    plt.ylim(0.1, 3600)
    
    # Add legend
    plt.legend()
    
    # Add grid for better readability
    plt.grid(True, linestyle='--', alpha=0.7, which='both')
    
    # Save and show the plot
    plt.savefig('time_comparison_plot.png')
    plt.show()
    
    print(f"Plot saved as 'time_comparison_plot.png'")
    print(f"Number of test cases plotted: {len(common_files)}")

if __name__ == "__main__":
    main()
