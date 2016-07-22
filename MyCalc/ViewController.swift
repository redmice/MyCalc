//
//  ViewController.swift
//  MyCalc
//
//  Created by Javier G. Visiedo on 7/2/16.
//  Copyright © 2016 visiedo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    
    /**
     Calculator display
     */

    @IBOutlet private weak var display: UILabel!

    /**
     Display for the operation history
     */
    
    @IBOutlet private weak var operationHistoryDisplay: UILabel!
    
    /**
     Connection to the Model implementing all calculator functions
    */
    private var brain = CalculatorBrain()
    
    /**
     Action triggered when a number button is pressed
     
     It gets the digit from the sender.currentTitle attribute and appends it to the display. 
     If it is the first digit, the display text is just replaced by the number
     
     - parameter sender: UIButton class associated to the button
     */
    
    @IBAction private func calcNumberPressed(sender: UIButton) {
        
        let digit = sender.currentTitle!

        if userIsTypingANumber
        {
            if ((digit != ".") || (digit == "." && display.text!.rangeOfString(".") == nil))    //Allow valid double numbers (i.e. just one "."
            {
                display.text = display.text! + digit
            }
        }
        else
        {
            if digit == "." {
                display.text = "0."
            }
            else {
                display.text = digit
            }
            userIsTypingANumber = true
        }
    }

    /**
     Change the sign of a number when the +/- button is pressed
 
     If the user is in the middle of typing a number, it just changes the display with the corresponding sign, and allows the user to continue. 
     Otherwise it operates on the last element of the stack as any other unary operation
     */
    
    @IBAction private func changeSignPressed(sender: UIButton) {
    
        if userIsTypingANumber {                    //Just change the sign of the number in the display and allow the user to continue
            if (display.text!.rangeOfString("-") == nil) {  //It is possitive. Add a "-" at the begining
                display.text = "-" + display.text!
            }
            else {
                display.text = display.text!.stringByReplacingOccurrencesOfString("-", withString: "")  //It is already negative -> remove the "-"
            }
        }
        else {                                      //Operate on the result on the display
            operate (sender)
        }
    }
    
    
    /**
     Action triggered when an operation button is pressed
     
     It performs the operation requested by calling the method "performOperation" with the required arguments, adding
     the operation, and the = sign, at the end of the operation history display
     
      - parameter sender: UIButton class associated to the operation button
    */
    
    @IBAction private func operate(sender: UIButton) {
       
        if userIsTypingANumber
        {
            brain.setOperand(displayValue!)
            userIsTypingANumber = false
        }
        if let matemathicalSymbol = sender.currentTitle {
            brain.performOperation(matemathicalSymbol)
        }
        displayValue = brain.result
    }
    
    /**
     Resets the calculator to its initial state
     
     Sets the display value to "0", removes all operands from the operandStack, and sets userIsTypingANumer to false
 
    */
 
    @IBAction private func resetCalculator() {
        
        userIsTypingANumber = false
        display.text = "0"
        brain.reset()
        operationHistoryDisplay!.text = " "
    }
    
    /**
     Removes the last digit introduced by the user
     
     If there is no more digits it shows a "0" in the display
    */
    
    @IBAction private func backSpace(sender: UIButton) {
        
        let displayString = display.text!
        let charCount = displayString.characters.count
        
        if ( userIsTypingANumber && (charCount > 0)) {
            if (charCount == 1) {
                display.text = "0"
                userIsTypingANumber = false
            }
            else {
                display.text = String(display.text!.characters.dropLast())
            }
        }
    }
    
    /**
    Indicates if the user is in the middle of typing a number
 
    It is used to control what to do with the display:
     * just append the next digit if the user is in the process of typing a number, or
     * clear the display and start over if e.g. the user pressed enter right before
    */
    
    var userIsTypingANumber = false     //True if the user is in the middle of typing a number
    
    /**
     Computed property for the value shown in the display
     
     * Get: returns the display value string converted into a Double
     * Set: replaces the value displayed by the new value
     
     */
    var displayValue: Double? {
        get {
            return NSNumberFormatter().numberFromString(display.text!)?.doubleValue
        }
        set{
            if (newValue != nil) {
                display.text = "\(newValue!)"
                if !brain.description.isEmpty {
                    let ending = brain.isPartialResult ? " ..." : " ="
                    operationHistoryDisplay!.text = brain.description + ending
                }
            }
            else {
                display.text = " "
            }
            userIsTypingANumber = false
        }
    }
    
}

