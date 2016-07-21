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
    
    /**
     Enum type containing either an operand or an operation for the calculator
 
     - parameter Operand: Operand introduced in the calculator
     - parameter UnaryOperation: Calculator unary operation: Operation string, unary function
     - parameter BinaryOperation: Calculator binary operation: Operation string, unary function
    */
    private enum Op: CustomStringConvertible
    {
        case Constant(Double)
        case UnaryOperation (String, Double->Double, Double->String)
        case BinaryOperation (String, (Double, Double)->Double, (String, String)->String)
        case Equals
        
        var description: String {
            get {
                switch self {
                case .Constant(let operand):
                    return "\(operand)"
                case .UnaryOperation (let symbol, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _):
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
        
        learnOp(Op.BinaryOperation("×", *) { $0 + " × " + $1 } )
        learnOp(Op.BinaryOperation("÷", /) { $0  + " ÷ " +  $1 } )
        learnOp(Op.BinaryOperation("+", +) { $0 + " + " + $1 } )
        learnOp(Op.BinaryOperation("−", -) { $0 + " − " + $1 } )
        learnOp(Op.BinaryOperation("ʸ√", { pow ( $0, 1/$1 ) }) { $1 + " √ " + $0 })
        learnOp(Op.UnaryOperation("x²", { pow ( $0, 2 ) }) { "\($0)^2" })
        learnOp(Op.UnaryOperation("x³", { pow ( $0, 3 ) }) { "\($0)^3" })
        learnOp(Op.BinaryOperation("xʸ", { pow ( $0, $1 ) }) { $0 + "^" + $1 })
        
        learnOp(Op.UnaryOperation("√", sqrt) { "√\($0)" })
        learnOp(Op.UnaryOperation("∛", { pow ( $0, 1/3 ) }) { "3√\($0)" })
        learnOp(Op.UnaryOperation("cos", cos) { "cos(\($0))" })
        learnOp(Op.UnaryOperation("sin", sin) { "sin(\($0))" })
        learnOp(Op.UnaryOperation("tan", tan) { "cos(\($0))" })
        learnOp(Op.UnaryOperation("⁺/₋", { -$0} ) { "-(\($0))" })
        
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
        newOperandEntered = true
    }
    
    
    /**
     Interface function to the Controller, used to perform the operation indicated
     */

    func performOperation (symbol: String) {
        if let operation = knownOperations[symbol] {
            switch operation {
            case .Constant(let value):
                accumulator = value
                description += symbol + " "
            case .UnaryOperation(_, let function, let formatter):
                description += formatter (accumulator)
                accumulator = function(accumulator)
            case .BinaryOperation(_, let function, let formatter):
                if newOperandEntered {          //New operand available, regular process
                    executePendingOperation()
                    pendingOperation = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator, formatFunction: formatter)
                    newOperandEntered = false
                }
                else {                          //No new operand introduced, the user changed mind and press another operation button
                    if pendingOperation != nil {
                        pendingOperation?.binaryFunction = function     //Just update the operation and keep waiting for the new operand
                    }
                }
                
            case .Equals:
                executePendingOperation()
            }
        }
    }
    
    private func executePendingOperation () {
        if pendingOperation != nil {
            description += pendingOperation!.formatFunction("\(pendingOperation!.firstOperand)", "\(accumulator)")
            accumulator = pendingOperation!.binaryFunction(pendingOperation!.firstOperand, accumulator)
            pendingOperation = nil
            description += " ="
        }
        else {
            //description += pendingOperation!.formatFunction("\(pendingOperation!.firstOperand)", "...")
        }
        isPartialResult = false
    }
    
    /**
    Interface function to the Controller. Resets the calculator to its initial state
    */
    
    func reset () {
        accumulator = 0.0
        pendingOperation = nil
        newOperandEntered = false
        description = " "
    }
    
    var result: Double{
        get {
            return accumulator
        }
    }
    
    /** 
     True when the user has just entered a new operand
     */
    private var newOperandEntered = false
    
    private var isPartialResult = false
    
    private var pendingOperation: PendingBinaryOperationInfo?
    
    /** 
     Holds the information needed to perform a binary operation, while waiting for the 2nd operand
     */
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var formatFunction: (String, String) -> String
    }
    
    var description = " "
}
