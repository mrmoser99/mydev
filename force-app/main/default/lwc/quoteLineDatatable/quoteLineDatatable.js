/**
 *******************************************************************************
 * quoteLineDatatable
 * @description Contains all logic related to a specific quote list view in the proposal tab of price quote page
 * @author Shiqi Sun, Traction on Demand
 * @date 2021-12-01
 * 
 * 07/13/2022 - Make $ right aligned like they are in every screen in a billion customer sites
 * 02/02/2023 - Modified to make response in appeal mode to change lables and button name
 ***************************************************************************************************************
 */

import {LightningElement, api} from 'lwc';

//{cellAttributes: {alignment: insertProperValueHere}} 

const COLUMS = [
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'left'}, label: 'Asset Number', fieldName: 'assetNumber', type: 'text', hideDefaultActions:true,  initialWidth: 50},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'left'}, label: 'Asset Detail', fieldName: 'Make__c', type: 'text', hideDefaultActions:true},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'right'}, label: 'QTY', fixedWidth: 50, fieldName: 'Number_of_Units__c', type:'number', hideDefaultActions:true,  initialWidth: 50},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'right'}, label: 'Unit Sales Price', fixedWidth: 115, fieldName: 'Base_Unit_Sales_Price__c', type: 'currency', hideDefaultActions:true,  initialWidth: 100},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'right'}, label: 'Total Price', fixedWidth: 120, fieldName: 'Total_Sales_Price_Base__c', type: 'currency', hideDefaultActions:true,  initialWidth: 100},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'right'}, label: 'Hours', fieldName: 'Annual_Hours__c', type: 'number', hideDefaultActions:true,  initialWidth: 60},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'left'}, label: 'Environment', fieldName: 'Operating_Environment__c', type: 'text', hideDefaultActions:true},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'left'}, label: 'Finance Type', fieldName: 'financeType', type: 'text', hideDefaultActions:true},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'left'}, label: 'Term', fieldName: 'finance_term', type: 'number', hideDefaultActions:true,  initialWidth: 50},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'left'}, label: 'Rate Type', fixedWidth: 120, fieldName: 'rateType', type: 'text', hideDefaultActions:true},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'right'}, label: 'Interest Rate', fieldName: 'interestRate', type: 'text', hideDefaultActions:true, initialWidth: 70, typeAttributes: {step: '0.01', minimalFractionDigits: 2, maximumFractionDigits: 2}},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'right'}, label: 'Residual', fieldName: 'closeAt', type: 'currency', hideDefaultActions:true},
    {cellAttributes: {class:{fieldName:'groupByAsset'}, alignment: 'right'}, label: 'Payment', fieldName: 'payment', type: 'currency', hideDefaultActions:true}
];

const COLUMSSUMMARY = [
    {cellAttributes: {alignment: 'left', class: 'slds-color__background_gray-7'}, fieldName: 'assetNumber', type: 'text', hideDefaultActions:true,  initialWidth: 50},
    {cellAttributes: {alignment: 'left', class: 'slds-color__background_gray-7'}, fieldName: 'Make__c', type: 'text', hideDefaultActions:true},
    {cellAttributes: {alignment: 'right', class: 'slds-color__background_gray-7'}, fieldName: 'Number_of_Units__c', type:'number', hideDefaultActions:true,  initialWidth: 50},
    {cellAttributes: {alignment: 'right', class: 'slds-color__background_gray-7'}, fieldName: 'Base_Unit_Sales_Price__c', fixedWidth: 115,type: 'currency', hideDefaultActions:true,  initialWidth: 100},
    {cellAttributes: {alignment: 'right', class: 'slds-color__background_gray-7'}, fieldName: 'Amount__c', fixedWidth: 120, type: 'currency', hideDefaultActions:true,  initialWidth: 100},
    {cellAttributes: {alignment: 'right', class: 'slds-color__background_gray-7'}, fieldName: 'Annual_Hours__c', type: 'number', hideDefaultActions:true,  initialWidth: 60},
    {cellAttributes: {alignment: 'left', class: 'slds-color__background_gray-7'}, fieldName: 'Operating_Environment__c', type: 'text', hideDefaultActions:true},
    {cellAttributes: {alignment: 'left', class: 'slds-color__background_gray-7'}, fieldName: 'financeType', type: 'text', hideDefaultActions:true},
    {cellAttributes: {alignment: 'left', class: 'slds-color__background_gray-7'}, fieldName: 'finance_term', type: 'number', hideDefaultActions:true,  initialWidth: 50},
    {cellAttributes: {alignment: 'left', class: 'slds-color__background_gray-7'}, fieldName: 'rateType',  fixedWidth: 120,type: 'text', hideDefaultActions:true},
    {cellAttributes: {alignment: 'right', class: 'slds-color__background_gray-7'}, fieldName: 'interestRate', type: 'text', hideDefaultActions:true, initialWidth: 70, typeAttributes: {step: '0.01', minimalFractionDigits: 2, maximumFractionDigits: 2}},
    {cellAttributes: {alignment: 'right', class: 'slds-color__background_gray-7'}, fieldName: 'closeAt', type: 'currency', hideDefaultActions:true},
    {cellAttributes: {alignment: 'right', class: 'slds-color__background_gray-7'}, fieldName: 'payment', type: 'currency', hideDefaultActions:true}
];

export default class QuoteLineDatatable extends LightningElement {
    @api option = {}; 
    @api columns = COLUMS;
    columnsSum = COLUMSSUMMARY;
    @api optionsSum = [];
    @api mode;

    isCCMode = false;

    inCCMode = false;
    onlyCallbackOnce = false;
    isProposalChecked = false;
    isCreditAppChecked;
        /*[ {
        'totalPrice' : 20000,
        'interestRate' : 0.1000026,
        'closeAt' : 1234.56,
        'payment' : 432.10
    } ];*/

    connectedCallback() {

         
        if (this.mode == 'cc'){
            this.isCCMode = true;
        }
        else{
            this.isCCMode = false;
        }
        if (this.onlyCallbackOnce) {
            return;
        }
        this.onlyCallbackOnce = true;
        
        if (this.option.quote.Include_In_Proposal__c) {
            this.isProposalChecked = true;
        }

     
        
        if (typeof this.option.quote.Current_Credit_App_Selection__c === 'undefined') {
            this.option.quote.Current_Credit_App_Selection__c = false;
        }

        if (this.option.quote.Current_Credit_App_Selection__c == true) {
            this.isCreditAppChecked = true;
        }
        else{
            this.isCreditAppChecked = false;
        }

        /*if (this.option.quoteLines && this.option.quoteLines.forEach) {
            this.option.quoteLines.forEach(ele => {
                ele.groupByAsset = ((parseInt(ele.assetNumber) % 2) === 0) ? 'slds-color__background_gray-7' : '';
            });
        }*/
    }

    handleCreditAppRadio(event) {

        const eventForAppeal = new CustomEvent("optionselected", {
            detail: {quoteId :this.creditAppId,
                    oppId : this.oppid }
        });

        console.log('is credit app checked b1 : ' + this.isCreditAppChecked);

        if (this.isCreditAppChecked){
            this.isCreditAppChecked = false;
//            this.option.quote.Current_Credit_App_Selection__c = false;
        }
        else{
            this.isCreditAppChecked = true;
            //this.option.quote.Current_Credit_App_Selection__c = true;
        }

        console.log('clicked radio quote is:' + event.target.value);
        console.log('is credit app checked a: ' + this.isCreditAppChecked);
        const assetEvent = new CustomEvent("selectquote", {
            detail: {creditAppId: event.target.value, 
                    newValue: this.isCreditAppChecked
            }
        });

        this.dispatchEvent(assetEvent);
    }

    handleProposalCheckbox(event) {
        const assetEvent = new CustomEvent("toggleproposalforquote", {
            detail: event.target.value
        });

        this.dispatchEvent(assetEvent);
    }

    handleEditAsset(event) {
        this.loading = true;
        const assetEvent = new CustomEvent("editasset", {
            detail: this.option.optionIndex.toString()
        });

        this.dispatchEvent(assetEvent);

    }

    handleCloneAsset(event) {
        this.loading = true;
        const assetEvent = new CustomEvent("cloneasset", {
            detail: this.option.optionIndex.toString()
        });

        this.dispatchEvent(assetEvent);

    }

    handleDeleteAsset(event) {
        this.loading = true;
        console.log('got in here');
        const assetEvent = new CustomEvent("deleteasset", {
            detail: this.option.quote.Id
        });

        this.dispatchEvent(assetEvent);
    }

}