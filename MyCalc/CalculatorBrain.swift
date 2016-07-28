//
//  CalculatorBrain.swift
//  MyCalc
//
//  Created by Javier G. Visiedo on 7/9/16.
//  Copyright © 2016 visiedo. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    private var accumulator = 0.0
    
    private var internalProgram = [AnyObject]()
    
    /**
     Enum type containing either an operand or an operation for the calculator
 
     - parameter Operand: Operand introduced in the calculator
     - parameter UnaryOperation: Calculator unary operation: Operation string, unary function
     - parameter BinaryOperation: Calculator binary operation: Operation string, binary function
    */
    private enum Op: CustomStringConvertible
    {
        case Constant(Double)
        case UnaryOperation (String, Double->Double, UInt8, String->String)
        case BinaryOperation (String, (Double, Double)->Double, UInt8, (String, String)->String)
        case Equals
        
        var description: String {
            get {
                switch self {
                case .Constant(let operand):
                    return "\(operand)"
                case .UnaryOperation (let symbol, _, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _, _):
                    return symbol
                case .Equals:
                    return "="
                }
            }
        }
    }
    
    /**
    Dictionary containing all known operations. It contains pairs of descriptive string and an element of the Op enum
     */
    
    private var knownOperations = [String:Op]()
    
    init(){
        /**
         Local function to the init() method, used to introduce elements in the dictionary, based on the description of the enum
        */
        func learnOp(op: Op) {
            knownOperations[op.description] = op
        }
        
        learnOp(Op.BinaryOperation("×", *, 3) { $0 + " × " + $1 } )
        learnOp(Op.BinaryOperation("÷", /, 3) { $0  + " ÷ " +  $1 } )
        learnOp(Op.BinaryOperation("+", +, 2) { $0 + " + " + $1 } )
        learnOp(Op.BinaryOperation("−", -, 2) { $0 + " − " + $1 } )
        learnOp(Op.BinaryOperation("ʸ√", { pow ( $0, 1/$1 ) }, 1) { $1 + "√" + "(" + $0 + ")"})
        learnOp(Op.UnaryOperation("x²", { pow ( $0, 2 ) }, 1) { "(\($0))^2" })
        learnOp(Op.UnaryOperation("x³", { pow ( $0, 3 ) }, 1) { "\(($0))^3" })
        learnOp(Op.BinaryOperation("xʸ", { pow ( $0, $1 ) }, 1) { $0 + "^" + $1 })
        
        learnOp(Op.UnaryOperation("√", sqrt, 1) { "√\($0)" })
        learnOp(Op.UnaryOperation("∛", { pow ( $0, 1/3 ) }, 1) { "3√(\($0))" })
        learnOp(Op.UnaryOperation("cos", cos, 1) { "cos(\($0))" })
        learnOp(Op.UnaryOperation("sin", sin, 1) { "sin(\($0))" })
        learnOp(Op.UnaryOperation("tan", tan, 1) { "cos(\($0))" })
        learnOp(Op.UnaryOperation("⁺/₋", { -$0}, 1) { "-(\($0))" })
        
        knownOperations["="] = Op.Equals
        
        //Constants: handled as operations. Introduce the corresponding operand into the stack
        knownOperations["π"] = Op.Constant(M_PI)
        knownOperations["e"] = Op.Constant(M_E)
    }
    
    /**
    Interface function to the Controller, used to introduce a new Operand in the accumulator
    */
    func setOperand (operand: Double) {
        accumulator = operand
        internalProgram.append(operand)
        newOperandEntered = true
    }
    
    
    /**
     Interface function to the Controller, used to perform the operation indicated
     */

    func performOperation (symbol: String) {
        internalProgram.append(symbol)
        if let operation = knownOperations[symbol] {
            switch operation {
            case .Constant(let value):
                accumulator = value
                newOperandEntered = true
            case .UnaryOperation(_, let function, _, _):
                accumulator = function(accumulator)
                //setOperand(accumulator)
            case .BinaryOperation(_, let function, _, _):
                if newOperandEntered {          //New operand available, regular process
                    executePendingOperation()
                    pendingOperation = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator)
                    newOperandEntered = false
                }
                else {                          //No new operand introduced, the user changed mind and press another operation button
                    if pendingOperation != nil {
                        pendingOperation!.binaryFunction = function     //Just update the operation and keep waiting for the new operand
                    }
                }
                
            case .Equals:
                executePendingOperation()
            }
        }
    }
    
    private func executePendingOperation () {
        if pendingOperation != nil {
            accumulator = pendingOperation!.binaryFunction(pendingOperation!.firstOperand, accumulator)
            pendingOperation = nil
        }
    }
    
    /**
    Interface function to the Controller. Resets the calculator to its initial state
    */
    
    func reset () {
        accumulator = 0.0
        pendingOperation = nil
        newOperandEntered = false
        displayDescription = " "
        displayPending = ""
        internalProgram.removeAll()
    }
    
    var result: Double{
        get {
            return accumulator
        }
    }
    
    var description: String {
        get {
            displayDescription = ""
            evaluateDescription ()
            return displayDescription
        }
    }
    
    private func evaluateDescription () {
        var currentOperand = ""
        var leftOperand = ""
        var displayBuffer = ""
        var binaryFormatter: ((String, String) -> String)?
        var currentPrecedence: UInt8 = 3

        
        for op in internalProgram {
            if let operand = op as? Double {
                currentOperand = "\(operand)"
                if leftOperand == "" {
                    leftOperand = currentOperand
                }
            } else if let symbol = op as? String {
                if let operation = knownOperations[symbol] {
                    switch (operation) {
                    case .Constant:
                        currentOperand = symbol
                    case .UnaryOperation (_, _, _, let formatter):
                        currentOperand = formatter (currentOperand)
                        if binaryFormatter != nil {
                            leftOperand = binaryFormatter! (leftOperand, currentOperand)
                            binaryFormatter = nil
                        }
                        else {
                            leftOperand = currentOperand
                        }
                        displayBuffer = leftOperand
                    case .BinaryOperation(let symbol, _, let precedence, let formatter):
                        
                        if symbol != "" {
                            if binaryFormatter != nil {
                                leftOperand = binaryFormatter! (leftOperand, currentOperand)
                            }
                            if currentPrecedence < precedence {
                                leftOperand = "(" + leftOperand + ")"
                            }
                            displayBuffer = leftOperand + " " + symbol
                            currentPrecedence = precedence
                            binaryFormatter = formatter
                        }
                        else {
                            
                            
                        }
                    case .Equals:
                        if binaryFormatter != nil {
                            displayBuffer = binaryFormatter!(leftOperand, currentOperand)
                            binaryFormatter = nil
                        }
                        currentOperand = "(" + displayBuffer + ")"
                    }
                }
            }
        }
        displayDescription = displayBuffer
    }
    
    private var displayDescription = ""
    
    var isPartialResult: Bool {
        get {
            return pendingOperation != nil
        }
    }
    
    typealias PropertyList = AnyObject
    
    var program: PropertyList {
        get {
            return internalProgram
        }
        set {
            reset()
            if let arrayOfOps = newValue as? [AnyObject]{
                for op in arrayOfOps {
                    if let operand = op as? Double {
                        setOperand(operand)
                    } else if let operation = op as? String {
                        performOperation(operation)
                    }
                }
            }
        }
    }
    
    private var pendingOperation: PendingBinaryOperationInfo?
    
    /** 
     True when the user has just entered a new operand
     */
    private var newOperandEntered = false
    
    /** 
     Holds the information needed to perform a binary operation, while waiting for the 2nd operand
     */
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
    }
    
    private var displayBuffer = " "
    private var displayPending = ""
}
