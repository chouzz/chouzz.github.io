---
title: 二分查找-BinraySearch总结
date: 2022-01-04 22:53 +0800
---

## 前言

二分查找(Binary Search)是一种从有序数组中查找某一特定元素的搜索算法。搜索过程从数组的中间元素开始，如果中间元素正好是要查找的元素，则搜索过程结束；如果某一特定元素大于或者小于中间元素，则在数组大于或小于中间元素的那一半中查找，而且跟开始一样从中间元素开始比较。 如果在某一步骤数组为空，则代表找不到。

## 算法实现(python)

while 循环写法

```python

def binary_search(nums: List[int], target: int):
    left = 0
    right = len(nums)-1
    while left <= right:
        mid = left + (right-left) // 2
        if target < nums[mid]:
            right = mid-1
        elif target > nums[mid]:
            left = mid+1
        else:
            return mid
    return -1

```

递归写法

以下是一个简单的二分查找算法的 Python 实现：

```python
def binary_search(arr, target):
    # 定义左右指针
    left = 0
    right = len(arr) - 1

    # 当左右指针没有相遇时循环查找
    while left <= right:
        # 计算中间位置
        mid = (left + right) // 2
        # 如果中间位置的值等于目标值，则找到了目标值，返回该位置
        if arr[mid] == target:
            return mid
        # 如果中间位置的值大于目标值，则在左半部分继续查找
        elif arr[mid] > target:
            right = mid - 1
        # 如果中间位置的值小于目标值，则在右半部分继续查找
        else:
            left = mid + 1

    # 如果没有找到目标值，返回 -1
    return -1
```

上述代码中，`arr` 表示要查找的有序数组，`target` 表示要查找的目标值。算法首先定义左右指针，初始值分别为数组的开头和结尾。然后，算法在每一次循环中计算中间位置，比较中间位置的值和目标值的大小，如果中间位置的值等于目标值，则找到了目标值，返回该位置；如果中间位置的值大于目标值，则在左半部分继续查找；如果中间位置的值小于目标值，则在右半部分继续查找。如果没有找到目标值，返回 -1。

## 优化版

以下是一个稍微优化了一些的二分查找算法的 Python 实现：

```python
def binary_search(arr, target):
    left, right = 0, len(arr) - 1

    while left <= right:
        mid = (left + right) // 2
        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1

    return -1
```

相比之前的实现，这个实现使用了更紧凑的语法，同时还进行了一些微小的调整。具体来说，这个实现：

- 使用了 Python 的多重赋值语法，将 `left` 和 `right` 初始化到同一行。
- 将 `if` 和 `elif` 语句中的比较运算符方向调整了一下，使得 `arr[mid] < target` 和 `arr[mid] > target` 分别对应左半部分和右半部分的查找。
- 将 `if` 语句中的 `return` 改为了 `elif`，避免了不必要的判断。这个改动是安全的，因为如果 `arr[mid] == target`，那么 `if` 语句就会被执行，而不会执行 `elif` 语句。

虽然这些改动对算法的时间复杂度没有影响，但它们可以让代码更加清晰和易读。