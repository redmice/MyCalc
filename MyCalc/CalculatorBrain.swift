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
        case BinaryOperation (String, (Double, Double)->Double, UInt8, (String, String)->String, Bool)
        case Equals
        
        var description: String {
            get {
                switch self {
                case .Constant(let operand):
                    return "\(operand)"
                case .UnaryOperation (let symbol, _, _, _):
                    return symbol
                case .BinaryOperation(let symbol, _, _, _, _):
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
        
        learnOp(Op.BinaryOperation("×", *, 3, { $0 + " × " + $1 }, true ))
        learnOp(Op.BinaryOperation("÷", /, 3, { $0  + " ÷ " +  $1 }, true ))
        learnOp(Op.BinaryOperation("+", +, 2, { $0 + " + " + $1 }, true ))
        learnOp(Op.BinaryOperation("−", -, 2, { $0 + " − " + $1 }, true ))
        learnOp(Op.BinaryOperation("ʸ√", { pow ( $0, 1/$1 ) }, 1, { $1 + "√" + "(" + $0 + ")"}, false))
        learnOp(Op.BinaryOperation("xʸ", { pow ( $0, $1 ) }, 1, { $0 + "^" + $1 }, false))
        
        learnOp(Op.UnaryOperation("x²", { pow ( $0, 2 ) }, 1) { "(\($0))^2" })
        learnOp(Op.UnaryOperation("x³", { pow ( $0, 3 ) }, 1) { "\(($0))^3" })
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
        accumulatorLeave.updateValue("\(accumulator)")
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
                accumulatorLeave.updateValue(symbol)      //We want to print the constant symbol, not the value
                newOperandEntered = true
            case .UnaryOperation(_, let function, _, _):
                currentSubTree.addNode(accumulatorLeave)
                currentSubTree.updateValue(symbol)
                if expressionTree != nil {
                    expressionTree = currentSubTree
                }
                else {
                    expressionTree!.addNode(currentSubTree)
                }
                currentSubTree = BinaryTree.Empty
                accumulator = function(accumulator)
                //setOperand(accumulator)
            case .BinaryOperation(_, let function, _, _, _):
                if newOperandEntered {          //Operation pressed right after operand: regular process
                    executePendingOperation()   //TODO: Handle insertion in the tree inside executePendingOperation?
                    pendingOperation = PendingBinaryOperationInfo(binaryFunction: function, firstOperand: accumulator)
                    newOperandEntered = false
                    currentSubTree = BinaryTree.Node(accumulatorLeave, symbol, .Empty)
                }
                else {                          //No new operand introduced, the user changed mind and press another operation button
                    if pendingOperation != nil {
                        pendingOperation!.binaryFunction = function     //Just update the operation and keep waiting for the new operand
                        internalProgram.removeLast()
                    }
                    currentSubTree.updateValue(symbol)
                }
            case .Equals:
                executePendingOperation()
            }
        }
        internalProgram.append(symbol)
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
        displayDescriptionStack = ""
        displayDescription = " "
        pendingDescription = nil
        internalProgram.removeAll()
    }
    
    var result: Double{
        get {
            return accumulator
        }
    }
    
    var description: String {
        get {
            displayDescriptionStack = ""
            pendingDescription = nil
            evaluateDescription ("", programStack: internalProgram)
            return displayDescription
        }
    }
    
    private var currentPrecedence: UInt8 = 3
    
    private func evaluateDescription (leftOperand: String, programStack: [AnyObject]) -> String {
        
        var OperandString = leftOperand
        
        if !programStack.isEmpty {
            var remainingOps = programStack
            let op = remainingOps.removeFirst()
            if let operand = op as? Double {
                evaluateDescription("\(operand)", programStack: remainingOps)
            } else if let symbol = op as? String {
                if let operation = knownOperations[symbol] {
                    switch (operation) {
                    case .Constant:
                        evaluateDescription(symbol, programStack: remainingOps)
                    case .UnaryOperation (_, _, _, let formatter):
                        let op = formatter (leftOperand)
                        if pendingDescription != nil {
                            displayDescriptionStack = pendingDescription!.BinaryFunction (pendingDescription!.firstOperand, op)
                            pendingDescription = nil
                        }
                        else {
                            displayDescriptionStack = op
                        }
                        displayDescription = displayDescriptionStack
                        evaluateDescription (displayDescriptionStack, programStack: remainingOps)
                    case .BinaryOperation(_, _, let precedence, let formatter, let leftRightEvaluation):
                        if pendingDescription != nil {
                            if leftRightEvaluation {
                                if  currentPrecedence < precedence {
                                    displayDescriptionStack = "(" + pendingDescription!.BinaryFunction (pendingDescription!.firstOperand, leftOperand) + ")"
                                    displayDescription = formatter (displayDescriptionStack, "")
                                }
                                else {
                                    displayDescriptionStack = pendingDescription!.BinaryFunction (pendingDescription!.firstOperand, leftOperand)
                                    displayDescription = formatter (displayDescriptionStack, "")
                                }
                            }
                            else {
                                displayDescription = pendingDescription!.BinaryFunction (pendingDescription!.firstOperand, formatter (leftOperand, "_"))
                                
                            }
                        }
                        else {
                            displayDescriptionStack = leftOperand
                            displayDescription = formatter (displayDescriptionStack, "")
                            
                        }
                        currentPrecedence = precedence
                        pendingDescription = PendingBinaryDescriptionInfo (firstOperand: displayDescriptionStack, secondOperand: "", BinaryFunction: formatter)
                        
                        evaluateDescription ("", programStack: remainingOps)
                    case .Equals:
                        if pendingDescription != nil {
                            displayDescription = pendingDescription!.BinaryFunction (pendingDescription!.firstOperand, leftOperand)
                            pendingDescription = nil
                        }
                            
                        else {
                            displayDescription += leftOperand
                        }
                        displayDescriptionStack = "(" + displayDescription + ")"
                        evaluateDescription (displayDescriptionStack, programStack: remainingOps)
                    }
                }
            }
        }
        return OperandString
    }
    
    private var displayDescriptionStack = ""
    
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
    private var pendingDescription: PendingBinaryDescriptionInfo?
    
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
    
    private struct PendingBinaryDescriptionInfo {
        var firstOperand: String
        var secondOperand: String
        var BinaryFunction: (String, String) -> String
    }
    
    private var displayBuffer = " "
    private var displayPending = ""
    
    private var expressionTree: BinaryTree<String>?
    private var accumulatorLeave = BinaryTree.Node(.Empty, "", .Empty)
    private var currentSubTree = BinaryTree.Node(.Empty, "", .Empty)
    
}