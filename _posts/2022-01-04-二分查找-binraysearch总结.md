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

```python
def binary_search_recursion(nums: List[int], target: int):

    def binary_search(left: int, right: int):
        if right >= left:
            mid = left + (right - left) // 2

            if target < nums[mid]:
                binary_search(left, mid-1)
            elif target > nums[mid]:
                binary_search(mid+1, right)
            else:
                return mid
        return -1
    return binary_search(0, len(nums)-1)
```

## 二分查找的注意事项

- 条件语句`left<=right`,等于号不能掉，否则情况出现的不全
- 当`taget<nums[mid]`的时候，一定要将 mid-1 赋值给 right，不能直接将 mid 赋值给 right，同样赋值给 left 的时候也是一样

## 二分查找的变种

TODO