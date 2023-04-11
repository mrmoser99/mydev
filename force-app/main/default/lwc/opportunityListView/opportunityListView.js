/*********************************************************************************************
 * 
 * 
 * Change Log:
 * 07/13/2022 - MRM Fixed Alignment for amount; in the usa dollars are right aligned.
 * 10/05/2022 - Fernando Nereu Souza Bug 879195 Sales Rep Values not getting populate in the list views
 * 14/12/2022 - Dibyendu - Bug 893493 Selecting an application from the application list view should always land to the same page layout
 * 01/25/2023 - MRM - Sent credit checks to same page as others.
 * 02/06/2023 - Lucas Lucena - BUG 942673 - TST ACC | On Application Listview - "Sales Rep" field not filtering correctly 
 * 02/20/2023 - MRM added isPortalUser; and some non portal navigation stuff
 * 16/03/2023 - Vinicio Ramos Silva - BUG 975326 - In app list view, after the Sales Rep filter selection, the filter is refreshed but not sorted.
 * 
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
import IsPortalEnabled from "@salesforce/apex/PricingUtils.isPortalEnabled";

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
        fixedWidth: 130,        
        typeAttributes: {
            label: {
                fieldName: 'Application_Number__c'
            },
            target: '_self'
        }
    },
    {label: 'Quote No.', fieldName: 'quoteNumberURL', type: 'url', sortable: true, fixedWidth: 120,  //mrm changed to this for appeals
     typeAttributes: {label: {fieldName: 'Display_Quote_Number__c'}, target:'_self'}
    },
    {label: 'Customer Name', fieldName: 'EndUserURL', type: 'url', sortable: true, fixedWidth: 160, 
     typeAttributes: {label: {fieldName: 'End_User_Company_Name__c'}, target: '_self'}
    },
    {label: 'Sales Rep', fieldName: 'SalesRepValue', type: 'text', fixedWidth: 150},
    {label: 'Amount', fieldName: 'Amount', type: 'currency', typeAttributes: { currencyCode: 'USD' }, sortable: true, fixedWidth: 120,
        cellAttributes: { alignment: 'right' }},   
    {label: 'Submitted', fieldName: 'Application_Date__c', type: 'date-local', fixedWidth: 100, typeAttributes:{
        month: "2-digit",
        day: "2-digit"
    }, sortable: true},
    {label: 'Expires', fieldName: 'Approval_Letter_Expiration_Date__c', type: 'date-local', fixedWidth: 100, typeAttributes:{
        month: "2-digit",
        day: "2-digit"
    }, sortable: true},
    {label: 'Status', fieldName: 'Sub_Stage__c', type: 'text', sortable: true, fixedWidth: 150},
    {label: '',type: 'action', typeAttributes: {
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
    isPortalUser = false;
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
    @track partnerStatus='';
    @track salesRepFilter = '';
    @track allValues = [];
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

        console.log('checking if portal user');

        IsPortalEnabled().then(result => {
            console.log('result is : ' + result);
            this.isPortalUser = result;
        });

        this.getInitialOpportunities();
    }

    getInitialOpportunities() {
        //FNS TEST

        getOpportunities({
            rowLimit: this.rowLimit,
            rowOffset: this.rowOffset,
            submittedDate: this.applicationDate,
            partnerStatus: this.allValues,
            searchAllValue: this.searchAllValue,
            sortBy: this.sortBy,
            sortDirection: this.sortDirection,
            salesRepFilter: this.salesRepFilter
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

                    //if(tempOpportunity.Nickname__c != 'Credit Check') {
                    if(tempOpportunity.Quote_Count__c > 0) {
                        if (this.isPortalUser){
                            tempOpportunity.quoteNumberURL = window.location.origin + '/dllondemand/s/new-quote?oppid=' + tempOpportunity.Id;
                        }
                        else{
                            tempOpportunity.quoteNumberURL = window.location.origin + '/lightning/n/Quote?c__oppid=' + tempOpportunity.Id;
                        }
                        tempOpportunity.Display_Quote_Number__c = tempOpportunity.Display_Quote_Number__c;
                        
                    } else {
                        tempOpportunity.Display_Quote_Number__c = '';
                        tempOpportunity.quoteNumberURL = '';
                    }

                    //create temp variable ApplicationNumberUrl
                    /*if (tempOpportunity.Application_Number__c == undefined) {
                        tempOpportunity.ApplicationNumberUrl = '#';
                    } else {
                        tempOpportunity.ApplicationNumberUrl = window.location.origin + '/dllondemand/s/opportunity/' + tempOpportunity.Id;
                    }*/

                    //Start: BUG  - Lucas Silva - 
                    //if(this.partnerStatus == 'Application Pending'){
                    //Changed the condition for the defect - 893493
                    if(tempOpportunity.Sub_Stage__c == 'Application Pending' || tempOpportunity.Sub_Stage__c == 'Additional Information requested'){
                        if (this.isPortalUser){
                            tempOpportunity.ApplicationNumberUrl = window.location.origin + '/dllondemand/s/creditappadditionalinfo?opptid=' + tempOpportunity.Id;
                        }
                        else{
                            tempOpportunity.ApplicationNumberUrl = window.location.origin + '/lightning/n/Credit_Application?c__oppid=' + tempOpportunity.Id;
                        }
                    }
                    //Changed the condition for the defect - 893493
                    else if(tempOpportunity.Nickname__c == 'Credit Check' && tempOpportunity.Sub_Stage__c != 'Application Draft')
                    {
                        //mrm fixed this to go to the one page...
                         
                        if (this.isPortalUser){
                            tempOpportunity.ApplicationNumberUrl = window.location.origin + '/dllondemand/s/opportunity/' + tempOpportunity.Id;
                        }
                        else{
                            tempOpportunity.ApplicationNumberUrl = window.location.origin + '/lightning/n/Credit_Application?c__oppid=' + tempOpportunity.Id;
                        }
                    
                    }
                    //Changed the condition for the defect - 893493
                    else{
                        if (this.isPortalUser){
                            tempOpportunity.ApplicationNumberUrl = window.location.origin + '/dllondemand/s/opportunity/' + tempOpportunity.Id;
                        }
                        else{
                            tempOpportunity.ApplicationNumberUrl = window.location.origin + '/lightning/n/Credit_Application?c__oppid=' + tempOpportunity.Id;
                        }
                        
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
                        if (this.isPortalUser){
                            tempOpportunity.EndUserURL = window.location.origin + '/dllondemand/s/account/' + tempOpportunity.End_User__c;
                        }
                        else{
                            tempOpportunity.EndUserURL = window.location.origin +'/lightning/r/Account/' + tempOpportunity.End_User__c + '/view';
                        }
                        
                    }                          
                    //console.log('EndUserURL: '+ tempOpportunity.End_User__c);
                    tempOpportunitiesList.push(tempOpportunity);
                    //console.log('oppList:' + tempOpportunitiesList);
                });

                this.opportunities = tempOpportunitiesList;
                //FNS TEST
                
                getOpportunitiesNum({
                    rowLimit: this.rowLimit,
                    rowOffset: this.rowOffset,
                    submittedDate: this.applicationDate,
                    partnerStatus: this.allValues,
                    searchAllValue: this.searchAllValue,
                    salesRepFilter: this.salesRepFilter
                }).then(result => {
                    console.log(result);
                    if (result) {
                        
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
                //FNS TEST
                getOpportunities({
                    rowLimit: this.rowLimit,
                    rowOffset: this.rowOffset,
                    submittedDate: this.applicationDate,
                    partnerStatus: this.allValues,
                    searchAllValue: this.searchAllValue,
                    sortBy: this.sortBy,
                    sortDirection: this.sortDirection,
                    salesRepFilter: this.salesRepFilter
                }).then(result => {
                        console.log(result);
                        
                        let tempMoreOpportunitiesList = [];

                        result.forEach((record) => {
                            let tempMoreOpportunity = Object.assign({}, record);  
                            console.log('url: '+ window.location.origin);
                            console.log('tempMoreOpportunity: '+ tempMoreOpportunity);
                            console.log('tempMoreOpportunity.Sub_Stage__c: '+ tempMoreOpportunity.Sub_Stage__c);
                            console.log('tempMoreOpportunity.ApplicationNumberUrl: '+ tempMoreOpportunity.ApplicationNumberUrl);
                            if (this.isPortalUser){
                                tempMoreOpportunity.ApplicationNumberUrl = window.location.origin + '/dllondemand/s/opportunity/' + record.Id;
                                tempMoreOpportunity.EndUserURL = window.location.origin + '/dllondemand/s/account/' + tempMoreOpportunity.End_User__c;
                            }
                            else{
                                tempMoreOpportunity.ApplicationNumberUrl = window.location.origin + '/lightning/n/Credit_Application?c__oppid=' + record.Id;
                                tempMoreOpportunity.EndUserURL = window.location.origin + '/r/Account/' + tempMoreOpportunity.End_User__c + '/view';
                            }
                            
                            
                            //Start: Lucas Lucena - PBI 942673
                            if (tempMoreOpportunity.Partner_Sales_Rep__r) {
                                tempMoreOpportunity.SalesRepValue = tempMoreOpportunity.Partner_Sales_Rep__r.Name;
                            } else {
                                tempMoreOpportunity.SalesRepValue = '';
                            }
                            //End: Lucas Lucena - PBI 942673

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
        if(!this.allValues.includes(event.target.value)){           
            this.allValues.push(event.target.value);                 
        }
        this.partnerStatus = event.target.value;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.opportunities = [];
        this.rowOffset = 0;
        this.getInitialOpportunities();
    }

    // Start: Lucas Lucena - PBI 942673
    handleChangeSalesRep(event) {
        this.salesRepFilter = event.target.value;
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            this.enableInfiniteLoading = true;
            this.isLoading =true;
            this.opportunities = [];
            this.rowOffset = 0;
            this.getInitialOpportunities();
         }, 2000);
        
    }
    // End: Lucas Lucena - PBI 942673

    handleRemove(event){
        
        const valueRemoved = event.target.name;
        this.allValues.splice(this.allValues.indexOf(valueRemoved),1);
        // Start: Vinício Ramos Silva - Bug 975326
        this.sortBy='Application_Date__c';
        this.sortDirection='desc';
        this.loadMoreStatus = '';
        this.initialDataLoaded = false;
        this.rowOffset = 0;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.opportunities = [];
        // End: Vinício Ramos Silva - Bug 975326
        this.getInitialOpportunities();
    }

    handleClearFilters(event){
        this.allValues = [];
        this.partnerStatus='';
        this.applicationDate='';
        this.salesRepFilter='';
        
        // Start: Vinício Ramos Silva - Bug 975326
        this.sortBy='Application_Date__c';
        this.sortDirection='desc';
        this.loadMoreStatus = '';
        this.initialDataLoaded = false;
        this.rowOffset = 0;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.opportunities = [];
        // End: Vinício Ramos Silva - Bug 975326

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
        if (this.isPortalUser){
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/dllondemand/s/credit-check/'
                }
            });
        }
        else{this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: '/lightning/n/Credit_Application'
                }
            });
        }
        
       
   }

    /*Download ListView*/
    /*code to download listView */
    handleDownload(event) {
       


        getOpportunities({
            rowLimit: 9999,
            rowOffset: 0,
            submittedDate: this.applicationDate,
            partnerStatus: this.allValues,
            searchAllValue: this.searchAllValue,
            sortBy: this.sortBy,
            sortDirection: this.sortDirection,
            salesRepFilter: this.salesRepFilter
        }).then(res => {
            console.log('toast for download p');
            const evt = new ShowToastEvent({
               // title: 'Download Portfolio',
                message: 'Downloading....',
                variant: 'success',
                duration:10000,
            });
            this.dispatchEvent(evt);
            console.log('res' +JSON.stringify(res));
           this.downloaddata= res.map(dt=>{
                let tmp = {...dt};
                if(!tmp.Application_Number__c) {tmp.Application_Number__c = ' ';}
                if(!tmp.Nickname__c) {tmp.Nickname__c = ' ';}
                if(!tmp.Type) {tmp.Type = ' ';}
                if(!tmp.Sub_Stage__c) {tmp.Sub_Stage__c = ' ';}
                if(!tmp.End_User_Company_Name__c) {tmp.End_User_Company_Name__c = ' ';}
                if(!tmp.Application_Date__c) {tmp.Application_Date__c = ' ';}
                if(!tmp.Funded_Date__c) {tmp.Funded_Date__c = ' ';}                                
                if(tmp.Account) {tmp.AccountName = tmp.Account.Name;} 
                else {tmp.AccountName = ' ';}                
                if (tmp.Partner_Sales_Rep__r) {tmp.SalesRepValue = tmp.Partner_Sales_Rep__r.Name;} 
                else {tmp.SalesRepValue = ' ';}
               // if(!tmp.Partner_Sales_Rep__r) {tmp.Partner_Sales_Rep__r.Name = ' ';}
                if(!tmp.Amount) {tmp.Amount = ' ';}
                if(!tmp.Booked_Amount_FORMULA__c) {tmp.Booked_Amount_FORMULA__c = ' ';}
                return tmp;
           });     
       
        if(!this.downloaddata || !this.downloaddata.length){
            
            return null
        }
        const jsonObject = JSON.stringify(this.downloaddata);
        const result = this.convertToCSV(jsonObject, this.headers);
        if(result === null) return
        const blob = new Blob([result])
        /*const exportedFilename = 'Applications' + fullDate +'.xls';
        if(navigator.msSaveBlob){
            navigator.msSaveBlob(blob, exportedFilename)
        } else if (navigator.userAgent.match(/iPhone|iPad|iPod/i)){
            const link = window.document.createElement('a')
            //link.href='data:text/csv;charset=utf-8,' + encodeURI(result);
            link.href= 'data:application/vnd.ms-excel,' + encodeURI(result);
            link.target="_blank"
            link.download=exportedFilename
            link.click()
        } else {
            const link = document.createElement("a")
            if(link.download !== undefined){
                const url = URL.createObjectURL(blob)
                link.setAttribute("href", url)
                link.setAttribute("download", exportedFilename)
                link.style.visibility='hidden'
                document.body.appendChild(link)
                link.click()
                document.body.removeChild(link)
            }
        }*/

    }) 
    }


     /*convertToCSV(objArray, headers){
        
        const columnDelimiter = ','
        const lineDelimiter = '\r\n'
        const actualHeaderKey = Object.keys(headers)
        const headerToShow = Object.values(headers) 
        let str = ''
        str+=headerToShow.join(columnDelimiter) 
        str+=lineDelimiter 
        const data = typeof objArray !=='object' ? JSON.parse(objArray):objArray
    
        data.forEach(obj=>{
            let line = ''
            actualHeaderKey.forEach(key=>{
                if(line !=''){
                    line+=columnDelimiter
                }
                let strItem = obj[key]+''
                line+=strItem? strItem.replace(/,/g, ''):strItem
            })
            str+=line+lineDelimiter
        })
      
        return str
    }*/
    
    convertToCSV(objArray, headers){
        let date = new Date()
        let day = date.getDate();
        let month = date.getMonth()+1;
        let year = date.getFullYear();
        let fullDate = month + "-" + day + "-" + year;
        
        /*added header columns for excel- Download Application*/
        let columnHeader = [
            'Application Number',
            'Quote Number', 
            'Nickname', 
            'Application Type', 
            'Application Status', 
            'Customer Name', 
            'Received Date', 
            'Booked Date', 
            'Location', 
            'Vendor Sales Rep', 
            'Application Amount', 
            'Booked Amount'];
        // Prepare a html table
        let doc = '<style>'; 
        // Add styles for the table
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '    text-align: left';        
        doc += '}';          
        doc += '</style>';
        
        doc += '<table>';
        
        // Add all the Table Headers
        doc += '<tr>';
        columnHeader.forEach(element => {            
            doc += '<th>'+ element +'</th>'           
        });
        doc += '</tr>';
        // Add the data rows
        const data = typeof objArray !=='object' ? JSON.parse(objArray):objArray

        data.forEach(record => {
            doc += '<tr>';
            doc += '<th>'+record.Application_Number__c+'</th>';
            doc += '<th>'+record.Display_Quote_Number__c+'</th>'; 
            doc += '<th>'+record.Nickname__c+'</th>'; 
            doc += '<th>'+record.Type+'</th>';
            doc += '<th>'+record.Sub_Stage__c+'</th>';
            doc += '<th>'+record.End_User_Company_Name__c+'</th>';
            doc += '<th>'+record.Application_Date__c+'</th>';
            doc += '<th>'+record.Funded_Date__c+'</th>';
            doc += '<th>'+record.AccountName+'</th>';
            doc += '<th>'+record.SalesRepValue+'</th>';
            doc += '<th>'+record.Amount+'</th>';
            doc += '<th>'+record.Booked_Amount_FORMULA__c+'</th>';
            doc += '</tr>';



        });
        doc += '</table>';
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Applications' + fullDate +'.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }
    /* end of Download Applications */

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