/**
 * @description       : LWC component to review credit app screen. 
 * @author            : Surbhi Goyal : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 23-05-2022
 * @last modified by  : Surbhi Goyal
**/
import {api, track, LightningElement, wire} from 'lwc';
import getOpportunityField from '@salesforce/apex/EnrollController.getOpportunityData';
import getQuoteLineField from '@salesforce/apex/EnrollController.getQuoteLineData';
import getQuoteLineForAccessoryField from '@salesforce/apex/EnrollController.getQuoteLineAccessoryData';
import { CurrentPageReference } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';

//Custom Label
import ENROL_REVIEW_SPECS from '@salesforce/label/c.ENROL_REVIEW_SPECS';
import ENROL_REVIEW_FINANCE_ASSETS from '@salesforce/label/c.ENROL_REVIEW_FINANCE_ASSETS';
import ENROL_REVIEW_REQUIRED from '@salesforce/label/c.ENROL_REVIEW_REQUIRED';
import ENROL_REVIEW_FIN_STRUCTURE from '@salesforce/label/c.ENROL_REVIEW_FIN_STRUCTURE';
import ENROL_REVIEW_LEASE_TYPE from '@salesforce/label/c.ENROL_REVIEW_LEASE_TYPE';
import ENROL_REVIEW_FIN_TERM from '@salesforce/label/c.ENROL_REVIEW_FIN_TERM';
import ENROL_REVIEW_RATE_TYPE from '@salesforce/label/c.ENROL_REVIEW_RATE_TYPE';
import ENROL_REVIEW_PAYMENT_FREQ from '@salesforce/label/c.ENROL_REVIEW_PAYMENT_FREQ';
import ENROL_REVIEW_ADV_PAY_OPTIONAL from '@salesforce/label/c.ENROL_REVIEW_ADV_PAY_OPTIONAL';
import ENROL_REVIEW_TOTAL_PRICE from '@salesforce/label/c.ENROL_REVIEW_TOTAL_PRICE';
import ENROL_REVIEW_MAKE from '@salesforce/label/c.ENROL_REVIEW_MAKE';
import ENROL_REVIEW_ASSET_ITA_CLASS from '@salesforce/label/c.ENROL_REVIEW_ASSET_ITA_CLASS';
import ENROL_REVIEW_ASSET_MODEL from '@salesforce/label/c.ENROL_REVIEW_ASSET_MODEL';
import ENROL_REVIEW_MAST_TYPE from '@salesforce/label/c.ENROL_REVIEW_MAST_TYPE';

import ENROL_REVIEW_OS_ENVIRONMENT from '@salesforce/label/c.ENROL_REVIEW_OS_ENVIRONMENT';
import ENROL_REVIEW_ANNUAL_HRS from '@salesforce/label/c.ENROL_REVIEW_ANNUAL_HRS';
import ENROL_REVIEW_BATTERY_INCLUDED from '@salesforce/label/c.ENROL_REVIEW_BATTERY_INCLUDED';
import ENROL_REVIEW_NO_UNITS from '@salesforce/label/c.ENROL_REVIEW_NO_UNITS';
import ENROL_REVIEW_UNIT_SALES_PRICE from '@salesforce/label/c.ENROL_REVIEW_UNIT_SALES_PRICE';
import ENROL_REVIEW_SUBSIDY from '@salesforce/label/c.ENROL_REVIEW_SUBSIDY';
import ENROL_REVIEW_RELATED_ASSET from '@salesforce/label/c.ENROL_REVIEW_RELATED_ASSET';
import ENROL_REVIEW_ACCESSORY from '@salesforce/label/c.ENROL_REVIEW_ACCESSORY';
import ENROL_REVIEW_SALES_PRICE from '@salesforce/label/c.ENROL_REVIEW_SALES_PRICE';

export default class EnrollReviewCreditApp extends LightningElement {
    label = {
        ENROL_REVIEW_SPECS,
        ENROL_REVIEW_FINANCE_ASSETS,
        ENROL_REVIEW_REQUIRED,
        ENROL_REVIEW_FIN_STRUCTURE,
        ENROL_REVIEW_LEASE_TYPE,
        ENROL_REVIEW_FIN_TERM,
        ENROL_REVIEW_RATE_TYPE,
        ENROL_REVIEW_PAYMENT_FREQ,
        ENROL_REVIEW_ADV_PAY_OPTIONAL,
        ENROL_REVIEW_TOTAL_PRICE,
        ENROL_REVIEW_MAKE,
        ENROL_REVIEW_ASSET_ITA_CLASS,
        ENROL_REVIEW_ASSET_MODEL,
        ENROL_REVIEW_MAST_TYPE,
        ENROL_REVIEW_OS_ENVIRONMENT,
        ENROL_REVIEW_ANNUAL_HRS,
        ENROL_REVIEW_BATTERY_INCLUDED,
        ENROL_REVIEW_NO_UNITS,
        ENROL_REVIEW_UNIT_SALES_PRICE,
        ENROL_REVIEW_SUBSIDY,
        ENROL_REVIEW_RELATED_ASSET,
        ENROL_REVIEW_ACCESSORY,
        ENROL_REVIEW_SALES_PRICE
    };
    // disable and visible conditions for tabs
    @api modeVisible;
    @api oppId;

    //active section
     activeSections = ['Financing Structure','asset 1'];

     @track wiredRefreshList;
     
     //Params from Url 
     oppId = null;
     opportunityId;
     @wire(CurrentPageReference)
     getStateParameters(currentPageReference) {
         if (currentPageReference) {
             this.oppId = currentPageReference.state.oppId;
         }
     }
 
     //finance structure
     rateType;
     financeTerm;
     financeType;
     paymentFrequency;
     advPayments;
     totalPrice;
     rateTypePicklist;
     financeTermPicklist;
     financeTypePicklist;
     frequencyPicklist;
     advancedPaymentsPicklist;
     //assets
     assets = [{
         sectionName: 'asset 1',
         assetHeading: 'Asset 1',
         assetNo: 1,
         isFirst: true,
         makeValue:'',
         assetTypeValue:'',
         modelValue:'',
         mastTypeValue:'',
         assetOperatingEnvironmentValue:'',
         annualHoursValue:'',
         batteryIncludedValue:'',
         numberOfUnitsValue:'',
         unitSalesPriceValue:'',
         subsidyValue:'',
         assetId:''
     }];
 
     // asset picklist options
     makePicklist;
     assetTypePicklist;
     modelPicklist;
     mastTypePicklist;
     assetOperatingPicklist;
     batteryIncludedPicklist;
     numberOfUnitsPicklist;
     subsidyPicklist;
     assetsBlank= [];
     loading=false;
     //accessory
     accessories = [{
         sectionName: 'Accessory1',
         accessoryHeading: 'Accessory 1',
         accessoryNo: 1,
         isFirst: true,
         relatedAssetValue:'',
         accessoryValue:'',
         unitSalesPriceValue:'',
         numberofUnitsValue:'',
         accessoryId:''
     }];
     //accesssory picklist options
     relatedAssetPicklist;
     accessoryPicklist;
     unitSalesPricePicklist;
     numberofUnitsPicklist;
 
 
 
     
     @wire(getQuoteLineField, {opportunityId: '$oppId'})
     wiredGetQuoteLine({ error, data }){
         if (data) {
            this.wiredRefreshList=data;
            console.log('modeVisible:::'+this.modeVisible);
             this.assets = [];
             var assetLen=0;
 
             const formatter = new Intl.NumberFormat('en-US', {
                 style: 'currency',
                 currency: 'USD',
                 minimumFractionDigits: 2
             })
 
             for(var i=0;i<data.length;i++) {
                 assetLen=i+1;
                 this.assets.push({
                     sectionName: 'asset'+assetLen,
                     assetHeading: 'Asset '+assetLen,
                     assetNo: assetLen,
                     isFirst: true,
                     makeValue:data[i].Make__c,
                     assetTypeValue:data[i].Asset_Type_ITA_Class__c,
                     modelValue:data[i].Model__c,
                     mastTypeValue:data[i].Mast_Type__c,
                     assetOperatingEnvironmentValue:data[i].Operating_Environment__c,
                     annualHoursValue:data[i].Annual_Hours__c,
                     batteryIncludedValue:data[i].Battery_Included__c,
                     numberOfUnitsValue:data[i].Number_of_Units__c.toString(),
                     unitSalesPriceValue: (data[i].Base_Unit_Sales_Price__c != null && data[i].Base_Unit_Sales_Price__c != undefined && data[i].Base_Unit_Sales_Price__c != '') ? formatter.format(data[i].Base_Unit_Sales_Price__c.toFixed(2)) : '',
                     subsidyValue:data[i].Subsidy__c,
                     assetId:data[i].Id,
                     quoteId: data[i].Quote__c // Used to map to submitCreditApp()
                 });
             }
 
         } else if (error) {
 
         }
     }
     @wire(getQuoteLineForAccessoryField, {opportunityId: '$oppId'})
     wiredGetQuoteLineForAccessory({ error, data }){
         if (data) {
             this.loading=true;
             this.accessories = [];
             var accessoryLen=0;
 
             console.log('accessories', data);
 
             const formatter = new Intl.NumberFormat('en-US', {
                 style: 'currency',
                 currency: 'USD',
                 minimumFractionDigits: 2
             })
 
             for(var i=0;i<data.length;i++) {
                 accessoryLen=i+1;
 
                 // Handle whether a related asset exists.
                 var relatedModel = '';
                 if(data[i].Related_Asset__c != null){
                     relatedModel = data[i].Related_Asset__r.Make__c + ' ' + data[i].Related_Asset__r.Model__c;
                 } else {
                     relatedModel = '';
                 }
               // Add the accessory to the list
                 this.accessories.push({
                     accessoryHeading:       'Accessory '+accessoryLen,
                     accessoryId:            data[i].Id,
                     accessoryNo:            accessoryLen,
                     accessoryValue:         data[i].Model__c,
                     isFirst:                true,
                     numberofUnitsValue:     data[i].Number_of_Units__c.toString(),
                     relatedAssetValue:      relatedModel,
                     sectionName:            'Accessory'+accessoryLen,
                     unitSalesPriceValue:  (data[i].Base_Unit_Sales_Price__c != null && data[i].Base_Unit_Sales_Price__c != undefined && data[i].Base_Unit_Sales_Price__c != '') ?   formatter.format(data[i].Base_Unit_Sales_Price__c.toFixed(2)) : ''
                 });
             }
             this.loading=false;
 
         } else if (error) {
 
         }
     }
 
 
     @wire(getOpportunityField, {opportunityId: '$oppId'})
     wiredgetQuoteRecord({ error, data }) {
         if (data) {
            const formatter = new Intl.NumberFormat('en-US', {
                style: 'currency',
                currency: 'USD',
                minimumFractionDigits: 2
            });
             //finance story
             this.rateType=data.Rate_Type__c;
             this.financeTerm=data.Term__c;
             this.financeType=data.Lease_Type__c;
             this.paymentFrequency=data.Frequency__c;
             this.advPayments=data.Advance_Payments__c;
             console.log('amount is: ' + data.Amount);
             this.totalPrice = (data.Amount != null && data.Amount != undefined && data.Amount != '') ?  formatter.format(data.Amount.toFixed(2)) : '';
             
            this.opportunityId = data.Id;
           } else if (error) {
 
         }
     }
     handleOnReviewSpecs(){
         
     }

     @api saveModeOn(){
         this.loading=true;
         //eval("$A.get('e.force:refreshView').fire();");
         refreshApex(this.wiredRefreshList);
         this.loading=false;
         
     }
}