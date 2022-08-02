#!/usr/bin/env python3
COLORS = 18

indices = list(range(COLORS))

def dist(indices):
    total = 0
    for i in range(len(indices)):
        for j in (range(i+1, len(indices))):
            total += abs(indices[i] - indices[j]) / (i - j) ** 2
        for j in range(0, i):
            total += abs(indices[i] - (indices[j] + len(indices))) / (i - j) **2

    return total

def swap(indices, i, j):
    old = indices[i]
    indices[i] = indices[j]
    indices[j] = old


found_swap = True
current_dist = dist(indices)
while found_swap:
    found_swap = False
    for i in range(COLORS - 1):
        for j in range(i+1, COLORS):
            swap(indices, i, j)
            new_dist = dist(indices)
            if new_dist > current_dist:
                found_swap = True
                current_dist = new_dist
            else:
                swap(indices, j, i)

print(current_dist, indices)
print([i / len(indices) for i in indices])
