//
//  BinaryTree.swift
//  MyCalc
//
//  Generic implementation of a Binary Tree using a recursive enum
//
//  Created by Javier Garcia Visiedo on 8/2/16.
//  Copyright © 2016 visiedo. All rights reserved.
//

import Foundation

indirect enum BinaryTree<T>: CustomStringConvertible {
    case Node (BinaryTree<T>, T, BinaryTree<T>)
    case Empty
    
    var description: String {
        get {
            switch self{
            case .Node (let left, let value, let right):
                return "Value: \(value), left = [" + left.description + "], right = [" + right.description + "]"
            case .Empty:
                return ""
            }
        }
    }
    
    var count: Int {
        get {
            switch self {
            case .Node (let left, _, let right):
                return left.count + 1 + right.count
            case .Empty:
                return 0
            }
        }
    }
    
    func addNode (node: BinaryTree) -> Bool {
        var result = false          //Error: could not insert
        if case var .Node (left, value, right) = self {
            if case .Empty = left {
                left = node
                result = true
            } else if case .Empty = right {
                right = node
                result = true
            }
        }
        return result
    }
    
    func updateValue (newValue: T) -> Bool {
        var result = false          //Error: could not insert
        if case var .Node (_, value, _) = self {
            value = newValue
            result = true
        }
        return result
    }

    
    func traverseInOrder(process: T->Void) {
        if case let .Node(left, value, right) = self {
            left.traverseInOrder(process)
            process(value)
            right.traverseInOrder(process)
        }
    }
    
    func traversePreOrder(process: T->Void) {
        if case let .Node(left, value, right) = self {
            process(value)
            left.traversePreOrder(process)
            right.traversePreOrder(process)
        }
    }
    
    func traversePostOrder(process: T->Void) {
        if case let .Node(left, value, right) = self {
            left.traversePostOrder(process)
            right.traversePostOrder(process)
            process(value)
        }
    }
}
