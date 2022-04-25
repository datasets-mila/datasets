import csv
import glob
import os

from datalad.api import Dataset
import numpy as np


def print_stats(dataset_path, nparr):
    print(f"Dataset: {dataset_path}")
    if nparr.size:
        print(f"Number of files: {nparr.size}")
        print(f"Sum (M): {nparr.sum() / 1000000}M")
        print(f"Max (M): {nparr.max() / 1000000}M")
        print(f"Min (M): {nparr.min() / 1000000}M")
        print(f"Mean (M): {nparr.mean() / 1000000}M")
        print(f"Std (M): {nparr.std() / 1000000}M")
        print(f"Histogram: {np.histogram(nparr, [0, 10, 100, 1000, 1 * 1000000, 10 * 1000000, 100 * 1000000, 1000 * 1000000, 10000 * 1000000, 100000 * 1000000, 1000000 * 1000000, 1000000 * 1000000 * 1000000])}")
        print(f"Histogram: {np.histogram(nparr, [0, 4 * 1024, 8 * 1024, 16 * 1024, 32 * 1024, 64 * 1024, 128 * 1024, 256 * 1024, 512 * 1024, 1024 * 1024])}")
    else:
        print(f"Empty dataset")


def write_to_csv(writer, dataset_path, nparr):
    row = {'Dataset': dataset_path}
    if nparr.size:
        row["Number of files"] = nparr.size
        row["Sum (M)"] = nparr.sum() / 1000000
        row["Max (M)"] = nparr.max() / 1000000
        row["Min (M)"] = nparr.min() / 1000000
        row["Mean (M)"] = nparr.mean() / 1000000
        row["Std (M)"] = nparr.std() / 1000000
        histogram, bin_edges = np.histogram(nparr, [0, 10, 100,  # B
                                                    1000,  # K
                                                    1 * 1000000, 10 * 1000000, 100 * 1000000,  # M
                                                    1000 * 1000000, 10000 * 1000000, 100000 * 1000000,  # G
                                                    1000000 * 1000000,  # T
                                                    1000000 * 1000000 * 1000000])
        for value, bin_edge in zip(histogram, bin_edges[1:]):
            row[bin_edge] = value
        histogram, bin_edges = np.histogram(nparr, [0, 4 * 1024, 8 * 1024, 16 * 1024, 32 * 1024,  # KB
                                                    64 * 1024, 128 * 1024, 256 * 1024, 512 * 1024,  # KB
                                                    1024 * 1024])  # MB
        for value, bin_edge in zip(histogram, bin_edges[1:]):
            row[bin_edge] = value
    else:
        row["Number of files"] = "Empty dataset"
    writer.writerow(row)


ds = Dataset(".")

datasets_files_mask = {}
subds_paths = []
for path in ds.subdatasets(result_xfm='relpaths'):
    path = path.rstrip('/')
    subds_paths.append(path)
    path += ".var"
    subds_paths.extend(glob.glob(os.path.join(path, "*")))

subds_paths.sort()

sizes = np.zeros((85732287 + 23011954,), np.int64)
filenames = [""] * sizes.size
size_i = 0
for filename in (# ".tmp_processing/compute_files_stats/datasets_files_list",
                 ".tmp_processing/compute_files_stats/datasets_data1_files_list",
                 ):
    print(f"Extracting files info from {filename}")
    with open(filename, errors="ignore") as f:
        line = f.readline()
        while line:
            file_ls_info = [v for v in line.split('\t') if v]
            try:
                size = file_ls_info[0]
                if size.endswith('K'):
                    size = float(size[:-1]) * 1000
                elif size.endswith('M'):
                    size = float(size[:-1]) * 1000000
                elif size.endswith('G'):
                    size = float(size[:-1]) * 1000000000
                elif size.endswith('T'):
                    size = float(size[:-1]) * 1000000000000
                else:
                    size = int(size)
                if size / 1000000 == 128000000.0:
                    # Skipping this file. It is too big
                    raise ValueError("File too big")
                if size == 0.0:
                    # Skipping empty files
                    raise ValueError("File empty")
                if size / 1000000 >= 50000.0:
                    print(f"File looks big: {file_ls_info}")
                sizes[size_i] = size
                filenames[size_i] = file_ls_info[1]
                size_i += 1
            except ValueError as error:
                print(f"Could not parse string as int or float for file info {file_ls_info}: {str(error)}")
            try:
                line = f.readline()
            except UnicodeDecodeError as error:
                print(f"Skipping ling: {error}")
                line = f.readline()

sizes = sizes[:size_i]
filenames = filenames[:size_i]

print(f"Extracted files info for {size_i} files")

for subds_path in subds_paths:
    datasets_files_mask[subds_path] = np.zeros(sizes.shape, dtype=bool)

for i, filename in enumerate(filenames):
    for subds_path in subds_paths:
        if filename.startswith(subds_path+"/scripts/"):
            break
        elif filename.startswith(subds_path+"/"):
            datasets_files_mask[subds_path][i] = 1
            break

print_stats("All datasets", sizes)

for subds_path, mask in datasets_files_mask.items():
    print_stats(subds_path, sizes[mask])

csv_fields = ['Dataset', 'Number of files', 'Sum (M)', 'Max (M)', 'Min (M)', 'Mean (M)', 'Std (M)',
	      0, 10, 100,  # B
              1 * 1000,  # K
              1 * 1000000, 10 * 1000000, 100 * 1000000,  # M
              1 * 1000000000, 10 * 1000000000, 100 * 1000000000,  # G
              1 * 1000000000000,  # T
              1000000 * 1000000000000,  # inf
              0, 4 * 1024, 8 * 1024, 16 * 1024, 32 * 1024,  # KB
              64 * 1024, 128 * 1024, 256 * 1024, 512 * 1024,  # KB
              1024 * 1024]  # MB
with open('files_list_stats.csv', 'w', newline='') as csvf:
    writer = csv.DictWriter(csvf, fieldnames=csv_fields)
    writer.writeheader()

    write_to_csv(writer, "All datasets", sizes)

    for subds_path, mask in datasets_files_mask.items():
        write_to_csv(writer, subds_path, sizes[mask])
