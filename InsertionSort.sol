// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

contract InsertionSort {
    function insertionSort(uint[] memory arr) public pure returns (uint[] memory) {
        uint length = arr.length;
        
        for (uint i = 1; i < length; i++) {
            uint key = arr[i];
            uint j = i;
            // j >= 1 to avoid index out of bounds
            while (j >= 1 && arr[j-1] > key) {
                arr[j] = arr[j-1];
                j--;
            }
            arr[j] = key;
        }

        return arr;
    }    
}
