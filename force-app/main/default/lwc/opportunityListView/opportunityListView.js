/*********************************************************************************************
 * 
 * 
 * Change Log:
 * 07/13/2022 - MRM Fixed Alignment for amount; in the usa dollars are right aligned.
 */

import {LightningElement, track, wire, api} from 'lwc';
import getOpportunities from '@salesforce/apex/OpportunityListView.getOpportunities';
import getOpportunitiesNum from '@salesforce/apex/OpportunityListView.getOpportunitiesNum';
//import getSalesRapMap from '@salesforce/apex/OpportunityListView.getOptionsByFieldObject';
import {getObjectInfo, getPicklistValues} from "lightning/uiObjectInfoApi";
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STATUS_FIELD from "@salesforce/schema/Opportunity.Sub_Stage__c";
import {NavigationMixin} from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Custom Labels
import CREDITCHECK_ENABLED from '@salesforce/label/c.CREDITCHECK_ENABLED';
import ENROLL_ENABLED from '@salesforce/label/c.ENROLL_ENABLED';

const actions = [{
    label: 'Enroll in Financing',
    name: 'EnrolInFinancing',
    disabled: false
}];

const columns = [
    {
        label: 'Application #',
        fieldName: 'ApplicationNumberUrl',
        type: 'url',
        sortable: true,
        standardCellLayout: true,
        typeAttributes: {
            label: {
                fieldName: 'Application_Number__c'
            },
            target: '_self'
        }
    },
    {label: 'Customer Name', fieldName: 'EndUserURL', type: 'url', sortable: true, 
     typeAttributes: {label: {fieldName: 'End_User_Company_Name__c'}, target: '_self'}
    },
    {label: 'Sales Rep', fieldName: 'SalesRepValue', type: 'text'},
    {label: 'Amount', fieldName: 'Amount', type: 'currency', fixedWidth: 100, typeAttributes: { currencyCode: 'USD' }, sortable: true,
        cellAttributes: { alignment: 'right' }},   
    {label: 'Submitted', fieldName: 'Application_Date__c', type: 'date-local', typeAttributes:{
        month: "2-digit",
        day: "2-digit"
    }, sortable: true},
    {label: 'Expires', fieldName: 'Approval_Letter_Expiration_Date__c', type: 'date-local', typeAttributes:{
        month: "2-digit",
        day: "2-digit"
    }, sortable: true},
    {label: 'Status', fieldName: 'Sub_Stage__c', type: 'text', sortable: true},
    {label: '',type: 'action',typeAttributes: {
            rowActions: actions
        }
    }
];

export default class opportunityListView extends NavigationMixin(LightningElement) {

    label = {
        CREDITCHECK_ENABLED,
        ENROLL_ENABLED
    };

    // Credit Check
    creditCheckEnabled = false;

    opportunities = [];
    totalNumberOfRows;
    error;
    columns = columns;
    sortBy;
    sortDirection;
    rowLimit = 20;
    rowOffset = 0;
    loadMoreStatus;
    applicationDate='';
    applicationDatePickListValues =[];
    partnerStatus='';
    partnerStatusPickListValues = [
        {label: 'All', value: ''},
        {label: 'Application Draft', value: 'Application Draft'},
        {label: 'Application Submitted', value: 'Application Submitted'},
        {label: 'Application Pending', value: 'Application Pending'},
        {label: 'Application Approved', value: 'Application Approved'},
        {label: 'Conditional Approval', value: 'Conditional Approval'},
        {label: 'Document Request Draft', value: 'Document Request Draft'},
        {label: 'Documents Requested', value: 'Documents Requested'},
        {label: 'Documents Out', value: 'Documents Out'},
        {label: 'Documents In', value: 'Documents In'},
        {label: 'Purchase Order Issued', value: 'Purchase Order Issued'},
        {label: 'Invoice Received', value: 'Invoice Received'},
        {label: 'Delivery and Acceptance Received', value: 'Delivery and Acceptance Received'},
        {label: 'Prep for Funding', value: 'Prep for Funding'},
        {label: 'Passed to Funding', value: 'Passed to Funding'},
        {label: 'Funding Team Accepted', value: 'Funding Team Accepted'},
        {label: 'Credit Declined', value: 'Credit Declined'}
    ];
    searchAllValue ='';
    enableInfiniteLoading = true;
    initialDataLoaded = false;   
    datatable;
    itemCount;
    now= Date.now();
    saleRapOptions;
    saleRapValue='';
    errorMsg='';
    
    @api specificationTabActive = false;

    @wire(getObjectInfo, {objectApiName: OPPORTUNITY_OBJECT})
    objectInfo;

    connectedCallback() {

        let thisYearNum = new Date().getFullYear();
        let thisYear = thisYearNum.toString();
        let lastYearNum = thisYear-1;
        let lastYear = lastYearNum.toString();
        let lastTwoYearNum = thisYear-2;
        let lastTwoYear = lastTwoYearNum.toString();
        let lastThreeYearNum = thisYear-3;
        let lastThreeYear = lastThreeYearNum.toString();
        let lastFourYearNum = thisYear-4;
        let lastFourYear = lastFourYearNum.toString();
        this.applicationDatePickListValues.push(
            {label: 'All Time', value: ''},
            {label: 'Last 30 days', value: '30D'},
            {label: 'Last 60 days', value: '60D'},
            {label: 'Last 6 months', value: '6M'},
            {label: 'Last 12 months', value: '12M'},
            {label: thisYear, value: thisYear},
            {label: lastYear, value: lastYear},
            {label: lastTwoYear, value: lastTwoYear},
            {label: lastThreeYear, value: lastThreeYear},
            {label: lastFourYear, value: lastFourYear});

        this.sortBy='Application_Date__c';
        this.sortDirection='desc';
        this.getInitialOpportunities();
    }

    getInitialOpportunities() {

        getOpportunities({
            rowLimit: this.rowLimit,
            rowOffset: this.rowOffset,
            submittedDate: this.applicationDate,
            partnerStatus: this.partnerStatus,
            searchAllValue: this.searchAllValue,
            sortBy: this.sortBy,
            sortDirection: this.sortDirection
        }).then(result => {

            // CREDITCHECK_ENABLED
            if(CREDITCHECK_ENABLED == 'true'){
                this.creditCheckEnabled = true;
            }
            console.log('creditCheckEnabled: ' + this.creditCheckEnabled);

            console.log(result);
            if (result) {
                let tempOpportunitiesList = [];

                result.forEach((record) => {
                    let tempOpportunity = Object.assign({}, record);

                    //create temp variable ApplicationNumberUrl
                    /*if (tempOpportunity.Application_Number__c == undefined) {
                        tempOpportunity.ApplicationNumberUrl = '#';
                    } else {
                        tempOpportunity.ApplicationNumberUrl = window.location.origin + '/dllondemand/s/opportunity/' + tempOpportunity.Id;
                    }*/

                    //Start: BUG  - Lucas Silva - 
                    if(this.partnerStatus == 'Application Pending'){
                        tempOpportunity.ApplicationNumberUrl = window.location.origin + '/dllondemand/s/creditappadditionalinfo?opptid=' + tempOpportunity.Id;
                    }
                    else{
                        tempOpportunity.ApplicationNumberUrl = window.location.origin + '/dllondemand/s/opportunity/' + tempOpportunity.Id;
                    }
                    if ((tempOpportunity.Application_Number__c == undefined) || (tempOpportunity.Application_Number__c == '')) {
                       // tempOpportunity.ApplicationNumberUrl.typeAttributes.label.fieldName = name;
                    } 

                    //End: BUG  - Lucas Silva - 
                    if (tempOpportunity.Partner_Sales_Rep__r) {
                        console.log('Sales Rep ' + tempOpportunity.Partner_Sales_Rep__r.name);
                        tempOpportunity.SalesRepValue = tempOpportunity.Partner_Sales_Rep__r.Name;
                    } else {
                        tempOpportunity.SalesRepValue = '';
                    }
                    
                    if(tempOpportunity.End_User__c==undefined){
                        tempOpportunity.EndUserURL ='#';
                    }
                    else{
                        tempOpportunity.EndUserURL = window.location.origin + '/dllondemand/s/account/' + tempOpportunity.End_User__c;
                    }                          
                    console.log('EndUserURL: '+ tempOpportunity.End_User__c);
                    tempOpportunitiesList.push(tempOpportunity);
                    console.log('oppList:' + tempOpportunitiesList);
                });

                this.opportunities = tempOpportunitiesList;
                getOpportunitiesNum({
                    rowLimit: this.rowLimit,
                    rowOffset: this.rowOffset,
                    submittedDate: this.applicationDate,
                    partnerStatus: this.partnerStatus,
                    searchAllValue: this.searchAllValue
                }).then(result => {
                    console.log(result);
                    if (result) {
                        console.log(result + 'Newt');
                        this.totalNumberOfRows = result;
                        this.initialDataLoaded = true;
                        if(this.totalNumberOfRows > this.rowLimit){
                            this.itemCount = this.rowLimit + '+';
                        }
                        else{
                            this.itemCount = this.totalNumberOfRows;
                        }
                    }

                })
            } else if (result.error) {
                this.initialDataLoaded = true;
                console.error("Error", error);
            }
        })

    }

    // Event to handle onloadmore on lightning datatable markup
    loadMoreData(event) {
        event.preventDefault();
        console.log('data loading oppview');
        this.datatable = event.target;
        if (this.initialDataLoaded) {
            this.enableInfiniteLoading =true;
            this.datatable.isLoading = true;
            this.loadMoreStatus = 'Loading';
            this.rowOffset = this.rowLimit + this.rowOffset;

            if (this.rowOffset <= this.totalNumberOfRows) {
                getOpportunities({
                    rowLimit: this.rowLimit,
                    rowOffset: this.rowOffset,
                    submittedDate: this.applicationDate,
                    partnerStatus: this.partnerStatus,
                    searchAllValue: this.searchAllValue,
                    sortBy: this.sortBy,
                    sortDirection: this.sortDirection
                }).then(result => {
                        console.log(result);
                        
                        let tempMoreOpportunitiesList = [];

                        result.forEach((record) => {
                            let tempMoreOpportunity = Object.assign({}, record);  
                            console.log('url: '+ window.location.origin);
                            console.log('tempMoreOpportunity: '+ tempMoreOpportunity);
                            console.log('tempMoreOpportunity.Sub_Stage__c: '+ tempMoreOpportunity.Sub_Stage__c);
                            console.log('tempMoreOpportunity.ApplicationNumberUrl: '+ tempMoreOpportunity.ApplicationNumberUrl);
                            tempMoreOpportunity.ApplicationNumberUrl = window.location.origin + '/dllondemand/s/opportunity/' + record.Id;
                            tempMoreOpportunity.EndUserURL = window.location.origin + '/dllondemand/s/account/' + tempMoreOpportunity.End_User__c;
                            console.log('EndUserURL: '+ tempMoreOpportunity.End_User__c);
                            tempMoreOpportunitiesList.push(tempMoreOpportunity);
                            console.log('oppList:' + tempMoreOpportunitiesList);
                        });

                        this.opportunities = this.opportunities.concat(tempMoreOpportunitiesList);
                        this.loadMoreStatus = '';
                        this.datatable.isLoading = false;
                        this.itemCount = this.rowOffset + '+';
                    }
                );
            } else {
                this.enableInfiniteLoading = false;
                this.datatable.isLoading = false;
                this.loadMoreStatus = 'No more data to load';
                this.itemCount = this.totalNumberOfRows;
            }
        }
    }

    // The method onsort event handler
    updateColumnSorting(event) {

        // assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.opportunities = [];
        this.rowOffset = 0;
        this.getInitialOpportunities();
   }

    handleChangeDate(event) {
        this.applicationDate = event.target.value;
        //this.value = this.applicationDate;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.opportunities = [];
        this.rowOffset = 0;
        this.getInitialOpportunities();
    }

    handleChangeStatus(event) {
        this.partnerStatus = event.target.value;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.opportunities = [];
        this.rowOffset = 0;
        this.getInitialOpportunities();
    }

    handleKeyUp(event) {
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            this.searchAllValue = event.target.value;
            this.enableInfiniteLoading = true;
            this.isLoading =true;
            this.opportunities = [];
            this.rowOffset = 0;
            this.getInitialOpportunities();
        }    
    }

    resetList(event) {

        if(event.detail.value)
            return;
        else{
            this.searchAllValue='';
            this.enableInfiniteLoading = true;
            this.isLoading =true;
            this.opportunities = [];
            this.rowOffset = 0;
            this.getInitialOpportunities();
        }
        
    }
    onSalesRepChange(event) {
        if(event.detail.value==undefined || event.detail.value=='' || event.detail.value == null) {
            this.errorMsg=event.detail;
        } else {
            this.errorMsg='';
        }
        this.saleRapValue = event.detail.value;
        console.log('this.saleRapValue::'+this.saleRapValue);
    }

    //Method to handle Row action event - Enroll in Financing
    handleRowAction(event) {
        this.loader = true;
        const substages = event.detail.row.Sub_Stage__c;
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        console.log('ENROLL_ENABLED: ' + ENROLL_ENABLED);
        if(ENROLL_ENABLED == 'false'){
            this.loader = false;
            const evt = new ShowToastEvent({
                title:      'Enroll in Financing ',
                message:    'This application is not available for enrollment.',
                variant:    'error',
                duration:   20000
            });
            this.dispatchEvent(evt);
        } else if (actionName === 'EnrolInFinancing' && (substages === 'Application Approved' || substages === 'Conditional Approval'
            || substages === 'Document Request Draft' || substages === 'Documents Requested' || substages === 'Documents Out' 
            || substages === 'Documents In' || substages === 'Purchase Order Issued' || substages === 'Invoice Received' 
            || substages === 'Delivery and Acceptance Received' || substages === 'Prep for Funding' || substages === 'Passed to Funding'
            || substages === 'Funding Team Accepted')) {
            this.loader = false;
            this[NavigationMixin.Navigate]({type: 'standard__webPage',attributes: {
                    url: window.location.origin + '/dllondemand/s/enroll-screen?oppId=' + row.Id
                }
            })
        } else {
            this.loader = false;
            const evt = new ShowToastEvent({
                title:      'Enroll in Financing ',
                message:    'This application is not available for enrollment.',
                variant:    'error',
                duration:   20000
            });
            this.dispatchEvent(evt);
        }

        // Refresh the page to prevent the caching issues.
        eval("$A.get('e.force:refreshView').fire();");
    }

   onClickOfApplicationNumber(event){
        const applicationNum = event.detail.row.Application_Number__c;
        console.log('application number: ' + applicationNum);
   }

   //added for button to navigate to the credit check page
   navigateToCreditCheck(event) {
       this[NavigationMixin.Navigate]({
           type: 'standard__webPage',
           attributes: {
               url: '/dllondemand/s/credit-check'
           }
       });
   }

    // Submit Credit Application on click of Create New Application button
    /*

    @track
    showHandleClick = false;

    handleClick() {
        this.showHandleClick = true;
        //firing an child method
        //this.template.querySelector("c-submit-credit-application-form").handleValueChange();
    }
    */
}