import os
import random
import shutil
import hydra
from pathlib import Path
from omegaconf import DictConfig

def create_directories(validation_path, test_path):
    """Create validation and test directories if they don't exist."""
    Path(validation_path).mkdir(parents=True, exist_ok=True)
    Path(test_path).mkdir(parents=True, exist_ok=True)

def get_existing_file_numbers(directory):
    """Get list of existing file numbers from the filenames."""
    numbers = []
    for filename in os.listdir(directory):
        if filename.startswith("graph_partitions_") and filename.endswith(".bin"):
            try:
                num = int(filename.replace("graph_partitions_", "").replace(".bin", ""))
                numbers.append(num)
            except ValueError:
                continue
    return sorted(numbers)

def split_dataset(partitions_path, validation_partitions_path, test_partitions_path, val_ratio=0.1, test_ratio=0.1, seed=42):
    """
    Split the dataset into training, validation, and test sets.
    
    Args:
        partitions_path: The training partitions directory, which should contain all samples before running
        validation_partitions_path: The validation partitions directory, will be created if it doesn't exist
        test_partitions_path: The test partitions directory, will be created if it doesn't exist
        val_ratio: Ratio of validation set (default: 0.1)
        test_ratio: Ratio of test set (default: 0.1)
        seed: Random seed for reproducibility
    """
    random.seed(seed)
    
    # Create necessary directories
    create_directories(validation_partitions_path, test_partitions_path)
    
    # Source directory
    src_dir = partitions_path
    
    # Get list of existing file numbers
    file_numbers = get_existing_file_numbers(src_dir)
    total_files = len(file_numbers)
    
    # Calculate split sizes
    test_size = int(total_files * test_ratio)
    val_size = int(total_files * val_ratio)
    
    # Randomly select files for test and validation sets
    random.shuffle(file_numbers)
    test_numbers = set(file_numbers[:test_size])
    val_numbers = set(file_numbers[test_size:test_size + val_size])
    
    # Move files to appropriate directories
    for num in file_numbers:
        filename = f"graph_partitions_{num}.bin"
        src_file = os.path.join(src_dir, filename)
        
        if num in test_numbers:
            dest_dir = test_partitions_path
        elif num in val_numbers:
            dest_dir = validation_partitions_path
        else:
            continue  # Skip files that should remain in training set
            
        shutil.move(src_file, os.path.join(dest_dir, filename))
    
    # Print summary
    print(f"Dataset split complete:")
    print(f"Training set: {total_files - test_size - val_size} files")
    print(f"Validation set: {val_size} files")
    print(f"Test set: {test_size} files")

# Usage
@hydra.main(version_base="1.3", config_path="conf", config_name="config")
def main(cfg: DictConfig) -> None:
    split_dataset(cfg.partitions_path, cfg.validation_partitions_path, cfg.test_partitions_path, val_ratio=cfg.val_ratio, test_ratio=cfg.test_ratio)


if __name__ == "__main__":
    main()