/**
 * @description       : LWC component for Summary Section in Enrol in Finance. 
 * @author            : Surbhi Goyal : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 10-05-2022
 * @last modified by  : Kritika Sharma
**/
import { LightningElement,wire } from 'lwc';
import getOpportunityField from '@salesforce/apex/EnrollController.getOpportunityData';
import getAllQuoteLineData from '@salesforce/apex/EnrollController.getAllQuoteLineData';
import getQuoteLineData from '@salesforce/apex/EnrollController.getQuoteLineData';
import getAssetDetails from '@salesforce/apex/EnrollController.getAssetDetails';

import { CurrentPageReference } from 'lightning/navigation';

// Custom Labels
import ENROLL_SUMMARY from '@salesforce/label/c.ENROLL_SUMMARY';
import ENROLL_SUMMARY_FIN_AMT from '@salesforce/label/c.ENROLL_SUMMARY_FIN_AMT';
import ENROLL_SUMMARY_FIN_NO_ASSETS from '@salesforce/label/c.ENROLL_SUMMARY_FIN_NO_ASSETS';
import ENROLL_SUMMARY_FIN_TERM from '@salesforce/label/c.ENROLL_SUMMARY_FIN_TERM';
import ENROLL_SUMMARY_FIN_RATE from '@salesforce/label/c.ENROLL_SUMMARY_FIN_RATE';
import ENROLL_SUMMARY_FIN_EQUIPMENT from '@salesforce/label/c.ENROLL_SUMMARY_FIN_EQUIPMENT';
import ENROLL_SUMMARY_FIN_FEE from '@salesforce/label/c.ENROLL_SUMMARY_FIN_FEE';
import ENROLL_SUMMARY_FIN_CONTRACT_PAY from '@salesforce/label/c.ENROLL_SUMMARY_FIN_CONTRACT_PAY';
import ENROLL_SUMMARY_FIN_TOTAL_PRICE from '@salesforce/label/c.ENROLL_SUMMARY_FIN_TOTAL_PRICE';
import ENROLL_SUMMARY_FIN_APPROVED_FOR from '@salesforce/label/c.ENROLL_SUMMARY_FIN_APPROVED_FOR';

export default class EnrollSummary extends LightningElement {

     label = {
        ENROLL_SUMMARY,
        ENROLL_SUMMARY_FIN_AMT,
        ENROLL_SUMMARY_FIN_NO_ASSETS,
        ENROLL_SUMMARY_FIN_TERM,
        ENROLL_SUMMARY_FIN_RATE,
        ENROLL_SUMMARY_FIN_EQUIPMENT,
        ENROLL_SUMMARY_FIN_FEE,
        ENROLL_SUMMARY_FIN_CONTRACT_PAY,
        ENROLL_SUMMARY_FIN_TOTAL_PRICE,
        ENROLL_SUMMARY_FIN_APPROVED_FOR
    };

    oppId = null;
    opportunityId;

    approvedFor;
    totalPriceSummary;
    totalContractPayment;
    serviceFee;
    equipmentPayment;
    interestRate;
    term;
    numberOfAsset;
    financedAmount;
    
    // Get record details by passing OppId in URL
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
         if (currentPageReference) {
             this.oppId = currentPageReference.state.oppId;
         }
     }
    
    connectedCallback(){
        
        var equipPayment=0;
        var serviceFeeAmount=0;
        var numberOfAllQuoteLine=0;
        var serviceFeeTotal=0;
        getOpportunityField({opportunityId: this.oppId}).then(data =>{
            if(data){
                const formatter = new Intl.NumberFormat('en-US', {
                    style: 'currency',
                    currency: 'USD',
                    minimumFractionDigits: 2
                });
                console.log('data of opportunity:::'+JSON.stringify(data));
                
                //Total Price
                this.approvedFor=(data.Payment_Amount__c != null && data.Payment_Amount__c != undefined && data.Payment_Amount__c != '') ? formatter.format(data.Payment_Amount__c.toFixed(2)) : '$0.00';
                
                //Total Price Summary
                this.totalPriceSummary=(data.Payment_Amount__c != null && data.Payment_Amount__c != undefined && data.Payment_Amount__c != '') ? formatter.format(data.Payment_Amount__c.toFixed(2)) : '$0.00';
                
                //Financed Amount
                this.financedAmount=formatter.format(data.Amount);

                // Number of Assets
                this.numberOfAsset=data.Number_of_Assets__c;

                //Term
                this.term=data.Term__c;

                //Interest Rate
                this.interestRate=(data.Interest_Rate__c != null && data.Interest_Rate__c != undefined && data.Interest_Rate__c != '') ? data.Interest_Rate__c.toFixed(2)+'%' : '%';
                
                //Equipment Payment
                this.equipmentPayment=formatter.format(data.Payment_Amount__c);

                //Service Fee
                if(data.Service_Fee_Total__c != null && data.Service_Fee_Total__c > 0){
                    this.serviceFee = formatter.format(data.Service_Fee_Total__c);
                }else{
                    this.serviceFee = '$0';
                }

                //Total Contract Payment
                this.totalContractPayment =formatter.format(data.Total_Contract_Payment__c);
            }
        });
    }
}